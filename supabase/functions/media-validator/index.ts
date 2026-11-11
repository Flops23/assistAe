import {createHandler,databaseRpc} from "./handler.mjs";
declare const EdgeRuntime: { waitUntil(task: Promise<unknown>): void };
const url=Deno.env.get("SUPABASE_URL");
let keys:Record<string,string>={};
try{keys=JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")||"{}");}catch{/* legacy managed env below */}
const key=Object.values(keys).find(v=>typeof v==="string"&&v.startsWith("sb_secret_"))||Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if(!url||!key)throw new Error("SERVER_CONFIGURATION_MISSING");
const background=(task:Promise<unknown>)=>{
  if(typeof EdgeRuntime!=="undefined")EdgeRuntime.waitUntil(task);else task.catch(()=>{});
};
Deno.serve(createHandler(databaseRpc(url,key),background));
