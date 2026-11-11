import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import { existsSync } from "node:fs";
const target=new URL("../transport.mjs",import.meta.url);
async function api(){assert.ok(existsSync(target),"pinned transport missing");return import(target.href);}
test("transport bounds bytes and never forwards app credentials/cookies",async()=>{
  const {Budget}=await api();
  const {requestDenoPinned}=await import("../deno-transport.mjs");
  let headers;
  const server=http.createServer((req,res)=>{headers=req.headers;res.writeHead(200,{"Content-Length":"10000"});res.end(Buffer.alloc(10000,65));});
  await new Promise(r=>server.listen(0,"127.0.0.1",r));
  try{
    const url=new URL("http://127.0.0.1:"+server.address().port+"/media");
    const result=await requestDenoPinned(url,"127.0.0.1",new Budget(100,2000),"bytes=0-99",100);
    assert.equal(result.body.length,100);assert.equal(result.truncated,true);
    assert.equal(headers.authorization,undefined);assert.equal(headers.cookie,undefined);
    assert.equal(headers.range,"bytes=0-99");
  }finally{await new Promise(r=>server.close(r));}
});
test("the pinned connection decodes bounded chunked bodies",async()=>{
  const {Budget}=await api();
  const {requestDenoPinned}=await import("../deno-transport.mjs");
  const server=http.createServer((_req,res)=>{res.writeHead(200);res.write("abc");res.end("def");});
  await new Promise(r=>server.listen(0,"127.0.0.1",r));
  try{
    const url=new URL("http://fixture.example:"+server.address().port+"/media");
    const exact=await requestDenoPinned(url,"127.0.0.1",new Budget(6,2000));
    assert.equal(exact.body.toString(),"abcdef");assert.equal(exact.truncated,false);
    const bounded=await requestDenoPinned(url,"127.0.0.1",new Budget(4,2000));
    assert.equal(bounded.body.toString(),"abcd");assert.equal(bounded.truncated,true);
  }finally{await new Promise(r=>server.close(r));}
});
test("redirect into private network is refused",async()=>{
  const {Budget,fetchLimited}=await api();
  await assert.rejects(fetchLimited("https://cdn.example/a",new Budget(),null,100,{
    resolver:async()=>["1.1.1.1"],request:async()=>({status:302,headers:{location:"http://127.0.0.1/secret"},body:new Uint8Array(),truncated:false})
  }),/FORBIDDEN_DESTINATION/);
});
