import test from "node:test";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
const moduleUrl = new URL("../policy.mjs", import.meta.url);
async function api() {
  assert.ok(existsSync(moduleUrl), "media URL/IP policy missing");
  return import(moduleUrl.href);
}
test("only globally routable IP addresses are admitted", async () => {
  const { isPublicIp } = await api();
  for (const ip of ["8.8.8.8", "1.1.1.1", "2001:4860:4860::8888", "2606:4700:4700::1111"]) assert.equal(isPublicIp(ip), true, ip);
  for (const ip of ["0.0.0.0","10.1.2.3","100.64.0.1","127.0.0.1","169.254.169.254","172.16.0.1","192.168.1.1","192.0.2.1","198.18.0.1","198.51.100.1","203.0.113.1","224.0.0.1","255.255.255.255","::1","::ffff:127.0.0.1","64:ff9b::7f00:1","fc00::1","fe80::1","2001::1","2001:db8::1","2002:7f00:1::","3fff::1","not-an-ip"]) assert.equal(isPublicIp(ip), false, ip);
});
test("signed HTTP and HTTPS URLs survive; credentials/private schemes/ports do not", async () => {
  const { validateUrl } = await api();
  const signed = "https://cdn.example/video.mp4?token=a%2Fb%3D&expires=123";
  assert.equal(validateUrl(signed).href, signed);
  assert.equal(validateUrl("http://cdn.example/video.m3u8").protocol, "http:");
  for (const value of ["file:///etc/passwd","ftp://example.com/a","https://u:p@example.com/a","http://localhost/a","http://127.1/a","http://2130706433/a","http://[::ffff:127.0.0.1]/a","http://example.com:8080/a"]) assert.throws(() => validateUrl(value), value);
});
test("mixed public/private DNS records fail closed", async () => {
  const { resolvePublic, validateUrl } = await api();
  await assert.rejects(resolvePublic(validateUrl("https://cdn.example/a"), async () => ["1.1.1.1","10.0.0.1"]));
  assert.equal(await resolvePublic(validateUrl("https://cdn.example/a"), async () => ["1.1.1.1"]), "1.1.1.1");
});
test("DNS fallback uses only the fixed resolver and rejects non-public answers", async () => {
  const { resolveDns, resolvePublic, validateUrl } = await api();
  const url=validateUrl("https://cdn.example/clip?signature=private");
  const fail=async()=>{throw new Error("DNS unavailable");};
  const queried=[];
  let v6="2606:4700::1111";
  const fetchAnswer=async(input,options)=>{
    queried.push(input);
    assert.equal(input.origin,"https://cloudflare-dns.com");
    assert.equal(input.pathname,"/dns-query");
    assert.equal(input.searchParams.get("name"),"cdn.example");
    assert.equal(options.redirect,"error");
    const type=Number(input.searchParams.get("type"));
    return Response.json({Status:0,Answer:[{type,data:type===1?"1.1.1.1":v6}]});
  };
  const resolver=(host)=>resolveDns(host,{resolve4:fail,resolve6:fail,fetch:fetchAnswer});
  assert.equal(await resolvePublic(url,resolver),"1.1.1.1");
  assert.equal(queried.length,2);
  v6="::1";
  await assert.rejects(resolvePublic(url,resolver),/FORBIDDEN_DESTINATION/);
  const native=(host)=>resolveDns(host,{resolve4:async()=>["10.0.0.1"],resolve6:fail,fetch:fetchAnswer});
  await assert.rejects(resolvePublic(url,native),/FORBIDDEN_DESTINATION/);
  assert.equal(queried.length,4,"native private answer did not trigger fallback");
});
