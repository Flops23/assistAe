import { isIP } from "node:net";
import { resolve4, resolve6 } from "node:dns/promises";
export class MediaError extends Error {
  constructor(code) { super(code); this.code = code; }
}
export function isPublicIp(ip) {
  const family = isIP(ip);
  if (family === 4) {
    const [a,b,c] = ip.split(".").map(Number);
    return !(a===0 || a===10 || a===127 || a>=224 ||
      (a===100 && b>=64 && b<=127) || (a===169 && b===254) ||
      (a===172 && b>=16 && b<=31) || (a===192 && (b===168 || (b===0 && (c===0 || c===2)) || (b===88 && c===99))) ||
      (a===198 && (b===18 || b===19 || (b===51 && c===100))) || (a===203 && b===0 && c===113));
  }
  if (family !== 6) return false;
  const [left,right] = ip.toLowerCase().split("::");
  const l = left ? left.split(":") : [], r = right ? right.split(":") : [];
  const groups = right === undefined ? l : [...l,...Array(8-l.length-r.length).fill("0"),...r];
  const [a,b] = groups.map(s=>parseInt(s,16));
  return a>=0x2000 && a<0x4000 && a!==0x2002 &&
    !(a===0x2001 && (b<0x200 || b===0xdb8)) && !(a===0x3fff && b<0x1000);
}
export function validateUrl(raw) {
  if (typeof raw!=="string" || new TextEncoder().encode(raw).length>8192 || /[\r\n\0]/.test(raw)) throw new MediaError("INVALID_URL");
  let url; try { url=new URL(raw); } catch { throw new MediaError("INVALID_URL"); }
  if (!["http:","https:"].includes(url.protocol) || url.username || url.password || url.hash) throw new MediaError("INVALID_URL");
  const host=url.hostname.replace(/^\[|\]$/g,"").toLowerCase();
  if (!host || host==="localhost" || /\.(localhost|local|internal)$/.test(host) ||
    (isIP(host) && !isPublicIp(host)) || ![80,443].includes(Number(url.port || (url.protocol==="https:"?443:80)))) throw new MediaError("FORBIDDEN_DESTINATION");
  return url;
}
const DOH_ENDPOINT = "https://cloudflare-dns.com/dns-query";
const MAX_DNS_BYTES = 32 * 1024;

async function nativeAnswers(query, host) {
  let timer;
  try {
    return await Promise.race([
      query(host),
      new Promise(resolve => { timer = setTimeout(() => resolve([]), 1500); }),
    ]);
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
}

async function dohAnswers(host, type, fetchAnswer) {
  const url = new URL(DOH_ENDPOINT);
  url.searchParams.set("name", host);
  url.searchParams.set("type", String(type));
  const response = await fetchAnswer(url, {
    headers: { Accept: "application/dns-json" },
    redirect: "error",
    signal: AbortSignal.timeout(2500),
  });
  if (!response.ok || !response.body) throw new MediaError("FORBIDDEN_DESTINATION");
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let bytes = 0;
  let body = "";
  try {
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      bytes += value.byteLength;
      if (bytes > MAX_DNS_BYTES) {
        await reader.cancel();
        throw new MediaError("FORBIDDEN_DESTINATION");
      }
      body += decoder.decode(value, { stream: true });
    }
    body += decoder.decode();
  } finally {
    reader.releaseLock();
  }
  const result = JSON.parse(body);
  if (result.TC || ![0, 3].includes(result.Status) || (result.Answer != null && !Array.isArray(result.Answer))) {
    throw new MediaError("FORBIDDEN_DESTINATION");
  }
  return (result.Answer ?? []).filter(record => record.type === 1 || record.type === 28).map(record => record.data);
}

export async function resolveDns(host, dependencies = {}) {
  const deno = globalThis.Deno;
  const native = await Promise.all([
    nativeAnswers(dependencies.resolve4 ?? (deno ? name => deno.resolveDns(name, "A") : resolve4), host),
    nativeAnswers(dependencies.resolve6 ?? (deno ? name => deno.resolveDns(name, "AAAA") : resolve6), host),
  ]);
  const addresses = native.flat();
  // resolvePublic must classify all returned addresses, including private records.
  if (addresses.length) return addresses;
  try {
    return (await Promise.all([1, 28].map(type => dohAnswers(host, type, dependencies.fetch ?? fetch)))).flat();
  } catch {
    throw new MediaError("FORBIDDEN_DESTINATION");
  }
}

export async function resolvePublic(url,resolver=resolveDns) {
  const host=url.hostname.replace(/^\[|\]$/g,"");
  const addresses=isIP(host)?[host]:await resolver(host);
  if (!addresses.length || addresses.some(ip=>!isPublicIp(ip))) throw new MediaError("FORBIDDEN_DESTINATION");
  return addresses[0];
}
