import { createFirebaseClient, readFirebaseCredentials } from "./firebase.mjs";
import { createPushHandler } from "./handler.mjs";

const url = Deno.env.get("SUPABASE_URL");
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const account = readFirebaseCredentials(Deno.env.get("PUSH_FCM_SERVICE_ACCOUNT"));
const firebase = createFirebaseClient(account);

Deno.serve(createPushHandler({
  secret: serviceKey,
  enabled: Boolean(url && serviceKey && account && Deno.env.get("PUSH_ENABLED") === "true"),
  getAccessToken: firebase.getAccessToken,
  sendMessage: firebase.sendMessage,
  async rpc(operation: string, body: Record<string, unknown>) {
    const response = await fetch(new URL("/rest/v1/rpc/" + operation, url), {
      method: "POST",
      headers: {
        apikey: serviceKey ?? "",
        authorization: "Bearer " + serviceKey,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
      redirect: "error",
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok) {
      await response.body?.cancel();
      throw Error("Push outbox RPC failed");
    }
    return response.json();
  },
}));
