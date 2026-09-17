# 🚀 TRY NIRVANA — Live Demo
> **▶️ [LAUNCH LIVE DEMO](https://abhinav-s-biju.github.io/S_I_H/)** ← open this in your browser. No install, no signup.
>
> **📱 [DOWNLOAD APK](https://github.com/AbhiNav-S-Biju/S_I_H/releases/latest)** ← Android phone / emulator.
>
> **🎬 [WATCH DEMO VIDEO](docs/DEMO_VIDEO.md)** ← backup walkthrough if the demo links are blocked.

---

## 🧘 NIRVANA
**An offline-first companionship & care-coordination app for elders — with a live portal for the family caregiver.**

Built with Flutter for the **Smart India Hackathon**. NIRVANA runs 100% offline for the elder (reminders, games, preferences all work with the network unplugged) and syncs to the cloud the moment a connection returns.

### Why it matters
An elder with mild cognitive change should never have to fight an app. NIRVANA is built around three rules:

1. **Non-clinical by design.** It never diagnoses, never scores, never says *"failed"*. Feedback is *"Wonderful Effort!"*, never *"30% — Poor"*.
2. **No pressure, no timers.** Large 64dp+ touch targets, 18sp+ minimum text, WCAG AAA contrast, and unlimited time on every activity.
3. **The family stays informed.** A caregiver logs into a separate dashboard and sees participation trends and reminder acknowledgements — not clinical judgements.

---

## ✨ What's inside
| Feature | What it does |
|---|---|
| 🔔 **Offline Exact Reminders** | Medication / hydration / meal alarms scheduled natively on-device. Fire accurately even in Android Doze mode. Interactive **Done · Snooze 15 min · Later today** buttons work straight from the notification. |
| 🧩 **3 Cognitive Engagement Games** | *Remember Objects*, *Who Is This?* (cherished family photos), and *Grocery Memory* — each with non-penalizing hints. |
| 🆘 **"I'm Lost / I Need Help"** | One-tap live location sharing to the caregiver with a map view. |
| 👨‍👩‍👧 **Caregiver Dashboard** | Patient switcher, 7-day participation chart, reminder compliance, and sync health. |
| 🗣️ **Voice-Assisted Interaction** | Text-to-speech and speech-to-text for elders who prefer talking over tapping. |
| 🌍 **Multi-lingual** | English, हिन्दी, বাংলা, ଓଡ଼ିଆ, অসমীয়া, and more. |
| 📴 **Offline-First Sync Engine** | Hive is the single source of truth. Every mutation queues as an idempotent UUID event and replays with exponential backoff when the network returns. |

---

## 🏗️ Architecture at a glance
Clean Architecture + feature-driven modules + unidirectional flow via **Riverpod 2.x**.

```
lib/
├── app/          # Bootstrap, GoRouter, elder theme & accessibility design system
├── core/         # Sync engine, connectivity monitor, Supabase contracts
├── database/     # Hive boxes, binary type adapters, sync queue models
├── features/     # caregiver · games · home · reminders · settings · location_help
├── l10n/         # ARB localisation (EN / HI / BN / AS / OR)
└── main.dart     # Entry point — Hive → notifications → Supabase → runApp
```

**The sync guarantee:** every mutation is written to Hive synchronously (0 ms UI wait), then queued as a `HiveSyncEvent` with a UUID v4 `eventId`. The backend RPC `process_sync_event` treats a replayed `eventId` as `IGNORED_DUPLICATE`, so a flaky network can never double-apply data. After 8 consecutive failures an event is parked as `deadLetter` rather than poisoning the queue.

**Stack:** Flutter 3.32 · Riverpod · GoRouter · Hive (local) · Supabase Postgres + RLS (cloud) · flutter_local_notifications · flutter_map · Firebase Cloud Messaging.

Deep dives live in [`project_detailed_explanation.md`](project_detailed_explanation.md), [`architecture.md`](architecture.md), and [`database.md`](database.md).

---

## ▶️ Run the demo
### Option 1 — Live Web Demo *(fastest, works on any device)*

**👉 [abhinav-s-biju.github.io/S_I_H](https://abhinav-s-biju.github.io/S_I_H/)**

Runs the real Flutter app compiled to WebAssembly — no install. Best experienced in a desktop Chrome/Edge window.

> Because this is a browser sandbox, Android-only capabilities (native exact alarms, FCM push, live GPS) are naturally unavailable there. Everything else — onboarding, the games, the caregiver portal, settings, and localisation — is fully interactive. **Use the APK for the complete experience.**

### Option 2 — Android APK *(full native experience)*

**👉 [Download APK](https://github.com/AbhiNav-S-Biju/S_I_H/releases/latest)** — grab the `nirvana-release.apk` asset.

1. Download the `.apk` on an Android device (Android 7.0 / API 24 or newer).
2. Tap it and allow *"Install from unknown sources"* when prompted.
3. Open **NIRVANA** and complete the short onboarding.

*Note: this is a hackathon prototype build, signed with a debug key — Play Protect may show a warning. That's expected; choose "Install anyway".*

### Option 3 — Build & run from source
```bash
flutter pub get
flutter run                 # connected device / emulator
flutter run -d chrome       # web
flutter build apk --release # produces build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Suggested judge flow (≈4 minutes)

1. **📊 Read the PPT** — the problem statement and the pitch.
2. **🐙 Open this GitHub repo** — you're here.
3. **📖 Read this README** — the feature and architecture summary above.
4. **▶️ Launch the [Live Demo](https://abhinav-s-biju.github.io/S_I_H/)** — try a game and the caregiver portal.
5. **📱 If the browser build is limited, install the [APK](https://github.com/AbhiNav-S-Biju/S_I_H/releases/latest)** — see the offline reminders and live location sharing for real.
6. **🎬 Fallback: the [demo video](https://github.com/AbhiNav-S-Biju/S_I_H/releases/latest)** — a 2-minute recorded walkthrough if nothing else is reachable.

**Put it on airplane mode during the demo.** The elder app keeps working. That is the whole point.

---

## ⚖️ Ethical commitments
- ❌ No diagnosis, no disease staging, no "brain age", no clinical scoring.
- ❌ No facial recognition, no camera scanning, no biometric identifiers.
- ❌ No Protected Health Information sent to third-party LLMs or ad networks.
- ✅ All engagement language is supportive and positive by policy.
- ✅ The elder experience is fully autonomous and offline.

---

## 👥 Team
Built for the **Smart India Hackathon** by team **Memento**.

---

<p align="center"><em>NIRVANA — calm technology for the people who raised us. 🧘</em></p>
