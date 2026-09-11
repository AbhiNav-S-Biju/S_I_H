// ============================================================================
// NIRVANA secure Gemini gateway.
// Gemini credentials remain Supabase secrets and never enter Flutter.
// ============================================================================

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
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const NIRVANA_SYSTEM_PROMPT = `
You are NIRVANA, a calm, intelligent, patient and elderly-friendly
cognitive engagement and memory-assistance companion.

You are powered by Gemini and can answer general questions naturally,
while also helping the user with NIRVANA-specific features.

Use simple, clear and natural language.
Be warm without being childish or patronizing.
Keep responses concise enough to be comfortable when spoken aloud.

IMPORTANT BEHAVIOR:

1. GENERAL QUESTIONS
Answer general knowledge, educational, conversational and everyday
questions normally.

2. STORIES
If the user asks for a story, tell an actual short, engaging story.
Do NOT respond with a generic emotional-support message.
For "tell me another story", provide a different story.
Stories should be calm, positive and appropriate for elderly users.

3. NIRVANA DATA
For reminders, routines, family members, memories, activities and
other personal NIRVANA information, use authoritative NIRVANA data.
Never invent personal information.

4. GAMES
If the user asks about games, explain the available NIRVANA games.
If they explicitly ask to play a game, use the appropriate NIRVANA
game functionality.

5. CONVERSATION
Understand follow-up questions and conversational context.
For example:
"Tell me a story" → tell a story.
"Another one" → tell a different story.
"Make it funny" → modify the next story accordingly.

6. ORIENTATION
Help with date, day and time using NIRVANA tools when available.

7. LANGUAGE
Respond in the user's selected language.

8. SAFETY
Never diagnose dementia.
Never provide medication dosage or treatment instructions.
For medical concerns, encourage contacting the caregiver or doctor.

9. PERSONAL DATA
Never fabricate reminders, appointments, family members, memories,
caregiver instructions or activities.

10. FALLBACK
Do not use generic phrases such as
"I'm right here with you. Take all the time you need."
when the user has asked a question that you can answer.

You are an intelligent companion, not merely a predefined chatbot.
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

function safeGeminiError(status: number, body: string): void {
  let detail = body.slice(0, 500);
  try {
    const parsed = JSON.parse(body);
    detail = JSON.stringify({
      code: parsed.error?.code,
      status: parsed.error?.status,
      message: parsed.error?.message,
    });
  } catch (_) {
    // Keep the truncated provider response when it is not JSON.
  }
  console.error(`Gemini API request failed: HTTP ${status} ${detail}`);
}

function extractReply(data: any): string | null {
  const parts = data?.candidates?.[0]?.content?.parts ?? [];
  const texts = parts
    .filter((part: any) => typeof part.text === "string")
    .map((part: any) => part.text.trim())
    .filter((text: string) => text.length > 0);
  return texts.length > 0 ? texts.join("\n").trim() : null;
}

function extractToolCalls(data: any): Array<{ name: string; arguments: Record<string, unknown> }> {
  const parts = data?.candidates?.[0]?.content?.parts ?? [];
  return parts
    .filter((part: any) => part.functionCall?.name)
    .map((part: any) => ({
      name: part.functionCall.name,
      arguments: (part.functionCall.args as Record<string, unknown>) ?? {},
    }));
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

    if (!geminiKey) {
      console.error("ask-nirvana-ai: GEMINI_API_KEY is not configured");
      return json({ reply: "I can't connect right now, but I can still help with your reminders and daily routine.", provider: "local_mock" });
    }

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-3.5-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;
    const body = {
      systemInstruction: { parts: [{ text: prompt }] },
      contents: [
        ...conversation
          .filter((item) => item.role === "user" || item.role === "model")
          .map((item) => ({ role: item.role, parts: [{ text: item.text }] })),
        { role: "user", parts: [{ text: query }] },
      ],
      generationConfig: { temperature: 0.7, maxOutputTokens: 500 },
      ...(authoritative ? {} : { tools: [{ functionDeclarations: TOOL_DECLARATIONS }] }),
    };

    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const responseBody = await response.text();
    if (!response.ok) {
      safeGeminiError(response.status, responseBody);
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
    }

    let data: any;
    try {
      data = JSON.parse(responseBody);
    } catch (error) {
      console.error(`Gemini returned invalid JSON: ${String(error)}`);
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
      return json({
        reply: fallback[language] || fallback.en,
        provider: "local_mock",
      });
    }

    const finishReason = data?.candidates?.[0]?.finishReason;
    if (finishReason && finishReason !== "STOP") {
      console.error(`Gemini finished with reason: ${finishReason}`);
    }

    const candidates = data?.candidates;
    if (!Array.isArray(candidates) || candidates.length === 0) {
      console.error("Gemini returned no candidates");
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
      return json({
        reply: fallback[language] || fallback.en,
        provider: "local_mock",
      });
    }

    const toolCalls = extractToolCalls(data);
    if (toolCalls.length > 0) return json({ toolCalls, provider: "gemini" });

    const reply = extractReply(data);
    if (reply) return json({ reply, provider: "gemini" });

    console.error("Gemini returned no text or function call.");
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
    return json({
      reply: fallback[language] || fallback.en,
      provider: "local_mock",
    });
  } catch (error) {
    console.error("ask-nirvana-ai error", error);
    return json({ error: "AI service unavailable" }, 500);
  }
});
