// supabase/functions/gemini-chat/index.ts
// Proxy seguro para Gemini AI con soporte multimodal (texto + imagen)
// Deploy: supabase functions deploy gemini-chat --project-ref iqdobggghorpuepuquhb

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const requestCounts = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 20;
const WINDOW_MS = 60000;
const MAX_IMAGE_BASE64_LENGTH = 6_000_000;
const ALLOWED_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

function isRateLimited(userId: string): boolean {
  const now = Date.now();
  const userLimit = requestCounts.get(userId);

  if (!userLimit || now > userLimit.resetAt) {
    requestCounts.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return false;
  }

  if (userLimit.count >= RATE_LIMIT) return true;
  userLimit.count++;
  return false;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    let userId = "anonymous";
    try {
      const payload = JSON.parse(atob(token.split(".")[1]));
      userId = payload.sub ?? "anonymous";
    } catch (_) {}

    if (isRateLimited(userId)) {
      return new Response(
        JSON.stringify({ error: "Limite de peticiones alcanzado. Intenta en 1 minuto." }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();
    const rawMessage = typeof body.message === "string" ? body.message.trim() : "";
    const imageBase64 = typeof body.imageBase64 === "string" ? body.imageBase64.trim() : "";
    const mimeType = typeof body.mimeType === "string" && ALLOWED_MIME_TYPES.has(body.mimeType)
      ? body.mimeType
      : "image/jpeg";
    const history = Array.isArray(body.history) ? body.history.slice(-8) : [];

    if (!rawMessage && !imageBase64) {
      return new Response(JSON.stringify({ error: "Mensaje o imagen requeridos" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (rawMessage.length > 3000) {
      return new Response(JSON.stringify({ error: "Mensaje demasiado largo" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (imageBase64.length > MAX_IMAGE_BASE64_LENGTH) {
      return new Response(JSON.stringify({ error: "La imagen supera el tamano permitido" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "Servicio de IA no configurado" }), {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const contents: Array<Record<string, unknown>> = [];
    for (const item of history) {
      if (item && typeof item.text === "string" && item.text.trim()) {
        contents.push({
          role: item.role === "model" ? "model" : "user",
          parts: [{ text: item.text.trim() }],
        });
      }
    }

    const userParts: Array<Record<string, unknown>> = [
      {
        text: rawMessage ||
          "Analiza esta imagen relacionada con mi vehiculo. Identifica el componente, testigo o posible falla y dame recomendaciones tecnicas claras en espanol.",
      },
    ];

    if (imageBase64) {
      userParts.push({
        inline_data: {
          mime_type: mimeType,
          data: imageBase64,
        },
      });
    }

    contents.push({ role: "user", parts: userParts });

    const models = ["gemini-2.5-flash", "gemini-2.5-flash-lite"];

    for (const model of models) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents,
              systemInstruction: {
                parts: [
                  {
                    text:
                      "Eres Master Mechanic, el asistente tecnico automotriz de My Auto Guide. " +
                      "Respondes en espanol claro, directo y profesional sobre mecanica automotriz y de motocicletas, " +
                      "diagnostico visual de piezas/testigos/fugas/llantas, mantenimiento y uso de la app. " +
                      "Si te envian una foto, analiza primero lo que observas, nivel de riesgo (bajo/medio/alto) y pasos recomendados. " +
                      "Si te preguntan temas ajenos, explica amablemente tu especialidad.",
                  },
                ],
              },
            }),
          },
        );

        if (res.ok) {
          const data = await res.json();
          const text =
            data?.candidates?.[0]?.content?.parts?.[0]?.text ??
            "Sin respuesta de la IA.";
          return new Response(JSON.stringify({ text, model }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } catch (_) {
        continue;
      }
    }

    return new Response(
      JSON.stringify({ error: "No se pudo conectar con la IA. Intenta mas tarde." }),
      {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (_) {
    return new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
