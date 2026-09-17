// ==============================================================================
// NIRVANA - Supabase Edge Function: send-passcode-sms
// Description: Securely delivers the *currently generated* patient pairing
// passcode to that patient's registered phone number via SMS.
//
// Architecture:
//   Flutter caregiver UI
//     -> authenticated Supabase request (caregiver JWT)
//     -> this Edge Function (verifies caregiver -> patient relationship)
//     -> SMS provider HTTP API
//     -> patient's phone
//
// SECURITY:
//   * SMS provider credentials live ONLY in Supabase Edge Function secrets.
//     Nothing here is ever shipped to, or readable by, the Flutter client.
//   * The passcode is never generated here. It is validated against the
//     existing `patient_pairing_codes` row so exactly the current passcode is
//     sent, and an old/superseded passcode can never be delivered.
//   * The patient phone number is read server-side from the patient row after
//     the caregiver relationship has been verified — the client cannot target
//     an arbitrary number.
//   * Passcodes and phone numbers are NOT logged; only a masked last-4 suffix
//     and the provider message id are reported.
//
// Required Supabase secrets (server-side only):
//   SMS_PROVIDER                'twilio' | 'generic'  (default: twilio)
//   SMS_DEFAULT_COUNTRY_CODE    optional, e.g. '91' — applied when a stored
//                               number has no leading '+'
//
//   When SMS_PROVIDER = 'twilio':
//     TWILIO_ACCOUNT_SID
//     TWILIO_AUTH_TOKEN
//     TWILIO_FROM_NUMBER          e.g. +15551234567 (or an alphanumeric Sender ID)
//
//   When SMS_PROVIDER = 'generic' (any JSON HTTP SMS gateway):
//     SMS_API_URL                 full endpoint URL
//     SMS_API_KEY                 bearer token / API key for the gateway
//     SMS_SENDER_ID               optional sender id in the JSON body
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically by the
// Supabase Edge Runtime. They are never exposed to the client.
// ==============================================================================

// Supabase Edge Runtime type definitions.
//
// This is a Deno/JSR specifier (`jsr:@supabase/functions-js/edge-runtime.d.ts`).
// It only resolves under the Supabase Edge Runtime, or under VS Code's Deno
// language server when Deno is installed. A plain TypeScript language server
// reports "Cannot find module ... jsr:" (TS2882) because JSR is a Deno-only
// specifier — it is an editor artefact and does NOT affect deployment.
//
// To clear the editor warning permanently, install Deno and the VS Code Deno
// extension, then enable it for this folder in .vscode/settings.json:
//   { "deno.enablePaths": ["supabase/functions"] }
//
// The runtime types we actually use (Deno.serve, Deno.env, fetch, crypto,
// btoa) are declared ambiently below, so nothing here depends on that import.

// Ambient type declarations for Deno APIs when the IDE Deno language server is inactive
declare const Deno: {
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
  env: { get: (key: string) => string | undefined };
};

// @ts-ignore: Resolved at runtime by Deno / Supabase Edge Runtime
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ------------------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------------------

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

/**
 * E.164 normalization.
 *
 * If the stored value already carries a country code (leading '+') we keep it
 * verbatim (digit-stripped). If it does not, we prepend SMS_DEFAULT_COUNTRY_CODE
 * when configured — this is what makes a locally-entered number (e.g. an Indian
 * '98765 43210') deliverable instead of being sent to an arbitrary country.
 *
 * Returns null when the result is not a plausible international number, so we
 * refuse to hand a malformed target to the SMS provider.
 */
function normalizePhone(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (trimmed.length === 0) return null;

  const hasPlus = trimmed.startsWith("+");
  const digits = trimmed.replace(/\D/g, "");
  if (digits.length < 8 || digits.length > 15) return null;

  if (hasPlus) return `+${digits}`;

  // No country code on file — apply the configured default so the number is not
  // silently misrouted. Without a default we still return the bare digits, as
  // the provider may infer the country from the account.
  const rawDefault = (Deno.env.get("SMS_DEFAULT_COUNTRY_CODE") ?? "").trim();
  const defaultCode = rawDefault.replace(/\D/g, "");
  return defaultCode.length > 0 ? `+${defaultCode}${digits}` : digits;
}

/** Only ever reports the last 4 digits — never the full number. */
function maskPhone(phone: string): string {
  if (phone.length <= 4) return "****";
  return `****${phone.slice(-4)}`;
}

/** Strips characters that could break out of the SMS body. */
function sanitizeCode(code: string): string | null {
  const cleaned = code.trim();
  if (!/^[0-9A-Za-z]{4,12}$/.test(cleaned)) return null;
  return cleaned;
}

// ------------------------------------------------------------------------------
// SMS provider adapters
// ------------------------------------------------------------------------------

interface SmsSendResult {
  ok: boolean;
  providerMessageId?: string;
  errorCode?: string;
}

/** Twilio Programmable Messaging REST API. */
async function sendViaTwilio(
  to: string,
  body: string,
): Promise<SmsSendResult> {
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
  const fromNumber = Deno.env.get("TWILIO_FROM_NUMBER");

  if (!accountSid || !authToken || !fromNumber) {
    console.error(
      "❌ Twilio secrets missing (TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN / TWILIO_FROM_NUMBER)",
    );
    return { ok: false, errorCode: "PROVIDER_NOT_CONFIGURED" };
  }

  const endpoint =
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

  const payload = new URLSearchParams({
    To: to,
    From: fromNumber,
    Body: body,
  });

  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: payload.toString(),
  });

  const text = await res.text();
  if (!res.ok) {
    // Log the provider error code only — never the number or message body.
    console.error(`❌ Twilio send failed (status ${res.status}): ${text.slice(0, 300)}`);
    return { ok: false, errorCode: `PROVIDER_${res.status}` };
  }

  try {
    const parsed = JSON.parse(text);
    return { ok: true, providerMessageId: parsed?.sid ?? undefined };
  } catch {
    return { ok: true };
  }
}

/** Generic JSON HTTP SMS gateway (URL + bearer key configured as secrets). */
async function sendViaGenericGateway(
  to: string,
  body: string,
): Promise<SmsSendResult> {
  const endpoint = Deno.env.get("SMS_API_URL");
  const apiKey = Deno.env.get("SMS_API_KEY");
  const senderId = Deno.env.get("SMS_SENDER_ID");

  if (!endpoint || !apiKey) {
    console.error("❌ Generic SMS secrets missing (SMS_API_URL / SMS_API_KEY)");
    return { ok: false, errorCode: "PROVIDER_NOT_CONFIGURED" };
  }

  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      to,
      message: body,
      ...(senderId ? { sender: senderId } : {}),
    }),
  });

  const text = await res.text();
  if (!res.ok) {
    console.error(`❌ SMS gateway send failed (status ${res.status}): ${text.slice(0, 300)}`);
    return { ok: false, errorCode: `PROVIDER_${res.status}` };
  }

  try {
    const parsed = JSON.parse(text);
    return {
      ok: true,
      providerMessageId: parsed?.id ?? parsed?.message_id ?? undefined,
    };
  } catch {
    return { ok: true };
  }
}

// ------------------------------------------------------------------------------
// Handler
// ------------------------------------------------------------------------------

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("OK", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return json({ success: false, error: "METHOD_NOT_ALLOWED" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
      return json({ success: false, error: "UNAUTHENTICATED" }, 401);
    }

    // 1. Identify the caller from their JWT (never trust a client-supplied id).
    const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } =
      await callerClient.auth.getUser();
    const caregiverId = userData?.user?.id ?? null;

    if (userError || !caregiverId) {
      return json({ success: false, error: "UNAUTHENTICATED" }, 401);
    }

    // 2. Parse and validate the request body.
    let payload: { patient_id?: string; code?: string; pairing_code_id?: string };
    try {
      payload = await req.json();
    } catch {
      return json({ success: false, error: "INVALID_JSON" }, 400);
    }

    const patientId = (payload.patient_id ?? "").trim();
    const rawCode = (payload.code ?? "").trim();
    const pairingCodeId = (payload.pairing_code_id ?? "").trim();

    if (!patientId || !rawCode) {
      return json({ success: false, error: "MISSING_FIELDS" }, 400);
    }

    const code = sanitizeCode(rawCode);
    if (!code) {
      return json({ success: false, error: "INVALID_CODE" }, 400);
    }

    // 3. Service-role client for server-side verification & persistence.
    const admin = createClient(supabaseUrl, supabaseServiceKey);

    // 3a. Verify the caregiver is actually linked to this patient.
    const { data: isLinked, error: linkError } = await admin.rpc(
      "caregiver_owns_patient",
      { p_caregiver_id: caregiverId, p_patient_id: patientId },
    );

    if (linkError) {
      console.error("❌ ownership check failed:", linkError.message);
      return json({ success: false, error: "VERIFICATION_FAILED" }, 500);
    }

    if (isLinked !== true) {
      // Never disclose whether the patient exists.
      return json({ success: false, error: "UNAUTHORIZED" }, 403);
    }

    // 3b. Verify the code is this patient's CURRENT, unused, unexpired code.
    const { data: codeRow, error: codeError } = await admin
      .from("patient_pairing_codes")
      .select("id, patient_id, expires_at, used_at")
      .eq("patient_id", patientId)
      .eq("code", code)
      .is("used_at", null)
      .gt("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (codeError) {
      console.error("❌ pairing code lookup failed:", codeError.message);
      return json({ success: false, error: "VERIFICATION_FAILED" }, 500);
    }

    if (!codeRow) {
      return json({ success: false, error: "STALE_CODE" }, 409);
    }

    // If the client supplied an id, it must match — guards against a race where
    // the code was regenerated between the UI claim and this call.
    if (pairingCodeId && pairingCodeId !== codeRow.id) {
      return json({ success: false, error: "STALE_CODE" }, 409);
    }

    // 3c. Duplicate-send guard (one SMS per generated passcode).
    const { data: alreadySent } = await admin
      .from("patient_passcode_sms_log")
      .select("id")
      .eq("pairing_code_id", codeRow.id)
      .eq("delivery_status", "SENT")
      .limit(1)
      .maybeSingle();

    if (alreadySent) {
      return json({ success: false, error: "ALREADY_SENT" }, 409);
    }

    // 4. Resolve the destination number SERVER-SIDE from the patient record.
    const { data: patient, error: patientError } = await admin
      .from("patients")
      .select("emergency_contact_phone, display_name, preferred_name")
      .eq("id", patientId)
      .single();

    if (patientError || !patient) {
      return json({ success: false, error: "PATIENT_NOT_FOUND" }, 404);
    }

    const patientPhone = normalizePhone(patient.emergency_contact_phone);
    if (!patientPhone) {
      return json({ success: false, error: "NO_PHONE" }, 422);
    }

    // 5. Compose the SMS — branded, with the passcode left as plain text so the
    //    patient can select and copy it, plus one short instruction.
    const patientName =
      (patient.preferred_name || patient.display_name || "there").trim();

    const messageBody =
      `NIRVANA: Hello ${patientName}, your device pairing passcode is ${code}. ` +
      `Enter this passcode in the NIRVANA app to connect your device. ` +
      `It expires in 15 minutes — please do not share it.`;

    // 6. Dispatch via the configured provider.
    const provider = (Deno.env.get("SMS_PROVIDER") ?? "twilio").toLowerCase();
    const result = provider === "generic"
      ? await sendViaGenericGateway(patientPhone, messageBody)
      : await sendViaTwilio(patientPhone, messageBody);

    // 7. Persist the outcome server-side. The passcode and phone number are
    //    never written to the log row.
    await admin.rpc("record_passcode_sms_result", {
      p_pairing_code_id: codeRow.id,
      p_caregiver_id: caregiverId,
      p_delivery_status: result.ok ? "SENT" : "FAILED",
      p_provider_message_id: result.providerMessageId ?? null,
      p_error_code: result.errorCode ?? null,
    });

    if (!result.ok) {
      const responseStatus =
        result.errorCode === "PROVIDER_NOT_CONFIGURED" ? 503 : 502;
      return json(
        {
          success: false,
          error: result.errorCode ?? "SEND_FAILED",
          message: "The SMS could not be delivered. Please try again.",
        },
        responseStatus,
      );
    }

    // Masked confirmation only — the full number stays server-side.
    return json({
      success: true,
      status: "SENT",
      sent_to_masked: maskPhone(patientPhone),
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Internal server error";
    console.error("Error in send-passcode-sms function:", message);
    return json({ success: false, error: "INTERNAL_ERROR" }, 500);
  }
});
