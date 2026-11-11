import {Buffer} from "node:buffer";
import {MediaError} from "./policy.mjs";

const HEADER_LIMIT = 32 * 1024;
const SOURCE_UNAVAILABLE = () => new MediaError("SOURCE_UNAVAILABLE");

class SocketReader {
  constructor(socket) {
    this.socket = socket;
    this.pending = Buffer.alloc(0);
  }

  async fill() {
    const bytes = Buffer.allocUnsafe(8192);
    const count = await this.socket.read(bytes);
    if (count === null) return false;
    this.pending = Buffer.concat([this.pending, bytes.subarray(0, count)]);
    return true;
  }

  async line(remaining) {
    for (;;) {
      const end = this.pending.indexOf("\r\n");
      if (end >= 0 && end + 2 <= remaining) {
        const line = this.pending.toString("latin1", 0, end);
        this.pending = this.pending.subarray(end + 2);
        return line;
      }
      if (this.pending.length >= remaining || !await this.fill()) throw SOURCE_UNAVAILABLE();
    }
  }

  async take(size) {
    if (!this.pending.length && !await this.fill()) return null;
    const count = Math.min(size, this.pending.length);
    const bytes = this.pending.subarray(0, count);
    this.pending = this.pending.subarray(count);
    return bytes;
  }
}

async function readResponse(socket, url, cap, budget) {
  const reader = new SocketReader(socket);
  const statusLine = await reader.line(HEADER_LIMIT);
  const status = Number(/^HTTP\/1\.[01] ([1-5]\d\d)(?: |$)/.exec(statusLine)?.[1]);
  if (!status) throw SOURCE_UNAVAILABLE();
  let headerBytes = HEADER_LIMIT - statusLine.length - 2;
  const headers = Object.create(null);
  for (;;) {
    const line = await reader.line(headerBytes);
    headerBytes -= line.length + 2;
    if (!line) break;
    const parsed = /^([!#$%&'*+.\x5e_\x60|~0-9a-zA-Z-]+):[ \t]*([^\r\n]*)$/.exec(line);
    if (!parsed) throw SOURCE_UNAVAILABLE();
    const name = parsed[1].toLowerCase();
    if (headers[name] !== undefined) {
      if (["content-length", "transfer-encoding", "content-encoding", "content-range", "location"].includes(name)) throw SOURCE_UNAVAILABLE();
      continue;
    }
    headers[name] = parsed[2].trim();
  }

  let body = Buffer.alloc(0);
  let count = 0;
  const result = truncated => ({url, status, headers, body: body.subarray(0, count), truncated});
  if (![200, 206].includes(status)) return result(false);
  if (headers["content-encoding"] && headers["content-encoding"] !== "identity") throw new MediaError("UNSUPPORTED_ENCODING");
  const transfer = headers["transfer-encoding"];
  const contentLength = headers["content-length"];
  if (transfer && (transfer.toLowerCase() !== "chunked" || contentLength !== undefined)) throw SOURCE_UNAVAILABLE();
  if (contentLength !== undefined && (!/^\d+$/.test(contentLength) || !Number.isSafeInteger(Number(contentLength)))) throw SOURCE_UNAVAILABLE();
  body = Buffer.allocUnsafe(contentLength === undefined ? cap : Math.min(cap, Number(contentLength)));

  const consume = async (size, allowEof) => {
    const end = Math.min(count + size, cap);
    while (count < end) {
      const bytes = await reader.take(end - count);
      if (bytes === null) {
        if (allowEof) return;
        throw SOURCE_UNAVAILABLE();
      }
      bytes.copy(body, count);
      count += bytes.length;
      budget.remaining -= bytes.length;
    }
  };

  if (transfer) {
    for (;;) {
      const sizeLine = await reader.line(1024);
      const size = Number.parseInt(/^([\da-f]+)(?:;.*)?$/i.exec(sizeLine)?.[1], 16);
      if (!Number.isSafeInteger(size)) throw SOURCE_UNAVAILABLE();
      if (size === 0) return result(false);
      if (count === cap) return result(true);
      const fits = size <= cap - count;
      await consume(size, false);
      if (!fits) return result(true);
      if (await reader.line(2) !== "") throw SOURCE_UNAVAILABLE();
    }
  }
  if (contentLength !== undefined) {
    const length = Number(contentLength);
    await consume(length, false);
    return result(length > cap);
  }
  await consume(cap, true);
  return result(count === cap && await reader.take(1) !== null);
}

// Pin the TCP connection to the classified address. TLS authenticates the original URL hostname.
export async function requestDenoPinned(url, ip, budget, range = null, cap = budget.remaining) {
  if (++budget.requests > 32 || budget.remaining <= 0 || cap <= 0) throw new MediaError("RESOURCE_LIMIT");
  const timeout = budget.time();
  const secure = url.protocol === "https:";
  let socket;
  let expired = false;
  const close = () => { try { socket?.close(); } catch { /* socket already closed */ } };
  let timer;
  const connect = async () => {
    socket = await Deno.connect({hostname: ip, port: Number(url.port || (secure ? 443 : 80))});
    if (expired) { close(); throw new MediaError("TIME_LIMIT"); }
    if (secure) {
      socket = await Deno.startTls(socket, {hostname: url.hostname.replace(/^\[|\]$/g, ""), alpnProtocols: ["http/1.1"]});
      if (expired) { close(); throw new MediaError("TIME_LIMIT"); }
    }
    const request = new TextEncoder().encode([
      "GET " + url.pathname + url.search + " HTTP/1.1",
      "Host: " + url.host,
      "Connection: close",
      "Accept: */*",
      "Accept-Encoding: identity",
      ...(range ? ["Range: " + range] : []),
      "", "",
    ].join("\r\n"));
    for (let sent = 0; sent < request.length;) sent += await socket.write(request.subarray(sent));
    return readResponse(socket, url, Math.min(cap, budget.remaining), budget);
  };
  try {
    const deadline = new Promise((_, reject) => {
      timer = setTimeout(() => {
        expired = true;
        close();
        reject(new MediaError("TIME_LIMIT"));
      }, timeout);
    });
    return await Promise.race([connect(), deadline]);
  } catch (error) {
    throw error instanceof MediaError ? error : SOURCE_UNAVAILABLE();
  } finally {
    clearTimeout(timer);
    close();
  }
}
