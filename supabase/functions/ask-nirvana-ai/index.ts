// ============================================================================
// NIRVANA secure Gemini gateway.
// Gemini credentials remain Supabase secrets and never enter Flutter.
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

declare const Deno: {
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
  env: { get: (key: string) => string | undefined };
};

interface ToolResult {
  name: string;
  result: string;
}

interface RequestPayload {
  query: string;
  languageCode?: string;
  toolResults?: ToolResult[];
  conversation?: Array<{ role: "user" | "model"; text: string }>;
}

const HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
};

const NIRVANA_SYSTEM_PROMPT = `
You are NIRVANA, a calm, patient, elderly-friendly cognitive engagement and memory-assistance companion.

Use simple, short and natural language.
Be warm without being childish or patronizing.
Respond in the user's selected language.
Maintain conversational context.
Help with reminders, routines, family information, memories, games, stories, orientation and general questions.

NIRVANA personal data is authoritative.
Never invent reminders, appointments, family members, memories, activities or caregiver instructions.
If information is unavailable, clearly say that it is unavailable.

Never diagnose dementia.
Never provide medication dosage or medical treatment instructions.
For medical concerns, encourage contacting the caregiver or doctor as appropriate.

Prefer NIRVANA tools over guessing.
`;

const TOOL_DECLARATIONS = [
  tool("get_next_reminder", "Get the next authoritative reminder."),
  tool("get_today_reminders", "Get authoritative reminders scheduled today."),
  tool("get_daily_routine", "Get the authoritative daily routine."),
  {
    name: "get_family_members",
    description: "Get authoritative family members or visitors.",
    parameters: {
      type: "OBJECT",
      properties: { relation: { type: "STRING" } },
    },
  },
  tool("get_family_memories", "Get authoritative family memories."),
  tool("get_recent_activity", "Get authoritative recent activity."),
  tool("get_available_games", "List games available in NIRVANA."),
  tool("start_game", "Start a NIRVANA game when the user asks to play."),
  tool("get_current_date", "Get the current date from NIRVANA."),
  tool("get_current_time", "Get the current time from NIRVANA."),
];

function tool(name: string, description: string) {
  return {
    name,
    description,
    parameters: { type: "OBJECT", properties: {} },
  };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: HEADERS });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("OK", { headers: HEADERS });

  try {
    const payload = (await req.json()) as RequestPayload;
    const query = payload.query?.trim();
    if (!query) return json({ error: "Missing or empty query" }, 400);

    const language = payload.languageCode || "en";
    const toolResults = Array.isArray(payload.toolResults) ? payload.toolResults : [];
    const conversation = Array.isArray(payload.conversation) ? payload.conversation : [];
    const authoritative = toolResults.length > 0
      ? `\nAuthoritative NIRVANA tool results. Use only these facts for personal data:\n${toolResults.map((item) => `${item.name}: ${item.result}`).join("\n")}`
      : "";
    const prompt = `${NIRVANA_SYSTEM_PROMPT}\nSelected language: ${language}${authoritative}`;
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    if (geminiKey) {
      const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.0-flash";
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;
      const body = {
        systemInstruction: { parts: [{ text: prompt }] },
        contents: [
          ...conversation
            .filter((item) => item.role === "user" || item.role === "model")
            .map((item) => ({ role: item.role, parts: [{ text: item.text }] })),
          { role: "user", parts: [{ text: query }] },
        ],
        generationConfig: { temperature: 0.3, maxOutputTokens: 180 },
        ...(authoritative ? {} : { tools: [{ functionDeclarations: TOOL_DECLARATIONS }] }),
      };
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (response.ok) {
        const data = await response.json();
        const parts = data.candidates?.[0]?.content?.parts ?? [];
        const reply = parts.find((part: any) => typeof part.text === "string")?.text?.trim();
        if (reply) return json({ reply, provider: "gemini" });

        const toolCalls = parts
          .filter((part: any) => part.functionCall?.name)
          .map((part: any) => ({
            name: part.functionCall.name,
            arguments: part.functionCall.args ?? {},
          }));
        if (toolCalls.length > 0) return json({ toolCalls, provider: "gemini" });
      }
    }

    const fallback: Record<string, string> = {
      en: "I'm right here with you. Take all the time you need. You are safe and cared for.",
      hi: "मैं आपके साथ हूँ। कोई जल्दी नहीं है, आप बिल्कुल सुरक्षित हैं।",
      bn: "আমি আপনার সাথেই আছি। কোনো তাড়া নেই, আপনি সম্পূর্ণ নিরাপদ।",
      as: "মই আপোনাৰ লগতেই আছোঁ। কোনো চিন্তা নকৰিব, আপুনি সুৰক্ষিত।",
      ne: "म तपाईंसँगै छु। कुनै हतार छैन, तपाईं पूर्ण सुरक्षित हुनुहुन्छ।",
      mni: "ঐহাক নহাক্কা লোয়ননা লৈরি। অদোম শান্তিনা লৈবীয়ু।",
      kha: "Nga don ryngkat bad phi. Shong thait suk.",
      lus: "I hnenah ka awm reng e. Hahchawl la, hahdam takin awm rawh.",
    };
    return json({ reply: fallback[language] || fallback.en, provider: "local_mock" });
  } catch (error) {
    console.error("ask-nirvana-ai error", error);
    return json({ error: "AI service unavailable" }, 500);
  }
});
