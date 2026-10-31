# Hyperframes Composition Brief: NIRVANA

## Objective
Create a short launch-style brag video for NIRVANA — an elderly-first, offline-
first memory-support and cognitive-engagement companion app for Flutter, with a
separate caregiver dashboard. Tone is a quiet premium product film: warm, calm,
non-clinical, technically credible. Vertical, 21 seconds.

## Output
- Composition directory: `brag-output-2026-07-14-120000/composition/`
- Rendered video: `brag-output-2026-07-14-120000/brag.mp4`
- Format: vertical — 1080x1920
- Duration: 21 seconds (scenes: 3.0, 3.2, 4.2, 4.0, 5.1, 1.5)

## Source Material
- Project root: `c:\Users\Abhinav\SIH\S_I_H` (Flutter app, `pubspec.yaml` name: nirvana)
- Primary files read:
  - `README.md` — positioning, offline-first claim, ethical commitments
  - `project_detailed_explanation.md` — architecture, accessibility mandates
  - `lib/app/theme/elder_theme.dart` — the full claymorphic palette + dual shadow
  - `lib/app/theme/elder_typography.dart` — 22sp+ accessibility type scale
  - `lib/features/home/presentation/home_screen.dart` — real home UI, greeting,
    "What would you like to do?", the 5 action tiles and their tags/colors
  - `lib/features/games/models/game_level.dart` + `puzzle_item.dart` — jigsaw
    North-East levels (Kaziranga, Tawang, Seven Sisters, Cherrapunji)
  - `lib/features/ask_nirvana/providers/ask_nirvana_provider.dart` — the gentle
    first-person greeting, multi-language
  - `lib/l10n/app_en.arb` — verbatim UI strings
- Product name: NIRVANA
- Tagline / strongest claim:
  - "It never says 'failed'. Feedback is 'Wonderful Effort!'"
  - "NIRVANA — calm technology for the people who raised us."
  - "An elder with mild cognitive change should never have to fight an app."
- Key UI moments to recreate (must reference the real design, not invent one):
  1. Elder home: greeting card + "What would you like to do?" + 5 clay action
     tiles using the app's exact tags/colors — Memory Games (lavender/DAILY),
     My Reminders (sky/ROUTINES), Family Photos (peach/MEMORIES),
     Settings (buttercup/PREFERENCES), Ask NIRVANA (lavender/TALK)
  2. "Wonderful Effort!" supportive feedback card
  3. Reminder card: "Medicines" 8:00 AM with Done · Snooze 15 min · Later today
  4. Jigsaw level grid with real North-East scenes
  5. Caregiver dashboard (participation chart, reminder rows, sync health)
  6. "I'm Lost / I Need Help" → caregiver map pin
- Copy that must appear verbatim:
  - "It never says 'failed'."
  - "What would you like to do?"
  - "Memory Games" · "My Reminders" · "Family Photos" · "Ask NIRVANA"
  - "Wonderful Effort!"
  - "Medicines" · "Done" · "Snooze 15 min" · "Later today"
  - "Kaziranga One-Horned Rhino" · "Tawang Himalayan Monastery"
  - "I'm Lost / I Need Help"
  - "participation, not a clinical assessment"
  - "NIRVANA" · "Calm technology for the people who raised us."

## Creative Direction
- Tone preset: `polished`
- Creative direction: "quiet premium product film for a healthcare-adjacent tool
  — warm, unhurried, human; the confidence is in what it refuses to do."
- Interpretation: 6 scenes, longer holds, soft crossfades and gentle slides.
  Plain warm writing, no hype. Low-amplitude motion: clay surfaces settle, text
  rises and holds. Restraint is the design. No flashes, no hard cuts, no
  aggressive sound. The register does not change when we move from elder to
  caregiver — same app, two doors.
- Angle: every dementia app sells anxiety; NIRVANA sells calm. An elder should
  never have to fight an app — so the interface is clay-soft, never says
  "failed", never runs a timer, and keeps working offline — and the caregiver
  dashboard on the far side is visibility, not surveillance.
- Hook: the elder home greeting settles while "It never says 'failed'." lands.
- Outro: "NIRVANA — Calm technology for the people who raised us."
- Avoid:
  - Generic SaaS language ("streamline", "empower", "revolutionary", etc.)
  - Any medical / diagnostic / clinical-result claim. No statistics, no
    accuracy numbers, no testimonials, no deployment claims.
  - Flashy "AI dashboard" aesthetics. NIRVANA is calm claymorphism, not neon
    glassmorphism. Ask NIRVANA is a companion, not a medical advisor.
  - Face-recognition / surveillance framing. Do not depict scanning of people.
  - Abstract filler visuals that could belong to any product.

## Visual Identity
- Background: `#F3EFE6` clay canvas; `#F3ECE2` scaffold sand; sections `#EDE3D4`
- Surface: `#F4ECDD` raised clay card, `#FDFAF6` / `#FAF5EE` elevated
- Text: `#3A2F2A` primary warm dark-brown ink; `#8A7D68` soft ink; `#8C7F76` muted
- Accent clays: lavender `#9B8EC4` / deep `#6B5EA8` / bg `#F0EDFB`;
  buttercup `#C8A96E` / deep `#8B6E3C` / bg `#FBF3E2`;
  sage `#7BA89A` / deep `#3D6B5E` / bg `#EBF5F2`;
  peach `#D4897A` / deep `#A85A4A` / bg `#FBEFEC`; sky (use `#7BA8C4`-family
  light / bg `#EDF5F9` for the Reminders tile)
- Display font: Nunito (rounded, warm) — Google Fonts is a project dependency;
  fall back to a system rounded sans if the webfont can't be embedded
- Body font: Nunito
- Visual references from the project:
  - **The raised-clay surface**: a two-part shadow — a warm-white highlight
    top-left (`#FBF6EC`) and a warm-brown ambient shadow bottom-right
    (`#D6C9B2` / `#3A2F2A` @ ~0.10-0.16). Cards read as soft clay pressed from
    the canvas. This MUST be reproduced; never use a flat Material card.
  - Large radii: cards 24px, buttons 20px, icons 16px, pills fully rounded.
  - Letter tiles / icon discs with a subtle top-left gloss highlight.
  - Warm card shadow tint `#3A2F2A` @ 0.10, blur 20, offset (0,8).

## Storyboard
Use `brag-output-2026-07-14-120000/brag-plan.md` as the creative contract.

Scene summary:
1. **Hook — the greeting** — 3.0s — clay canvas + greeting card settling;
   must read: "It never says 'failed'."
2. **The elder home** — 3.2s — greeting + "What would you like to do?" + 5 clay
   action tiles arriving one by one; simulated tap on "Memory Games".
3. **Cognitive games** — 4.2s — Grocery Memory shelf round, a wrong pick answered
   with "Wonderful Effort!"; jigsaw level grid with Kaziranga / Tawang / Seven
   Sisters.
4. **Routine & familiarity** — 4.0s — reminder card "Medicines · 8:00 AM" with
   Done · Snooze 15 min · Later today + "works offline" chip; family photo /
   "Who Is This?" carousel.
5. **Local-first → caregiver** — 5.1s — pipeline cards (Hive → Sync queue →
   Supabase PostgreSQL → Caregiver dashboard); caregiver dashboard panels labeled
   "participation, not a clinical assessment"; "I'm Lost / I Need Help" map pin.
6. **Outro** — 1.5s — "NIRVANA" + "Calm technology for the people who raised us."

## Audio
- Audio role: warm bed with sparse professional accents — supportive, never clinical
- Audio arc: fades in warm, stays even (no big build), one gentle chime at
  "Wonderful Effort!", one quiet announcement cue at the map pin, resolves to a
  single soft bell under the final name, then out
- Music: `assets/music/happy-beats-business-moves-vol-12-by-ende-dot-app.mp3`
- Music treatment: fade in 0→0.6s; hold ~0.30 throughout; fade out across the
  final logo (~19.5→21.0s). Never above 0.5. Keep it under the SFX.
- Music cue guidance: bundled preset at
  `.agents/skills/brag/assets/music/cues/happy-beats-business-moves-vol-12-by-ende-dot-app.music-cues.md`
  (tempo 109.96 BPM). Templates live at `.agents/skills/brag/assets/music/cues/<track-stem>.music-cues.json`.
  Strong-cue locks (max 3, within ±0.15s): **8.74s** (Scene 3 jigsaw reveal),
  **17.47s** (Scene 5 caregiver dashboard / map reveal), **22.93s** (Scene 6 name
  lock — bonus, near the end). Beat grid (~0.55s spacing) for the tile row and
  pipeline cards: reveal each *text* label on alternating beats (~1.1s) so it stays
  readable; non-text accents may hit every beat.
- Audio-reactive treatment: subtle — use music RMS/bass to let the clay cards and
  the hero glow breathe very slightly. No waveform/equalizer visuals, no musical-
  note graphics, no strobing, no heavy pulsing. Extract via the Hyperframes
  audio-reactive helper; if extraction is unavailable, note it and skip (do not
  block the render).
- Audio-coupled moments:
  - Scene 1 greeting card settle — soft `interface/drop_001`
  - Scene 2 the 5 tiles — soft `ui/click*` per arrival; soft `ui/mouseclick1`
    for the simulated tap on Memory Games
  - Scene 3 wrong pick + feedback — soft tap, then gentle positive
    `impactGlass_light_001` (or `casino/chips-collide-1`) @ ~0.5 for
    "Wonderful Effort!"; light card sounds for the jigsaw level row
  - Scene 4 reminder + buttons + family card — `interface/drop_002`, quiet clicks,
    one `casino/card-slide-*`
  - Scene 5 pipeline → dashboard → map pin — one quiet announcement cue
    (`impactSoft_medium_003` or `interface/bong_001`) as the pin settles
  - Scene 6 name lock — `interface/bong_001` or `impactBell_heavy_004`, quiet
- SFX selection guidance: sparse, motion-matched, soft. Prefer low high-frequency
  risk files (check `sfx-analysis.md`). Nothing punchy, no glitch/error sounds,
  no dense stacking. Accent the first/last/strongest item, not every item.
- SFX analysis guidance: `.agents/skills/brag/assets/sfx/sfx-analysis.md` and
  `.json`
- Exact SFX choice: Hyperframes chooses filenames, timestamps, density, volume
  based on the implemented animation.
- Audio files: copy the chosen music and any SFX into
  `brag-output-2026-07-14-120000/composition/assets/`

## Hyperframes Instructions
Load the composition-building Hyperframes domain skills — `hyperframes-core`,
`hyperframes-animation`, `hyperframes-creative`, `hyperframes-keyframes`,
`hyperframes-cli`, and `hyperframes-accessibility` if present. /brag is its own
workflow: do not enter the `hyperframes` entry-point intent interview and do not
route into its generic promo / launch-video workflow. Prefer native Hyperframes
conventions over anything in /brag.

Requirements:
- Show real UI/copy from the project in at least Scenes 2, 3, 4, and 5. Do not
  invent a different design language — use the claymorphic palette and the
  dual-shadow raised surface from `elder_theme.dart`.
- Accessibility is a product feature here: keep body text large, warm-brown on
  light clay, high contrast (must pass `hyperframes check`, including WCAG), and
  never pull readable text off screen before it can be read.
- Keep all text readable in the final render. Beat-grid reveals of text must hold
  to the reading floor (~0.8s for short labels, ~0.3s/word for sentences).
- Keep the video within 15-25 seconds (target 21s).
- Include the planned music/SFX layer (music and SFX are enabled for this run).
- Treat /brag audio notes as guidance, not a fixed cue sheet. Choose SFX after the
  visual animation exists.
- Treat music cue metadata as optional timing hints; lock at most 3 strong cues.
- Use SFX to support motion and interaction; keep restraint (polished tone).
- Honor the music treatment: fade-in at the top, fade-out under the final name,
  final bell ringing over the tail.
- Consider the Hyperframes audio-reactive workflow when music is present and wire
  at least one existing visual element to RMS/bass. Skip gracefully if the
  extraction helper or ffmpeg is unavailable.
- Use local assets for audio and any runtime/media dependencies.
- Run `npx hyperframes check` before render — it is brag's single gate. Fix all
  errors, including WCAG contrast failures.
