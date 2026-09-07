# NIRVANA - Cognitive Engagement Games Specification

## 1. Game Philosophy & Ethical Guardrails

### 1.1 Core Principles
In NIRVANA, games are **gentle cognitive engagement activities**, designed to bring daily joy, evoke familiar memories, spark recognition, and offer positive reinforcement. They are **never diagnostic tests** and must never evoke frustration, anxiety, or feelings of inadequacy.

### 1.2 Strict Phrasing & Terminology Matrix

| Category | 🚫 STRICTLY FORBIDDEN | ✅ MANDATORY APPROVED PHRASING |
|---|---|---|
| **Activity Framing** | "Memory Test", "Cognitive Assessment", "Brain Exam" | "Today's Fun Activity", "Daily Exercise", "Let's Play" |
| **Outcomes** | "Score: 40% (Poor)", "Failed", "Brain Score" | "Wonderful Effort!", "Nice work!", "Activity Completed" |
| **Incorrect Choice** | "Wrong!", "Incorrect", "Error", "Memory Loss Detected" | "Let's try another one!", "Take your time", "Good try!" |
| **Difficulty Change** | "Downgrading due to poor performance" | "Let's try a calmer pace" |
| **Metrics in Dashboard**| "Cognitive Health Index", "Dementia Progression" | "Daily Participation Consistency", "Engaged Minutes" |

---

## 2. Detailed Game Mechanics

### Game 1: Remember Objects (Visual Recognition & Recall)

#### Objective
Display a small set of familiar, high-contrast everyday objects (e.g., Cup, Key, Apple, Book, Glasses), hide them after a comfortable observation window, and ask the user to tap which items they saw from a selection.

```
┌────────────────────────────────────────────────────────┐
│  [Step 1: Memorization]                                │
│                                                        │
│  "Take a look at these items:"                         │
│                                                        │
│       ┌─────────┐      ┌─────────┐      ┌─────────┐    │
│       │  🍎     │      │  🔑     │      │  ☕     │    │
│       │  Apple  │      │  Key    │      │  Cup    │    │
│       └─────────┘      └─────────┘      └─────────┘    │
│                                                        │
│        [ Ready / Next (Large button) ]                 │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  [Step 2: Recall & Selection]                          │
│                                                        │
│  "Which items did you see?" (Select 3)                 │
│                                                        │
│   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐       │
│   │ 🍎     │  │ 🕶️     │  │ ☕     │  │ 🔑     │       │
│   │ Apple  │  │ Glasses│  │ Cup    │  │ Key    │       │
│   └────────┘  └────────┘  └────────┘  └────────┘       │
│                                                        │
│   [Audio Prompt: "Tap the items you remember seeing"]   │
└────────────────────────────────────────────────────────┘
```

#### Accessibility & Engagement Design
- **No Harsh Timer**: The user can observe for as long as they want or tap "Ready" when comfortable.
- **Visual Cueing**: Large icons with clear descriptive subtitles below each icon.
- **Adaptive Sizing**:
  - *Level 1*: 2 items to remember out of 4 options.
  - *Level 2*: 3 items to remember out of 6 options.
  - *Level 3*: 4 items to remember out of 6 options.

---

### Game 2: Who Is This? (Familiar Face & Family Recall)

#### Objective
Display uploaded family or caregiver photos with gentle relationship prompts, encouraging recognition of loved ones, family members, and cherished pets.

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│          ┌──────────────────────────────────┐          │
│          │                                  │          │
│          │       [ Family Photo ]           │          │
│          │       (e.g., Granddaughter)      │          │
│          │                                  │          │
│          └──────────────────────────────────┘          │
│                                                        │
│        🔊 [ "Listen to Voice Note: 'Hi Grandpa!' " ]    │
│                                                        │
│          "Who is smiling in this picture?"             │
│                                                        │
│     ┌─────────────────────┐   ┌─────────────────────┐  │
│     │   Emily (Grand-     │   │   Sarah (Daughter)  │  │
│     │   daughter)         │   │                     │  │
│     └─────────────────────┘   └─────────────────────┘  │
│                                                        │
│     ┌─────────────────────┐   ┌─────────────────────┐  │
│     │   Dr. Robert        │   │   [ Hint / Reveal ] │  │
│     │                     │   │                     │  │
│     └─────────────────────┘   └─────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

#### Accessibility & Engagement Design
- **Privacy First**: Family photos are stored locally on device and synced only to private caregiver Supabase Storage bucket with RLS. No external facial recognition or third-party AI inspection is performed.
- **Multi-sensory cues**: Optional voice recording clip ("Hi Grandpa, it's Emily!") attached to the card.
- **Graceful Hint Option**: "Hint / Reveal" button is always present so the user can immediately see the answer without feeling stuck.

---

### Game 3: Grocery Memory (Sequencing & Everyday Routine)

#### Objective
Present a simple, realistic shopping list of 2–4 pantry/grocery items, then simulate picking those items off the grocery shelf. Evokes familiar everyday domestic routines.

```
┌────────────────────────────────────────────────────────┐
│  [Shopping List]                                       │
│                                                        │
│  "Let's get our groceries for today:"                  │
│                                                        │
│    🛒  1. Bread 🍞                                     │
│    🛒  2. Milk 🥛                                      │
│    🛒  3. Bananas 🍌                                   │
│                                                        │
│  [ Let's Go to the Shop ➔ ]                            │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│  [Supermarket Shelf]                                   │
│                                                        │
│  "Tap the items from your list into the cart:"         │
│                                                        │
│   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐       │
│   │  🍞    │  │  🥦    │  │  🥛    │  │  🧀    │       │
│   │ Bread  │  │Broccoli│  │  Milk  │  │ Cheese │       │
│   └────────┘  └────────┘  └────────┘  └────────┘       │
│                                                        │
│   Items in Basket: [ 🍞 Bread ] [ 🥛 Milk ]            │
└────────────────────────────────────────────────────────┘
```

#### Accessibility & Engagement Design
- **Step-by-step guidance**: Text-to-speech or soothing human audio prompts explain each step.
- **Instant feedback**: Selected items bounce gently into the basket with an uplifting chime.
- **Adaptive Level**:
  - *Level 1*: 2 items.
  - *Level 2*: 3 items.
  - *Level 3*: 4 items.

---

## 3. Session Data Model & Non-Clinical Metrics

```dart
class GameSession {
  final String id;
  final String patientId;
  final GameType gameType; // rememberObjects, whoIsThis, groceryMemory
  final int difficultyLevel;
  final int totalTrials;
  final int successfulTrials;
  final int durationSeconds;
  final Map<String, dynamic> activityMetadata; // e.g. hints_used, items_chosen
  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime createdAt;
}
```

### Dashboard Translation
In the Caregiver Dashboard, session statistics are presented strictly as:
- **Participation Streak**: "Active 5 of the last 7 days"
- **Session Duration**: "Spent 12 minutes enjoying activities today"
- **Preferred Activity**: "Most enjoyed game: 'Who Is This?'"
