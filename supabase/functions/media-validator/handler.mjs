import {inspect} from "./inspect.mjs";
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const failures=new Set(["INVALID_URL","FORBIDDEN_DESTINATION","SOURCE_UNAVAILABLE","RESOURCE_LIMIT","TIME_LIMIT","UNSUPPORTED_FORMAT","LIVE_UNSUPPORTED","VOD_UNCONFIRMED","MALFORMED_MP4","MALFORMED_HLS","DRM_UNSUPPORTED","UNSUPPORTED_ENCODING","REDIRECT_LIMIT","PLAYLIST_CYCLE"]);
const response=(status,body)=>new Response(JSON.stringify(body),{status,headers:{"Content-Type":"application/json","Cache-Control":"no-store"}});
export function databaseRpc(url,key){
  return async(name,args)=>{
    const headers={"Content-Type":"application/json",apikey:key};
    if(key.startsWith("eyJ"))headers.Authorization="Bearer "+key;
    const res=await fetch(url+"/rest/v1/rpc/"+name,{method:"POST",headers,body:JSON.stringify(args),redirect:"error",signal:AbortSignal.timeout(10000)});
    if(!res.ok)throw new Error("DATABASE_UNAVAILABLE");
    return res.json();
  };
}
export function createHandler(rpc,waitUntil){
  return async request=>{
    if(request.method!=="POST")return response(405,{code:"METHOD_NOT_ALLOWED"});
    let body;
    try{
      const reader=request.body?.getReader();if(!reader)return response(400,{code:"INVALID_INPUT"});
      const chunks=[];let n=0;
      try{for(;;){const r=await reader.read();if(r.done)break;n+=r.value.length;if(n>1024){await reader.cancel();return response(413,{code:"INVALID_INPUT"});}chunks.push(r.value);}}
      finally{reader.releaseLock();}
      const bytes=new Uint8Array(n);let at=0;for(const chunk of chunks){bytes.set(chunk,at);at+=chunk.length;}
      body=JSON.parse(new TextDecoder().decode(bytes));
      if(!body||Array.isArray(body)||Object.keys(body).length!==2||!UUID.test(body.validation_id)||!UUID.test(body.execution_token))return response(400,{code:"INVALID_INPUT"});
    }catch{return response(400,{code:"INVALID_INPUT"});}
    let job;
    try{job=await rpc("worker_claim_media_validation",{p_id:body.validation_id,p_token:body.execution_token});}
    catch{return response(503,{code:"TEMPORARILY_UNAVAILABLE"});}
    if(!job)return response(403,{code:"FORBIDDEN"});
    const task=(async()=>{
      let result;
      try{
        const r=await inspect(job.source_url);
        result={p_status:r.duration_confidence==="verified"?"valid":"inconclusive",p_kind:r.kind,p_duration:r.duration_ms,p_fingerprint:r.fingerprint,p_failure:null};
      }catch(error){result={p_status:"invalid",p_kind:null,p_duration:null,p_fingerprint:null,p_failure:failures.has(error.code)?error.code:"VALIDATOR_ERROR"};}
      // No URL, token, raw exception, or provider response is logged or returned.
      try{await rpc("worker_finish_media_validation",{p_id:job.validation_id,p_attempt:job.attempt_token,...result});}catch{/* lease expiry permits bounded retry */}
    })();
    waitUntil(task);
    return response(202,{accepted:true});
  };
}
