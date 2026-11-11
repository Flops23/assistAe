import test from "node:test";
import assert from "node:assert/strict";
import {existsSync} from "node:fs";
const path=new URL("../inspect.mjs",import.meta.url);
async function api(){assert.ok(existsSync(path),"media parser missing");return import(path.href);}
function box(type,data){const b=Buffer.alloc(8+data.length);b.writeUInt32BE(b.length);b.write(type,4);data.copy(b,8);return b;}
function mp4(duration=6000, format="avc1", extra=Buffer.alloc(0)){
  const mvhd=Buffer.alloc(20);
  mvhd.writeUInt32BE(1000,12);
  mvhd.writeUInt32BE(duration,16);
  const hdlr=Buffer.alloc(12);
  hdlr.write("vide",8);
  const stsd=Buffer.alloc(8);
  stsd.writeUInt32BE(1,4);
  const stsz=Buffer.alloc(12);
  stsz.writeUInt32BE(30,4);
  stsz.writeUInt32BE(1,8);
  const stbl=box("stbl",Buffer.concat([
    box("stsd",Buffer.concat([stsd,box(format,Buffer.alloc(78))])),box("stsz",stsz),
  ]));
  const trak=box("trak",box("mdia",Buffer.concat([box("hdlr",hdlr),box("minf",stbl)])));
  const moov=box("moov",Buffer.concat([box("mvhd",mvhd),trak,extra]));
  return Buffer.concat([box("ftyp",Buffer.from("isom0000isom")),moov,box("mdat",Buffer.alloc(30))]);
}
function fixture(data,contentType="video/mp4"){return async(url)=>({url:new URL(url),status:200,headers:{"content-type":contentType,"content-length":String(data.length)},body:Buffer.from(data),truncated:false});}
test("MP4 duration is read from mvhd, not caller metadata",async()=>{
  const {inspect}=await api();const r=await inspect("https://cdn.example/clip", {load:fixture(mp4())});
  assert.equal(r.kind,"mp4");assert.equal(r.duration_ms,6000);assert.equal(r.duration_confidence,"verified");assert.match(r.fingerprint,/^[a-f0-9]{64}$/);
});
test("safe finite MP4 with unknown duration allows manual advance",async()=>{
  const {inspect}=await api();const r=await inspect("http://cdn.example/clip.mp4",{load:fixture(mp4(0))});
  assert.equal(r.duration_ms,null);assert.equal(r.duration_confidence,"inconclusive");
});
test("HLS VOD durations are summed; live and private segment destinations fail",async()=>{
  const {inspect}=await api();const manifest="#EXTM3U\n#EXTINF:4.5,\na.ts\n#EXTINF:5.5,\nb.ts\n#EXT-X-ENDLIST\n";
  const options={load:fixture(Buffer.from(manifest),"application/vnd.apple.mpegurl"),resolver:async()=>["1.1.1.1"]};
  const r=await inspect("https://cdn.example/a.m3u8",options);assert.equal(r.duration_ms,10000);assert.equal(r.kind,"hls");
  await assert.rejects(inspect("https://cdn.example/a.m3u8",{...options,load:fixture(Buffer.from(manifest.replace("#EXT-X-ENDLIST","")))}),/LIVE_UNSUPPORTED/);
  await assert.rejects(inspect("https://cdn.example/a.m3u8",{...options,load:fixture(Buffer.from(manifest.replace("a.ts","http://169.254.169.254/a")))}),/FORBIDDEN_DESTINATION/);
});
test("ordinary pages do not become media merely because the URL ends in mp4",async()=>{
  const {inspect}=await api();await assert.rejects(inspect("https://cdn.example/fake.mp4",{load:fixture(Buffer.from("<html>login</html>"),"text/html")}),/UNSUPPORTED_FORMAT/);
});
test("MP4 with tracks but no media data is not admitted",async()=>{
  const {inspect}=await api();
  await assert.rejects(inspect("https://cdn.example/no-data.mp4",{load:fixture(mp4().subarray(0,-38))}),/MALFORMED_MP4/);
});
test("MP4 can read movie metadata after a large media box using matching ranges",async()=>{
  const {inspect}=await api();
  const data=Buffer.concat([mp4().subarray(0,20),box("mdat",Buffer.alloc(3*1024*1024)),mp4().subarray(20,-38)]);
  const offsets=[];
  const load=async(url,range)=>{
    const [,start,end]=/^bytes=(\d+)-(\d+)$/.exec(range).map(Number);
    const last=Math.min(end,data.length-1);
    offsets.push(start);
    return {url:new URL(url),status:206,headers:{"content-range":`bytes ${start}-${last}/${data.length}`},body:data.subarray(start,last+1),truncated:false};
  };
  assert.equal((await inspect("https://cdn.example/tail.mp4",{load})).duration_ms,6000);
  assert.deepEqual(offsets,[0,20+8+3*1024*1024]);
});
test("MP4 rejects protected sample entries and fragment initialization without proven VOD",async()=>{
  const {inspect}=await api();
  await assert.rejects(inspect("https://cdn.example/protected.mp4",{load:fixture(mp4(6000,"encv"))}),/DRM_UNSUPPORTED/);
  await assert.rejects(inspect("https://cdn.example/fragment.mp4",{load:fixture(mp4(6000,"avc1",box("mvex",Buffer.alloc(0))))}),/VOD_UNCONFIRMED/);
});
test("HLS rejects unsupported encryption and duplicate attributes in media and session keys",async()=>{
  const {inspect}=await api();
  const media=(key)=>Buffer.from(`#EXTM3U\n${key}\n#EXTINF:10,\na.ts\n#EXT-X-ENDLIST\n`);
  const url="https://cdn.example/a.m3u8";
  const opts=(data)=>({load:fixture(data),resolver:async()=>["1.1.1.1"]});
  await assert.rejects(inspect(url,opts(media('#EXT-X-KEY:METHOD=SAMPLE-AES,URI="key",X-METHOD=AES-128'))),/DRM_UNSUPPORTED/);
  await assert.rejects(inspect(url,opts(media('#EXT-X-KEY:METHOD=AES-128,KEYFORMAT="custom",URI="key",X-KEYFORMAT="identity"'))),/DRM_UNSUPPORTED/);
  await assert.rejects(inspect(url,opts(media('#EXT-X-KEY:METHOD=AES-128,METHOD=AES-128,URI="key"'))),/MALFORMED_HLS/);
  await assert.rejects(inspect(url,opts(media('#EXT-X-SESSION-KEY:METHOD=SAMPLE-AES,URI="key"'))),/DRM_UNSUPPORTED/);
  const accepted=await inspect(url,opts(media('#EXT-X-KEY:METHOD=AES-128,KEYFORMAT="identity",URI="key?q=a,b"')));
  assert.equal(accepted.duration_ms,10000);
});
test("an MP4 brand alone cannot produce a usable ticket",async()=>{
  const {inspect}=await api();
  await assert.rejects(inspect("https://cdn.example/fake.mp4",{load:fixture(box("ftyp",Buffer.from("isom0000isom")))}),/MALFORMED_MP4/);
});
test("unknown HLS attributes cannot mask the actual encryption method",async()=>{
  const {inspect}=await api();
  const manifest='#EXTM3U\n#EXT-X-KEY:METHOD=SAMPLE-AES,KEYFORMAT="com.apple.streamingkeydelivery",URI="https://cdn.example/key",X-METHOD=AES-128,X-KEYFORMAT="identity"\n#EXTINF:10,\na.ts\n#EXT-X-ENDLIST\n';
  await assert.rejects(inspect("https://cdn.example/a.m3u8",{load:fixture(Buffer.from(manifest)),resolver:async()=>["1.1.1.1"]}),/DRM_UNSUPPORTED/);
});
