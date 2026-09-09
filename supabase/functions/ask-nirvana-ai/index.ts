// ==============================================================================
// NIRVANA - Supabase Edge Function: ask-nirvana-ai
// Description: Secure server-side AI fallback endpoint for Ask NIRVANA.
// Invoked when an elder's voice query does NOT match structured NIRVANA intents.
//
// SECURITY & PRIVACY:
// - AI provider API keys (GEMINI_API_KEY / OPENAI_API_KEY) are kept strictly in Supabase Secrets.
// - No private API keys or service credentials are ever stored in or sent to the client.
// - Strict dementia-safety, medical diversion, and concise elder-friendly prompt rules.
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

interface RequestPayload {
  query: string;
  languageCode: string;
  patientContext?: string;
}

const NIRVANA_SYSTEM_PROMPT = `
You are NIRVANA, a gentle, compassionate, and reassuring AI companion for an older adult with memory care needs.

CRITICAL SAFETY & INTERACTION RULES:
1. Short & Clear: Always use 1 or 2 short, simple sentences. Avoid complicated words, jargon, or long explanations.
2. Tone: Calm, patient, respectful, warm, and comforting.
3. Language: Respond fluently in the requested language (e.g., English, Hindi, Bengali, Assamese, Nepali, etc.).
4. Medical & Dementia Safety:
   - NEVER diagnose dementia, Alzheimer's, or any medical condition.
   - NEVER suggest or alter medication names, doses, or schedules.
   - NEVER contradict or override caregiver or doctor advice.
   - For physical symptoms or emergencies, calmly guide the user to their caregiver or doctor.
5. Zero Fabrication:
   - NEVER invent appointments, family members, or past events.
   - If asked for personal or unrecorded information, gently state you do not have that information.
6. Examples of Good Responses:
   - "I am right here with you. How are you feeling today?"
   - "That sounds like a lovely memory. Take your time to enjoy the day."
   - "You could try a gentle memory game. Would you like to play one?"
`;

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
    const payload: RequestPayload = await req.json();
    const { query, languageCode, patientContext } = payload;

    if (!query || typeof query !== "string" || query.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing or empty query" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const lang = languageCode || "en";
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    const openAiApiKey = Deno.env.get("OPENAI_API_KEY");

    // 1. If Gemini API key is configured in Supabase Secrets
    if (geminiApiKey) {
      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;
        const body = {
          systemInstruction: {
            parts: [{ text: `${NIRVANA_SYSTEM_PROMPT}\nTarget Language Code: ${lang}\n${patientContext ? `Elder Context: ${patientContext}` : ""}` }],
          },
          contents: [
            {
              role: "user",
              parts: [{ text: query }],
            },
          ],
          generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 100,
          },
        };

        const res = await fetch(geminiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });

        if (res.ok) {
          const geminiData = await res.json();
          const replyText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
          if (replyText) {
            return new Response(
              JSON.stringify({ reply: replyText, provider: "gemini" }),
              { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
            );
          }
        }
      } catch (geminiError) {
        console.error("Gemini API call failed:", geminiError);
      }
    }

    // 2. If OpenAI API key is configured in Supabase Secrets
    if (openAiApiKey) {
      try {
        const openAiUrl = "https://api.openai.com/v1/chat/completions";
        const body = {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: `${NIRVANA_SYSTEM_PROMPT}\nTarget Language Code: ${lang}\n${patientContext ? `Elder Context: ${patientContext}` : ""}` },
            { role: "user", content: query },
          ],
          temperature: 0.3,
          max_tokens: 100,
        };

        const res = await fetch(openAiUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${openAiApiKey}`,
          },
          body: JSON.stringify(body),
        });

        if (res.ok) {
          const openAiData = await res.json();
          const replyText = openAiData.choices?.[0]?.message?.content?.trim();
          if (replyText) {
            return new Response(
              JSON.stringify({ reply: replyText, provider: "openai" }),
              { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
            );
          }
        }
      } catch (openAiError) {
        console.error("OpenAI API call failed:", openAiError);
      }
    }

    // 3. Fallback Response if no backend secret configured or provider offline
    const defaultFallbacks: Record<string, string> = {
      en: "I'm right here with you. Take all the time you need. You are safe and cared for.",
      hi: "मैं आपके साथ हूँ। कोई जल्दी नहीं है, आप बिल्कुल सुरक्षित हैं।",
      bn: "আমি আপনার সাথেই আছি। কোনো তাড়া নেই, আপনি সম্পূর্ণ নিরাপদ।",
      as: "মই আপোনাৰ লগতেই আছোঁ। কোনো চিন্তা নকৰিব, আপুনি সুৰক্ষিত।",
      ne: "म तपाईंसँगै छु। कुनै हतार छैन, तपाईं पूर्ण सुरक्षित हुनुहुन्छ।",
      mni: "ঐহাক নহাক্কা লোয়ননা লৈরি। অদোম শান্তিনা লৈবীয়ু।",
      kha: "Nga don ryngkat bad phi. Shong thait suk.",
      lus: "I hnenah ka awm reng e. Hahchawl la, hahdam takin awm rawh.",
    };

    const reply = defaultFallbacks[lang] || defaultFallbacks.en;

    return new Response(
      JSON.stringify({ reply, provider: "local_mock" }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  } catch (err: any) {
    console.error("Error in ask-nirvana-ai edge function:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
