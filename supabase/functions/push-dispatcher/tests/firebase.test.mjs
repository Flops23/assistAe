import assert from "node:assert/strict";
import test from "node:test";
import { createFirebaseClient, readFirebaseCredentials } from "../firebase.mjs";

test("OAuth uses a signed JWT and caches the token without requiring network access", async () => {
  const algorithm = {
    name: "RSASSA-PKCS1-v1_5", modulusLength: 2048,
    publicExponent: Uint8Array.of(1, 0, 1), hash: "SHA-256",
  };
  const keys = await crypto.subtle.generateKey(algorithm, true, ["sign", "verify"]);
  const key = Buffer.from(await crypto.subtle.exportKey("pkcs8", keys.privateKey)).toString("base64");
  const account = readFirebaseCredentials(JSON.stringify({
    type: "service_account",
    project_id: "mock-test",
    client_email: "push@mock-test.iam.gserviceaccount.com",
    private_key: "-----BEGIN PRIVATE KEY-----\n" + key + "\n-----END PRIVATE KEY-----\n",
    token_uri: "https://example.test/unused",
  }));
  assert.ok(account);

  let exchanges = 0;
  const client = createFirebaseClient(account, async (url, request) => {
    if (url === "https://oauth2.googleapis.com/token") {
      exchanges++;
      assert.equal(request.body.get("grant_type"), "urn:ietf:params:oauth:grant-type:jwt-bearer");
      const [header, claims, signature] = request.body.get("assertion").split(".");
      assert.equal(JSON.parse(Buffer.from(header, "base64url")).alg, "RS256");
      const payload = JSON.parse(Buffer.from(claims, "base64url"));
      assert.equal(payload.iss, account.client_email);
      assert.equal(payload.scope, "https://www.googleapis.com/auth/firebase.messaging");
      assert.equal(payload.aud, url);
      assert.equal(payload.exp - payload.iat, 3600);
      assert.ok(await crypto.subtle.verify(
        algorithm, keys.publicKey, Buffer.from(signature, "base64url"), Buffer.from(header + "." + claims),
      ));
      return Response.json({ access_token: "mock-token", expires_in: 3600 });
    }

    assert.equal(url, "https://fcm.googleapis.com/v1/projects/mock-test/messages:send");
    assert.equal(request.headers.authorization, "Bearer mock-token");
    assert.equal(request.redirect, "error");
    assert.deepEqual(JSON.parse(request.body), { validate_only: true });
    return Response.json({});
  });

  const tokens = await Promise.all([client.getAccessToken(), client.getAccessToken()]);
  assert.deepEqual(tokens, ["mock-token", "mock-token"]);
  assert.equal(await client.getAccessToken(), "mock-token");
  assert.equal(exchanges, 1);
  assert.equal((await client.sendMessage(tokens[0], { validate_only: true })).status, 200);
});

test("incomplete credentials are rejected", () => {
  assert.equal(readFirebaseCredentials(null), null);
  assert.equal(readFirebaseCredentials("not json"), null);
  assert.equal(readFirebaseCredentials('{"type":"service_account"}'), null);
});
