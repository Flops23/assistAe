import {MediaError,validateUrl,resolvePublic} from "./policy.mjs";
import {requestDenoPinned} from "./deno-transport.mjs";
export class Budget {
  constructor(bytes=4*1024*1024,milliseconds=15000){this.remaining=bytes;this.deadline=Date.now()+milliseconds;this.requests=0;}
  time(){const n=this.deadline-Date.now();if(n<=0)throw new MediaError("TIME_LIMIT");return n;}
}
export async function timed(promise,budget){
  let timer;try{return await Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(new MediaError("TIME_LIMIT")),budget.time());})]);}
  finally{clearTimeout(timer);}
}
export async function fetchLimited(raw,budget,range=null,cap=budget.remaining,dependencies={}){
  let url=validateUrl(raw);
  for(let redirects=0;;redirects++){
    const ip=await timed(resolvePublic(url,dependencies.resolver),budget);
    const request=dependencies.request||requestDenoPinned;
    const r=await request(url,ip,budget,range,cap);
    if([301,302,303,307,308].includes(r.status)){
      if(redirects>=3 || typeof r.headers.location!=="string")throw new MediaError("REDIRECT_LIMIT");
      url=validateUrl(new URL(r.headers.location,url).href);continue;
    }
    if(![200,206].includes(r.status))throw new MediaError("SOURCE_UNAVAILABLE");
    return {...r,url};
  }
}
