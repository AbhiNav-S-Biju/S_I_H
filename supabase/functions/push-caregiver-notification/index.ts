// ==============================================================================
// NIRVANA - Supabase Edge Function: push-caregiver-notification
// Description: Secure server-side push notification dispatcher.
// Triggered by Supabase Database Webhook on INSERT into caregiver_notifications.
// Dispatches FCM messages using Firebase Cloud Messaging HTTP v1 API.
//
// SECURITY:
// - Firebase Service Account credentials are kept strictly in Supabase Secrets.
// - No service credentials are ever stored in or transmitted to the mobile client.
// ==============================================================================

// Setup type definitions for Supabase Edge Runtime
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Ambient type declaration for Deno APIs when IDE Deno language server is inactive
declare const Deno: {
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
  env: {
    get: (key: string) => string | undefined;
  };
};
// @ts-ignore: Resolved at runtime by Deno / Supabase Edge Runtime
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: {
    id: string;
    caregiver_id: string;
    patient_id: string;
    notification_type: string;
    title: string;
    message: string;
    related_reminder_id?: string | null;
    related_game_session_id?: string | null;
    created_at: string;
  };
}

interface ServiceAccountKey {
  project_id: string;
  client_email: string;
  private_key: string;
}

// Generate Google OAuth2 Access Token for FCM HTTP v1 API
async function getAccessToken(serviceAccount: ServiceAccountKey): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: exp,
    iat: iat,
  };

  const encodeBase64Url = (str: string) =>
    btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const encodedHeader = encodeBase64Url(JSON.stringify(header));
  const encodedClaim = encodeBase64Url(JSON.stringify(claimSet));
  const signatureInput = `${encodedHeader}.${encodedClaim}`;

  // Import private key for signing
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = serviceAccount.private_key
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  );

  const encodedSignature = encodeBase64Url(
    String.fromCharCode(...new Uint8Array(signature))
  );

  const jwt = `${signatureInput}.${encodedSignature}`;

  // Request OAuth2 access token
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`Failed to obtain OAuth2 token: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

Deno.serve(async (req) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("OK", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

    if (!serviceAccountJson) {
      console.warn("⚠️ FIREBASE_SERVICE_ACCOUNT_JSON secret not set. Skipping FCM push.");
      return new Response(
        JSON.stringify({ success: false, message: "Firebase credentials not configured" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const serviceAccount: ServiceAccountKey = JSON.parse(serviceAccountJson);
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: WebhookPayload = await req.json();
    const { record } = payload;

    if (!record || !record.caregiver_id) {
      return new Response(
        JSON.stringify({ error: "Invalid webhook payload: missing record.caregiver_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch active push tokens for this caregiver
    const { data: tokens, error: tokensError } = await supabase
      .from("caregiver_push_tokens")
      .select("fcm_token")
      .eq("caregiver_id", record.caregiver_id)
      .eq("is_active", true);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, delivered: 0, message: "No active push tokens found" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Fetch Patient Name for enriched notification display
    let patientName = "Elder";
    if (record.patient_id) {
      const { data: patient } = await supabase
        .from("patients")
        .select("display_name, preferred_name")
        .eq("id", record.patient_id)
        .single();
      if (patient) {
        patientName = patient.preferred_name || patient.display_name || "Elder";
      }
    }

    // 3. Obtain OAuth2 Token for Firebase Cloud Messaging HTTP v1 API
    const accessToken = await getAccessToken(serviceAccount);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    let successCount = 0;
    let failureCount = 0;

    // 4. Dispatch notification to all active devices
    for (const tokenRow of tokens) {
      const fcmMessage = {
        message: {
          token: tokenRow.fcm_token,
          notification: {
            title: record.title || `Alert from ${patientName}`,
            body: record.message,
          },
          data: {
            notification_id: record.id ?? "",
            caregiver_id: record.caregiver_id ?? "",
            patient_id: record.patient_id ?? "",
            notification_type: record.notification_type ?? "",
            related_reminder_id: record.related_reminder_id ?? "",
            related_game_session_id: record.related_game_session_id ?? "",
            patient_name: patientName,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channel_id: "nirvana_caregiver_alerts",
              icon: "ic_launcher",
              sound: "default",
              default_vibrate_timings: true,
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        },
      };

      const fcmRes = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmMessage),
      });

      if (fcmRes.ok) {
        successCount++;
      } else {
        failureCount++;
        const errorText = await fcmRes.text();
        console.error(`FCM send failure for token ${tokenRow.fcm_token.slice(0, 10)}...:`, errorText);

        // If token is invalid / unregistered, mark inactive in Supabase
        if (errorText.includes("UNREGISTERED") || errorText.includes("INVALID_ARGUMENT")) {
          await supabase
            .from("caregiver_push_tokens")
            .update({ is_active: false })
            .eq("fcm_token", tokenRow.fcm_token);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failureCount,
        total_tokens: tokens.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Error in push-caregiver-notification function:", err);
    return new Response(
      JSON.stringify({ success: false, error: err.message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
