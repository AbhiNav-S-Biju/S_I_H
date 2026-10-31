# Brag Plan: NIRVANA

## What is this app?
NIRVANA is a Flutter app for elders with memory difficulties — short cognitive
games, offline reminders, familiar family photos, and a calm "Ask NIRVANA"
companion — that syncs quietly to a separate caregiver dashboard so a family
member can see participation and reminder activity. It is a hackathon prototype,
not a medical device.

## The angle
Every dementia app sells anxiety. NIRVANA sells calm. The premise: **an elder
should never have to fight an app.** So the video is a quiet product film about a
warm, clay-soft interface that never says "failed", never runs a timer, and keeps
working with the network unplugged — and then, without changing tone, reveals the
caregiver dashboard on the other side. The story arc is: *elder uses it →
engagement & routine → local-first sync → caregiver visibility → human
connection.* Verbatim, non-clinical, warm. No medical claims anywhere.

The most impressive claim is also the most human one: **"It never says 'failed'.
Feedback is 'Wonderful Effort!'"** and **"Put it on airplane mode during the demo.
The elder app keeps working. That is the whole point."**

## Hook (first 2-3 seconds)
Open on the elder home screen's own greeting — "Good morning, / Friend" in warm
clay on a peach-sand canvas — while the line **"It never says 'failed'."** lands.
The claim is the hook. A viewer who has cared for someone with memory loss knows
exactly why that matters, and stays.

## Key moments (the middle)
- **"Wonderful Effort!"** feedback card — the single most on-brand line in the
  whole product. Show it landing after a Grocery Memory round.
- **The game shelf appearing one by one** — round Srp: Remember Objects, Who Is
  This?, Grocery Memory, Jigsaw — each a clay tile with its own pastel color,
  using the app's real tile design (lavender / sky / peach / buttercup tags).
- **An offline reminder with Done · Snooze 15 min · Later today** — "Medicines,
  8:00 AM" firing on-device, and the three real action buttons.
- **The North-East scenes** — the Jigsaw level grid showing Kaziranga One-Horned
  Rhino and Tawang Himalayan Monastery: real asset imagery, the cultural
  contextualization made visible rather than described.
- **"I'm Lost / I Need Help" → caregiver sees the map pin** — one tap, live
  location to the caregiver. Safety, not emergency.
- **The caregiver dashboard** — 7-day participation, reminder compliance, sync
  health. Non-clinical participation, clearly labeled.

## Outro / punchline
End on the README's own line, kept verbatim in spirit:
**"NIRVANA — calm technology for the people who raised us."**
Product name lands, music resolves to a single soft bell over the fade.

## User flow worth showing
Entry → key action → result, shown as the centerpiece:
1. **Entry** — elder home screen: greeting, "What would you like to do?", the
   clay action tiles.
2. **Key action** — tap *Memory Games* → Grocery Memory round → a wrong pick
   answered with "Wonderful Effort!" (the non-punishing loop, shown, not told).
3. **Result** — activity is written locally, syncs, and the caregiver dashboard
   shows the participation/reminder activity. The loop closes on a map pin when
   the elder taps "I'm Lost / I Need Help".

## Tone
- Preset: `polished`
- Creative direction: "quiet premium product film for a healthcare-adjacent tool
  — warm, unhurried, human; the confidence is in what it refuses to do."
- Interpretation: fewer scenes, longer holds, soft crossfades and gentle slides.
  Writing is plain and warm, never hypey. Visual energy is low-amplitude: clay
  surfaces settle in, text rises and holds. Restraint is the design; no flashes,
  no hard cuts, no aggressive sound. The emotional register never breaks when we
  switch from the elder to the caregiver — same app, two doors.

## Format: vertical — 1080x1920
## Duration: 40 seconds
(Reels / Shorts / TikTok-native, which is how hackathon demos actually travel.)

### Build-2 revision (this run)
The user asked for three changes, all applied here:
1. **Use the app's own background.** Every scene now carries the real
   `_ClayBackground` from `home_screen.dart`: the warm sand canvas `#F3EFE6`,
   a lavender clay circle + half-dome bottom-right, a buttercup pill, a 3-puff
   clay cloud top-left, and scattered sage/peach/sky/buttercup clay bubbles.
   Ambient motion is a slow drift; readability is never sacrificed.
2. **Snapshots as accurate to the app as possible.** Screens are rebuilt from
   the real widget source, not invented: the elder home tiles (real tags/colors),
   the Daily Activities game shelf (real titles, subtitles, emojis and 96px
   image plates), the reminder card (real Done · Snooze 15 min · Later today),
   the caregiver dashboard (real "Games completed / Reminder completion /
   Activities completed" metric cards, "7-Day Activity View", "Recent Alerts &
   Activities", "Sync status"), and the real grocery/puzzle assets.
3. **Extended to ~40s.** More scenes and longer holds, same narrative order.

## Visual identity (from the project)
- Background: `#F3EFE6` (clay canvas, from `home_screen.dart`) / `#F3ECE2`
  (scaffold peachy sand, `ElderColors.background`)
- Surface: `#F4ECDD` / `#FDFAF6` (raised clay card, cream — never white)
- Text: `#3A2F2A` primary ink (warm dark brown — never black); `#8A7D68` soft ink
- Accents (clay family): lavender `#9B8EC4`, buttercup `#C8A96E`, sage `#7BA89A`,
  peach `#D4897A`; deep variants `#6B5EA8`, `#8B6E3C`, `#3D6B5E`, `#A85A4A`
- Display font: Nunito (rounded, warm, high-legibility) — `google_fonts` is in
  `pubspec.yaml`; fall back to system rounded sans if unavailable
- Body font: Nunito
- Strongest visual element: the two-shadow "raised clay" surface (warm-white
  highlight top-left, warm-brown ambient bottom-right) — never a flat Material
  card. Reproduce that dual-shadow treatment on every panel in the video.

## Share copy (draft)
NIRVANA is a memory-support companion for elders — cognitive games, offline
reminders, and an "Ask NIRVANA" chat, with a separate dashboard so a caregiver
can see participation and reminder activity. It never says "failed".

## Audio direction
- Role: warm bed with sparse professional accents — supportive, never clinical
- Music: `happy-beats-business-moves-vol-12-by-ende-dot-app.mp3` (steady, clean,
  1:58, 109.96 BPM) — the calmest bundled track, best fit for `polished`
- Music treatment: fade in 0→0.6s, sit under everything at ~0.30, gentle fade out
  across the final logo; let the outro bell ring over the tail
- Music cue guidance: bundled preset available —
  `.agents/skills/brag/assets/music/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.md`
  (tempo 109.96 BPM, 117.4s — comfortably covers a 40s cut).
  Strong-cue targets for major moments (within ±0.15s): **22.93s** (caregiver
  dashboard reveal), **28.0s**-area cue (map / "I'm Lost"), **36.0s**-area cue
  (name lock). Beat grid (~0.55s spacing) for sequential rows — reveal each text
  row on alternating beats (~1.1s) so labels stay readable; never one text row
  per beat at this tempo.
- Audio-reactive treatment: subtle — use music RMS to let the clay cards and the
  hero glow breathe very slightly. No waveform/equalizer visuals, no strobing.
- SFX posture: sparse — roughly 5-6 cues total, motion-matched, soft; prefer low
  high-frequency-risk files (`interface/drop_*`, `interface/click_*`,
  `impactSoft_medium_*`, `casino/chip-lay-*`, `impactGlass_light_*`)
- Audio-coupled moments: tile-reveal clicks; a soft-tap for the simulated
  game pick; a gentle positive chime for "Wonderful Effort!"; a single soft
  announcement cue when the caregiver map pin drops; a bell under the final name
- Restraint rule: no punchy impacts, no glitch/error sounds, no dense stacking.
  The subject is an elder with memory loss — audio must never feel like a
  startup ad or a game show.

## Storyboard (40s)
Total: 40.0s across 9 scenes. Every scene sits on the app's real clay canvas
background (see "Build-2 revision").

### Scene 1 — Hook: the greeting — 4.5s
Real clay canvas + ambient shapes. The app's own greeting card ("Good morning, /
Friend" with the heart disc) settles, and **"It never says 'failed'."** lands
large and holds, fully readable.
Sequential/interaction: none (one hold, one line)
Audio intent: calm, warm, immediately human — set the emotional floor
Audio-coupled idea: soft `interface/drop_001` as the card settles
Music: bed fades in during this scene; faint RMS makes the card breathe
Transition mood: soft crossfade → Scene 2
### Scene 2 — The elder home — 5.0s
Faithful rebuild of the real home screen: the greeting row with the heart disc and
speaker button, the "What would you like to do?" section title, then the five
clay action tiles arriving one by one — **Memory Games** (lavender / DAILY),
**My Reminders** (sky / ROUTINES), **Family Photos** (peach / MEMORIES),
**Ask NIRVANA** (lavender / TALK), **Settings** (buttercup / PREFERENCES) —
using the app's exact tags and colors. A simulated tap presses the Memory Games
tile.
Sequential/interaction: yes — tiles arrive one by one; then a simulated tap
Audio intent: the app feeling effortless and familiar, not busy
Audio-coupled idea: one soft `ui/click` per tile landing; softer click for the tap
Music: bed steady
Transition mood: soft push → Scene 3
### Scene 3 — Daily Activities (the games hub) — 5.0s
Rebuild the real games hub: **"Daily Activities"** title, the "Welcome to Today's
Fun!" banner, and the four game cards with the app's real emojis and 96px image
plates — 🍎 **Remember Objects** ("Find items on the shelf"), 👵 **Who Is This?**
("Recognize family faces"), 🛒 **Grocery Memory** ("Remember the shopping list"),
🧩 **Jigsaw** ("Complete the picture"). Cards arrive one by one; a simulated tap
opens Jigsaw.
Sequential/interaction: yes — 4 game cards, one by one
Audio intent: a warm shelf of activities, not a test menu
Audio-coupled idea: soft card sounds per arrival
Music: bed steady
Transition mood: soft push → Scene 4
### Scene 4 — Grocery Memory, mid-round — 5.0s
A real round: the "Find these on the shelf:" list (Rice · Tea · Milk with real
grocery art) over a 6-item shelf from the app's `assets/images/groceries`. A
simulated tap lands on the wrong item; instead of a red error, the card resolves
into the gentle positive feedback — **"Wonderful Effort!"** with the app's
non-punishing sub-line "No timers. No 'wrong'." — which holds and is readable.
Sequential/interaction: yes — list, then shelf, then the wrong pick, then feedback
Audio intent: reassuring — nothing scolds the user
Audio-coupled idea: soft tap; gentle positive chime as "Wonderful Effort!" lands
Music: bed steady
Transition mood: clean crossfade → Scene 5
### Scene 5 — Pictures from home (jigsaw) — 4.5s
Rebuild the Jigsaw level grid using the app's real puzzle art: **Kaziranga
One-Horned Rhino**, **Tawang Himalayan Monastery**, **Seven Sisters Heritage**,
**Cherrapunji Waterfalls** — familiar North-East scenes presented as pictures to
piece together, not abstract drills. Cards slide in one by one.
Sequential/interaction: yes — level cards slide in one by one
Audio intent: familiarity and place — this is the cultural contextualization made visible
Audio-coupled idea: light `casino/card-slide-*` per card
Music: bed steady
Transition mood: soft crossfade → Scene 6
### Scene 6 — Reminders — 4.5s
Faithful reminder card: **Medicines · 8:00 AM**, an **OFFLINE** chip, and the three
real actions **Done · Snooze 15 min · Later today** as clay buttons; the caption
"Scheduled on-device — accurate even when the phone is asleep."
Sequential/interaction: yes — card settles; the three buttons arrive
Audio intent: structure and safety without pressure
Audio-coupled idea: `interface/drop_002` for the card; quiet clicks for buttons
Music: bed steady
Transition mood: soft crossfade → Scene 7
### Scene 7 — Family & familiarity — 4.5s
Rebuild the "Who Is This?" family-photo experience: a **Granddaughter** card with
the app's own relationship hint copy, plus a small "Family Photos" album strip —
reinforcing that the content is the elder's own family, not generic material.
Sequential/interaction: yes — card slides in, album strip follows
Audio intent: warmth — the emotional centre of the product
Audio-coupled idea: `casino/card-slide-*` for the card; soft drop for the strip
Music: bed steady
Transition mood: soft crossfade → Scene 8
### Scene 8 — Local-first → caregiver — 5.5s
The technical heart. Four pipeline cards light up in sequence: **Hive — local,
on-device** → **Sync queue — idempotent events** → **Supabase — PostgreSQL + RLS**
→ **Caregiver dashboard**. Then the real caregiver dashboard assembles: the three
metric cards (**Games completed · Reminder completion · Activities completed**),
the **7-Day Activity View** bar chart, and a **Sync status** chip, labeled
"Participation, not a clinical assessment." Finally the map panel drops a single
location pin beside **"I'm Lost / I Need Help"** — the one-tap path from a
confused elder to a caregiver who can see where they are.
Sequential/interaction: yes — pipeline cards; then metric cards; then chart; then pin
Audio intent: quiet competence — engineered, and calm about it
Audio-coupled idea: soft tick per pipeline card; quiet announcement cue as the pin settles
Music: bed steady; **beat-lock the caregiver reveal near 22.93s**
Transition mood: soft crossfade → Scene 9
### Scene 9 — Outro / name lock — 2.5s
Clears to the real clay canvas with ambient shapes. **NIRVANA** lands large in the
app's warm dark-brown ink, with **"Calm technology for the people who raised us."**
beneath it. Music fades; a single quiet bell rings under the lock.
Sequential/interaction: none
Audio intent: land, resolve, exhale
Audio-coupled idea: `interface/bong_001` under the name; **beat-lock the name near the 36s cue**
Music: fade out across the lock
Transition mood: none (end)

**Scene durations:** 4.5 + 5.0 + 5.0 + 5.0 + 4.5 + 4.5 + 4.5 + 5.5 + 2.5 = 41.0 →
trim Scene 8 to 4.5s → **40.0s total**.

**Music mood for this video:** warm, steady, unobtrusive bed — closer to a
wellness brand than a startup
**Audio summary:** a warm bed that never rises to a climax, a handful of soft
motion-matched accents, one gentle chime for "Wonderful Effort!", one quiet bell
for the name — supportive audio for a supportive product.

## Disclaimer
The on-screen copy and any captions must respect the product's own framing. Where
a claim could read as medical, keep it non-clinical. Safe, verbatim-safe lines the
video may use: "It never says 'failed'.", "Wonderful Effort!", "participation, not
a clinical assessment", "works offline". Do **not** put the full disclaimer
sentence on screen (no room in 21s and it would read as legal boilerplate); keep
it in the share copy / description instead:
"This prototype supports games and reminders. It does not diagnose or treat
dementia."
