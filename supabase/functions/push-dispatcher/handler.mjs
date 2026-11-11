const titles = {
  room_invite: "Você recebeu um convite",
  friend_request: "Nova solicitação de amizade",
};

async function matchesAuthorization(request, secret) {
  const header = request.headers.get("authorization");
  if (!secret || !header?.startsWith("Bearer ")) return false;
  const encoder = new TextEncoder();
  const [provided, expected] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(header.slice(7))),
    crypto.subtle.digest("SHA-256", encoder.encode(secret)),
  ]);
  const first = new Uint8Array(provided);
  const second = new Uint8Array(expected);
  let difference = 0;
  for (let index = 0; index < first.length; index++) difference |= first[index] ^ second[index];
  return difference === 0;
}

function retryAfterSeconds(header) {
  if (header === null) return null;
  if (/^\d+$/.test(header)) return Math.min(86400, Number(header));
  const until = Date.parse(header);
  return Number.isFinite(until) ? Math.min(86400, Math.max(0, Math.ceil((until - Date.now()) / 1000))) : null;
}

async function dispatch(sendMessage, token, target) {
  if (!Object.hasOwn(titles, target.kind) || !/^[A-Za-z0-9_-]{22}$/.test(target.fid)) {
    return { result: "failed" };
  }
  const payload = {
    message: {
      fid: target.fid,
      data: { kind: target.kind },
      android: {
        ttl: "300s",
        restricted_package_name: "com.flops23.assistae",
        notification: {
          title: "assistAe",
          body: titles[target.kind],
          channel_id: "assistae_social",
          visibility: "PUBLIC",
          tag: target.kind,
        },
      },
    },
  };

  try {
    const response = await sendMessage(token, payload);
    if (response.ok) {
      await response.body?.cancel();
      return { result: "delivered" };
    }

    const error = (await response.json().catch(() => null))?.error;
    const code = Array.isArray(error?.details) ? error.details.find(
      (detail) => detail?.["@type"] === "type.googleapis.com/google.firebase.fcm.v1.FcmError",
    )?.errorCode : null;
    if (response.status === 404 && code === "UNREGISTERED") return { result: "unregistered" };
    if (response.status === 400 || code === "SENDER_ID_MISMATCH") return { result: "failed" };
    return {
      result: "retry",
      retrySeconds: retryAfterSeconds(response.headers.get("retry-after")),
      pause: true,
    };
  } catch {
    return { result: "retry", pause: true };
  }
}

export function createPushHandler({ secret, enabled, getAccessToken, rpc, sendMessage }) {
  return async (request) => {
    if (request.method !== "POST") return Response.json({ error: "METHOD_NOT_ALLOWED" }, { status: 405 });
    if (!await matchesAuthorization(request, secret)) {
      return Response.json({ error: "UNAUTHORIZED" }, { status: 401 });
    }
    if (!enabled) return Response.json({ error: "PUSH_DISABLED" }, { status: 503 });

    const counts = { accepted: 0, suppressed: 0, retry: 0, failed: 0, stale: 0 };
    const deadline = Date.now() + 35000;
    try {
      // Check Firebase credentials before taking ownership of any outbox row.
      const token = await getAccessToken();
      for (let index = 0; index < 6 && Date.now() < deadline; index++) {
        const claim = await rpc("worker_claim_push", {});
        if (!claim) break;
        const attempt = { p_id: claim.id, p_attempt: claim.attempt };
        const target = await rpc("worker_prepare_push", attempt);
        if (!target) {
          counts.suppressed++;
          continue;
        }
        const outcome = await dispatch(sendMessage, token, target);
        const finished = await rpc("worker_finish_push", {
          ...attempt,
          p_result: outcome.result,
          p_retry_seconds: outcome.retrySeconds ?? null,
        });
        if (!finished) counts.stale++;
        else if (outcome.result === "delivered") counts.accepted++;
        else if (outcome.result === "retry") counts.retry++;
        else counts.failed++;
        if (outcome.pause) break;
      }
      return Response.json(counts);
    } catch {
      return Response.json({ error: "DISPATCH_UNAVAILABLE" }, { status: 503 });
    }
  };
}
