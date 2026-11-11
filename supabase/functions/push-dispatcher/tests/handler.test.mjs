import assert from "node:assert/strict";
import test from "node:test";
import { createPushHandler } from "../handler.mjs";

const id = "103db631-9064-4e33-ac60-17a174ef7db8";
const attempt = "10f92201-8498-4e15-90a5-46f1839f7ff2";
const fid = "d000000000000000000000";
const secret = "worker-secret";

function request(token = secret) {
  return new Request("https://example.test/push-dispatcher", {
    method: "POST",
    headers: { authorization: "Bearer " + token },
  });
}

function fixture({ enabled = true, target = { fid, kind: "room_invite" }, send } = {}) {
  const calls = [];
  const handler = createPushHandler({
    secret,
    enabled,
    async getAccessToken() {
      calls.push(["oauth"]);
      return "mock-oauth";
    },
    async rpc(operation, body) {
      calls.push([operation, body]);
      if (operation === "worker_claim_push") {
        return calls.filter(([name]) => name === operation).length === 1 ? { id, attempt } : null;
      }
      if (operation === "worker_prepare_push") return target;
      if (operation === "worker_finish_push") return true;
      throw Error("unexpected operation");
    },
    async sendMessage(token, payload) {
      calls.push(["send", token, payload]);
      return send ? send() : new Response("{}", { status: 200 });
    },
  });
  return { calls, handler };
}

test("ordinary and disabled requests cannot touch the queue or provider", async () => {
  const open = fixture();
  assert.equal((await open.handler(request("ordinary-user-token"))).status, 401);
  assert.deepEqual(open.calls, []);
  const disabled = fixture({ enabled: false });
  assert.equal((await disabled.handler(request())).status, 503);
  assert.deepEqual(disabled.calls, []);
});

test("a suppressed claim skips FCM", async () => {
  const { calls, handler } = fixture({ target: null });
  assert.equal((await handler(request())).status, 200);
  assert.equal(calls.some(([name]) => name === "send"), false);
});

test("delivery sends only discreet type-specific content to the FID", async () => {
  const { calls, handler } = fixture();
  const response = await handler(request());
  assert.deepEqual(await response.json(), { accepted: 1, suppressed: 0, retry: 0, failed: 0, stale: 0 });
  assert.deepEqual(calls[3], ["send", "mock-oauth", {
    message: {
      fid,
      data: { kind: "room_invite" },
      android: {
        ttl: "300s",
        restricted_package_name: "com.flops23.assistae",
        notification: {
          title: "assistAe", body: "Você recebeu um convite",
          channel_id: "assistae_social", visibility: "PUBLIC", tag: "room_invite",
        },
      },
    },
  }]);
  assert.deepEqual(calls[4], ["worker_finish_push", {
    p_id: id, p_attempt: attempt, p_result: "delivered", p_retry_seconds: null,
  }]);
});

test("FCM quota retries with its requested delay and stops the batch", async () => {
  const { calls, handler } = fixture({
    send: () => new Response("{}", { status: 429, headers: { "retry-after": "360" } }),
  });
  const response = await handler(request());
  assert.equal((await response.json()).retry, 1);
  assert.equal(calls.filter(([name]) => name === "worker_claim_push").length, 1);
  assert.equal(calls[4][1].p_retry_seconds, 360);
});

test("only explicit FCM UNREGISTERED invalidates an installation", async () => {
  const gone = fixture({
    send: () => Response.json({ error: { details: [
      { "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode: "UNREGISTERED" },
    ] } }, { status: 404 }),
  });
  await gone.handler(request());
  assert.equal(gone.calls[4][1].p_result, "unregistered");
  const missing = fixture({ send: () => new Response("{}", { status: 404 }) });
  await missing.handler(request());
  assert.equal(missing.calls[4][1].p_result, "retry");
});

test("a network failure records retry without disclosing provider response", async () => {
  const { calls, handler } = fixture({ send: () => { throw Error(fid); } });
  const response = await handler(request());
  assert.equal((await response.json()).retry, 1);
  assert.equal(calls[4][1].p_result, "retry");
});
