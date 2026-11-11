import test from "node:test";
import assert from "node:assert/strict";
import {createHandler} from "../handler.mjs";
test("worker rejects malformed/oversized requests and invalid job capability",async()=>{
 const handler=createHandler(async()=>null,()=>{});
 const url="https://worker.example/media-validator";
 assert.equal((await handler(new Request(url))).status,405);
 assert.equal((await handler(new Request(url,{method:"POST",body:"x".repeat(1025)}))).status,413);
 assert.equal((await handler(new Request(url,{method:"POST",body:JSON.stringify({source_url:"http://localhost"})}))).status,400);
 const res=await handler(new Request(url,{method:"POST",body:JSON.stringify({validation_id:"11111111-1111-4111-8111-111111111111",execution_token:"22222222-2222-4222-8222-222222222222"})}));
 assert.equal(res.status,403);assert.deepEqual(await res.json(),{code:"FORBIDDEN"});
});
