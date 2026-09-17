# `send-passcode-sms` Edge Function

Delivers a patient's **currently-generated** pairing passcode to that patient's
registered phone number via SMS.

```
Flutter caregiver UI
  -> authenticated Supabase request (caregiver JWT + RLS-checked RPC)
  -> this Edge Function (verifies caregiver -> patient relationship, server-side)
  -> SMS provider HTTP API
  -> patient's phone
```

## Why an Edge Function

SMS provider credentials must never ship inside the Flutter app, the APK, or
Git. They live **only** in Supabase Edge Function secrets. The client sends an
authenticated request and never sees a provider key.

## Security properties

- The caller is identified from their JWT (`auth.getUser()`), never from a
  client-supplied id.
- The caregiver → patient link is re-verified server-side through the
  `caregiver_owns_patient` RPC before anything is sent.
- The destination number is read **server-side** from `patients`, so a caregiver
  cannot target an arbitrary phone number.
- The passcode is validated against `patient_pairing_codes` — only the current,
  unused, unexpired code is ever delivered. A stale/superseded code is rejected
  with `STALE_CODE`.
- One SMS per generated passcode (`ALREADY_SENT` thereafter), so accidental
  duplicate sends are blocked.
- Passcodes and full phone numbers are never logged. Only a masked `****1234`
  suffix and the provider message id are returned/reported.

## Required Supabase secrets

Set these with `supabase secrets set ...` (or the dashboard → Project Settings →
Edge Functions → Secrets). **Do not put these in Dart, Git, or the APK.**

| Secret | Required | Purpose |
| --- | --- | --- |
| `SMS_PROVIDER` | no (defaults to `twilio`) | `twilio` or `generic` |
| `SMS_DEFAULT_COUNTRY_CODE` | recommended | e.g. `91`; applied when a stored number lacks a leading `+` |
| `TWILIO_ACCOUNT_SID` | when provider = twilio | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | when provider = twilio | Twilio auth token |
| `TWILIO_FROM_NUMBER` | when provider = twilio | Twilio sender number / sender ID |
| `SMS_API_URL` | when provider = generic | Full JSON gateway endpoint |
| `SMS_API_KEY` | when provider = generic | Bearer key for the gateway |
| `SMS_SENDER_ID` | optional | Sender id included in the generic JSON body |

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
automatically by the Supabase Edge Runtime.

## Deploying

```bash
# 1. Apply the migration (adds the RPCs + the SMS log table)
supabase db push

# 2. Configure the provider secrets
supabase secrets set SMS_PROVIDER=twilio \
  TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_FROM_NUMBER=+1... \
  SMS_DEFAULT_COUNTRY_CODE=91

# 3. Deploy the function
supabase functions deploy send-passcode-sms
```

## Verifying

```bash
supabase functions invoke send-passcode-sms --body '{"patient_id":"<uuid>","code":"123456"}'
```

The function is only considered working once the secrets above are set and a
real SMS is received on the patient's device. Until then the app surfaces a
clear `PROVIDER_NOT_CONFIGURED` message and no delivery is claimed.
