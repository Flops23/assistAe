import {Buffer} from "node:buffer";
import {createHash} from "node:crypto";
import {Budget,fetchLimited,timed} from "./transport.mjs";
import {validateUrl,resolvePublic,MediaError} from "./policy.mjs";
const HALF=2*1024*1024,SAFE=Number.MAX_SAFE_INTEGER;
function boxes(b,start=0,end=b.length,logicalEnd=end){
  const result=[];
  for(let at=start;at+8<=end;){
    let size=b.readUInt32BE(at),header=8;
    if(size===1){if(at+16>end)break;const n=b.readBigUInt64BE(at+8);if(n>BigInt(SAFE))throw new MediaError("MALFORMED_MP4");size=Number(n);header=16;}
    if(size===0)size=logicalEnd-at;
    if(size<header)throw new MediaError("MALFORMED_MP4");
    result.push({at,size,header,type:b.toString("ascii",at+4,at+8),complete:at+size<=end});
    if(at+size>end)break;at+=size;
  }return result;
}
function childBoxes(body, start, end) {
  const children = boxes(body, start, end);
  const last = children.at(-1);
  if ((last ? last.at + last.size : start) !== end) throw new MediaError("MALFORMED_MP4");
  if (children.some(box => box.type === "pssh")) throw new MediaError("DRM_UNSUPPORTED");
  return children;
}

function boxChildren(body, box) {
  return box ? childBoxes(body, box.at + box.header, box.at + box.size) : [];
}

function hasMediaSamples(body, track) {
  const media = boxChildren(body, track).find(box => box.type === "mdia");
  const mediaChildren = boxChildren(body, media);
  const handler = mediaChildren.find(box => box.type === "hdlr");
  if (!handler || handler.size < handler.header + 12) return false;
  const type = body.toString("ascii", handler.at + handler.header + 8, handler.at + handler.header + 12);
  if (type !== "vide" && type !== "soun") return false;
  const info = mediaChildren.find(box => box.type === "minf");
  const table = boxChildren(body, info).find(box => box.type === "stbl");
  const sampleTables = boxChildren(body, table);
  const description = sampleTables.find(box => box.type === "stsd");
  const sizes = sampleTables.find(box => box.type === "stsz" || box.type === "stz2");
  if (!description || description.size < description.header + 8) return false;
  const start = description.at + description.header;
  const entries = childBoxes(body, start + 8, description.at + description.size);
  if (!entries.length || entries.length !== body.readUInt32BE(start + 4)) throw new MediaError("MALFORMED_MP4");
  for (const entry of entries) {
    if (["encv", "enca", "drmi", "drms"].includes(entry.type)) throw new MediaError("DRM_UNSUPPORTED");
    const payloadStart = entry.at + entry.header;
    const payloadLength = entry.size - entry.header;
    const audioVersion = type === "soun" && payloadLength >= 28 ? body.readUInt16BE(payloadStart + 8) : 0;
    const fields = type === "vide" ? 78 : audioVersion === 1 ? 44 : audioVersion === 2 ? 64 : 28;
    if (payloadLength < fields) throw new MediaError("MALFORMED_MP4");
    const extensions = childBoxes(body, payloadStart + fields, entry.at + entry.size);
    if (extensions.some(box => box.type === "sinf")) throw new MediaError("DRM_UNSUPPORTED");
  }
  return Boolean(sizes && sizes.size >= sizes.header + 12 && body.readUInt32BE(sizes.at + sizes.header + 8));
}

function movieDuration(body, moov) {
  if (!moov.complete) throw new MediaError("MALFORMED_MP4");
  const children = boxChildren(body, moov);
  if (children.some(box => box.type === "mvex")) throw new MediaError("VOD_UNCONFIRMED");
  let hasSamples = false;
  for (const track of children.filter(box => box.type === "trak")) {
    if (hasMediaSamples(body, track)) hasSamples = true;
  }
  const mvhd = children.find(box => box.type === "mvhd");
  if (!hasSamples || !mvhd) throw new MediaError("MALFORMED_MP4");
  const bytes = body.subarray(mvhd.at + mvhd.header, mvhd.at + mvhd.size);
  let scale,duration;
  if(bytes[0]===0 && bytes.length>=20){scale=bytes.readUInt32BE(12);const d=bytes.readUInt32BE(16);duration=d===0xffffffff?0n:BigInt(d);}
  else if(bytes[0]===1 && bytes.length>=32){scale=bytes.readUInt32BE(20);duration=bytes.readBigUInt64BE(24);if(duration===0xffffffffffffffffn)duration=0n;}
  else throw new MediaError("MALFORMED_MP4");
  if (!scale) throw new MediaError("MALFORMED_MP4");
  if (!duration) return null;
  const ms=(duration*1000n+BigInt(Math.floor(scale/2)))/BigInt(scale);
  return ms>0n&&ms<=BigInt(SAFE)?Number(ms):null;
}
function totalLength(r, offset = 0){
  if (r.status === 206) {
    const range = /^bytes (\d+)-(\d+)\/(\d+)$/.exec(r.headers["content-range"] || "");
    if (!range) return null;
    const [start, end, total] = range.slice(1).map(Number);
    return start === offset && start <= end && end < total && Number.isSafeInteger(total) &&
      r.body.length <= end - start + 1 && (r.truncated || r.body.length === end - start + 1) ? total : null;
  }
  const n=Number(r.headers["content-length"]);return Number.isSafeInteger(n)&&n>0?n:null;
}

function hlsAttributes(text) {
  const attributes = new Map();
  const attribute = /([A-Z0-9-]+)=("[^"\r\n]*"|[^,\s"]+)(,|$)/y;
  let at = 0;
  while (at < text.length) {
    attribute.lastIndex = at;
    const match = attribute.exec(text);
    if (!match || attributes.has(match[1])) throw new MediaError("MALFORMED_HLS");
    attributes.set(match[1], match[2]);
    at = attribute.lastIndex;
    if (at === text.length && match[3]) throw new MediaError("MALFORMED_HLS");
  }
  if (!attributes.size) throw new MediaError("MALFORMED_HLS");
  return attributes;
}
export async function inspect(raw,options={}){
  validateUrl(raw);
  const budget=options.budget||new Budget(),hash=createHash("sha256"),hosts=new Map();
  const load=async(url,range,cap)=>{
    budget.time();
    const r=await (options.load||((u,r,c)=>fetchLimited(u,budget,r,c)))(url,range,cap);
    hash.update(r.url.href);hash.update(r.body);return r;
  };
  const check=async(value,base)=>{
    if (value.includes("{$")) throw new MediaError("UNSUPPORTED_FORMAT");
    const url=validateUrl(new URL(value,base).href);
    if(!hosts.has(url.hostname)){
      if(hosts.size>=64)throw new MediaError("RESOURCE_LIMIT");
      hosts.set(url.hostname,await timed(resolvePublic(url,options.resolver),budget));
    }
    return url.href;
  };
  const first=await load(raw,"bytes=0-"+(HALF-1),HALF);
  const text=new TextDecoder().decode(first.body);
  let kind,duration;
  if(text.replace(/^\uFEFF/,"").startsWith("#EXTM3U")){
    kind="hls";
    const visited=new Set();
    const playlist=async(result,masterAllowed)=>{
      if(result.truncated || (result.status === 206 && totalLength(result) !== result.body.length)) throw new MediaError("RESOURCE_LIMIT");
      if(visited.has(result.url.href))throw new MediaError("PLAYLIST_CYCLE");visited.add(result.url.href);
      const lines=new TextDecoder().decode(result.body).replace(/^\uFEFF/,"").split(/\r?\n/).map(s=>s.trim()).filter(Boolean);
      if(lines[0]!=="#EXTM3U")throw new MediaError("UNSUPPORTED_FORMAT");
      if(lines.length>20000)throw new MediaError("RESOURCE_LIMIT");
      const variants = [];
      let nextVariant = false, sum = 0, segments = 0, durationForSegment = null, hasStream = false;
      for(const line of lines.slice(1)){
        if (line.startsWith("#EXTINF:")) {
          if (nextVariant || durationForSegment !== null) throw new MediaError("MALFORMED_HLS");
          const token = line.slice(8).split(",", 1)[0];
          const value = Number(token);
          if (!/^\d+(?:\.\d+)?$/.test(token) || !Number.isFinite(value)) throw new MediaError("MALFORMED_HLS");
          durationForSegment = value;
          continue;
        }
        if (!line.startsWith("#")) {
          const ref = await check(line, result.url);
          if (nextVariant) {
            variants.push(ref);
            nextVariant = false;
          } else {
            if (durationForSegment === null) throw new MediaError("MALFORMED_HLS");
            sum += durationForSegment;
            durationForSegment = null;
            segments++;
          }
          continue;
        }
        const colon = line.indexOf(":");
        if (colon < 0) continue;
        const tag = line.slice(0, colon);
        const value = line.slice(colon + 1);
        if (tag === "#EXT-X-CONTENT-STEERING" || tag === "#EXT-X-DEFINE") throw new MediaError("UNSUPPORTED_FORMAT");
        if (tag === "#EXT-X-STREAM-INF") {
          if (nextVariant || durationForSegment !== null) throw new MediaError("MALFORMED_HLS");
          nextVariant = hasStream = true;
        }
        const key = tag === "#EXT-X-KEY" || tag === "#EXT-X-SESSION-KEY";
        if (!key && !/(^|,)URI=/.test(value)) continue;
        const attrs = hlsAttributes(value);
        if (key) {
          const method = attrs.get("METHOD");
          if (!["NONE", "AES-128"].includes(method) || (attrs.has("KEYFORMAT") && attrs.get("KEYFORMAT") !== '"identity"')) {
            throw new MediaError("DRM_UNSUPPORTED");
          }
          if (method === "AES-128" && !attrs.has("URI")) throw new MediaError("MALFORMED_HLS");
        }
        if (!attrs.has("URI")) continue;
        const uri = attrs.get("URI");
        if (!/^"[^"]+"$/.test(uri)) throw new MediaError("MALFORMED_HLS");
        const ref = await check(uri.slice(1, -1), result.url);
        if (["#EXT-X-MEDIA", "#EXT-X-I-FRAME-STREAM-INF", "#EXT-X-IMAGE-STREAM-INF"].includes(tag)) variants.push(ref);
      }
      if (nextVariant || durationForSegment !== null) throw new MediaError("MALFORMED_HLS");
      if(hasStream || variants.length){
        if(!masterAllowed || segments || !variants.length || variants.length>16) throw new MediaError("MALFORMED_HLS");
        const durations=[];
        for(const uri of [...new Set(variants)])durations.push(await playlist(await load(uri,null,Math.min(256*1024,budget.remaining)),false));
        if(durations.some(d=>d===null))return null;
        return Math.max(...durations)-Math.min(...durations)<=1000?Math.max(...durations):null;
      }
      if(!lines.includes("#EXT-X-ENDLIST"))throw new MediaError("LIVE_UNSUPPORTED");
      if(!segments)throw new MediaError("MALFORMED_HLS");
      const ms=Math.round(sum*1000);
      return ms>0 && ms<=SAFE?ms:null;
    };
    duration=await playlist(first,true);
  }else{
    kind="mp4";let r=first,offset=0;const length=totalLength(first);
    const firstBody = Buffer.from(first.body);
    const initial=boxes(firstBody);
    const ftyp=initial.find(b=>b.type==="ftyp"&&b.complete);
    if(!ftyp || ftyp.size<16 || !/(isom|iso[2-9]|mp4[12]|avc1|M4V |MSNV|qt  )/.test(Buffer.from(first.body).toString("ascii",ftyp.at+8,ftyp.at+ftyp.size)))throw new MediaError("UNSUPPORTED_FORMAT");
    if(!length || firstBody.length > length) throw new MediaError("VOD_UNCONFIRMED");
    let movie = false, data = false;
    for(let round=0;round<8;round++){
      const body = Buffer.from(r.body);
      const list=boxes(body, 0, body.length, length - offset);
      let next = offset;
      for (const box of list) {
        const end = offset + box.at + box.size;
        if (end > length) throw new MediaError("MALFORMED_MP4");
        if (box.type === "pssh") throw new MediaError("DRM_UNSUPPORTED");
        if (box.type === "moof") throw new MediaError("VOD_UNCONFIRMED");
        if (box.type === "moov") {
          if (!box.complete) {
            next = offset + box.at;
            break;
          }
          duration = movieDuration(body, box);
          movie = true;
        }
        if (box.type === "mdat" && box.size > box.header) data = true;
        next = end;
      }
      if (movie && data) break;
      if(next>=length || next<=offset || budget.remaining<=0)break;
      const cap=Math.min(HALF,budget.remaining);
      const follow=await load(raw,"bytes="+next+"-"+Math.min(length-1,next+cap-1),cap);
      if(follow.status!==206 || totalLength(follow, next) !== length || follow.url.href !== first.url.href)break;
      offset=next;r=follow;
    }
    if (!movie || !data) throw new MediaError("MALFORMED_MP4");
  }
  return {kind,duration_ms:duration,duration_confidence:duration===null?"inconclusive":"verified",fingerprint:hash.digest("hex")};
}
