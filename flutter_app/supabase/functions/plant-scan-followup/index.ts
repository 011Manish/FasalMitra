// Follow-up Q&A about a single existing plant scan. Stateless beyond the
// current request: the client resends the scan_id each time.
// The AI key is read from the GEMINI_API_KEY secret. When it is missing the
// function answers `no_api_key` so the app can say so.
//
// Body: { "scan_id": "<uuid>", "question": "<text>" }

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.0-flash';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  });
}

function keyWasRejected(status: number, detail: string): boolean {
  return status === 401 || status === 403 ||
    (status === 400 && detail.includes('API_KEY_INVALID'));
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing_authorization' }, 401);

  let body: { scan_id?: string; question?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const scanId = body.scan_id;
  const question = body.question?.trim();
  if (!scanId || !/^[0-9a-f-]{36}$/i.test(scanId)) return json({ error: 'invalid_scan_id' }, 400);
  if (!question) return json({ error: 'missing_question' }, 400);

  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: scan, error: scanErr } = await sb
    .from('plant_health_scans')
    .select('analysis')
    .eq('id', scanId)
    .maybeSingle();
  if (scanErr) {
    console.error('scan lookup failed', scanErr.message);
    return json({ error: 'lookup_failed' }, 500);
  }
  if (!scan) return json({ error: 'scan_not_found' }, 404);

  const aiKey = Deno.env.get('GEMINI_API_KEY');
  if (!aiKey) return json({ error: 'no_api_key' }, 503);

  const prompt = `A farmer previously got this plant health report:\n\n${JSON.stringify(scan.analysis)}\n\n` +
    `They're now asking a follow-up question about this same scan: "${question}"\n\n` +
    `Answer directly and specifically, referencing the report above where relevant. ` +
    `Keep it to a short, plain-language paragraph or two. Remind them briefly this is an AI estimate ` +
    `if the question involves a treatment decision they'd act on.`;

  let aiRes: Response;
  try {
    aiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': aiKey },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.3, maxOutputTokens: 600 },
        }),
      }
    );
  } catch (e) {
    console.error('AI service unreachable', String(e));
    return json({ error: 'ai_unreachable' }, 502);
  }

  if (!aiRes.ok) {
    const detail = await aiRes.text();
    console.error('AI service error', aiRes.status, detail);
    return json(
      { error: keyWasRejected(aiRes.status, detail) ? 'ai_key_rejected' : 'ai_error' },
      502
    );
  }

  const aiData = await aiRes.json();
  const answer: string = aiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

  return json({ answer });
});