const oauthUrl = "https://oauth2.googleapis.com/token";
const messagingScope = "https://www.googleapis.com/auth/firebase.messaging";
const signing = { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" };

export function readFirebaseCredentials(config) {
  if (!config) return null;
  try {
    const account = JSON.parse(config);
    if (account?.type !== "service_account" ||
        typeof account.project_id !== "string" || !/^[a-z][a-z0-9-]{4,29}$/.test(account.project_id) ||
        typeof account.client_email !== "string" || !account.client_email.endsWith(".iam.gserviceaccount.com") ||
        typeof account.private_key !== "string" || !account.private_key.startsWith("-----BEGIN PRIVATE KEY-----")) return null;
    return account;
  } catch {
    return null;
  }
}

function base64Url(bytes) {
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function jwt(account) {
  const encoder = new TextEncoder();
  const pem = account.private_key.replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "").replace(/\s+/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8", Uint8Array.from(atob(pem), (byte) => byte.charCodeAt(0)), signing, false, ["sign"],
  );
  const iat = Math.floor(Date.now() / 1000);
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64Url(encoder.encode(JSON.stringify({
    iss: account.client_email, scope: messagingScope, aud: oauthUrl, iat, exp: iat + 3600,
  })));
  const unsigned = header + "." + claims;
  const signature = await crypto.subtle.sign(signing, key, encoder.encode(unsigned));
  return unsigned + "." + base64Url(new Uint8Array(signature));
}

export function createFirebaseClient(account, fetchFn = fetch) {
  let cached;
  let refresh;

  async function exchange() {
    if (!account) throw Error("FCM configuration unavailable");
    const response = await fetchFn(oauthUrl, {
      method: "POST",
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: await jwt(account),
      }),
      redirect: "error",
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) {
      await response.body?.cancel();
      throw Error("FCM OAuth unavailable");
    }
    const token = await response.json();
    if (typeof token.access_token !== "string" || !token.access_token ||
        !Number.isFinite(token.expires_in) || token.expires_in <= 0) throw Error("FCM OAuth response invalid");
    cached = { value: token.access_token, expires: Date.now() + token.expires_in * 1000 };
    return cached.value;
  }

  return {
    async getAccessToken() {
      if (cached && cached.expires > Date.now() + 60000) return cached.value;
      refresh ??= exchange().finally(() => { refresh = undefined; });
      return refresh;
    },

    sendMessage(token, payload) {
      if (!account) throw Error("FCM configuration unavailable");
      return fetchFn("https://fcm.googleapis.com/v1/projects/" + account.project_id + "/messages:send", {
        method: "POST",
        headers: { authorization: "Bearer " + token, "content-type": "application/json" },
        body: JSON.stringify(payload),
        redirect: "error",
        signal: AbortSignal.timeout(8000),
      });
    },
  };
}
