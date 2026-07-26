// Follow-up Q&A about a single existing plant scan. Stateless beyond the
// current request — the client resends the scan_id each time, no server-side
// conversation memory for this first pass.
//
// Body: { "scan_id": "<uuid>", "question": "<text>" }

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const ANTHROPIC_MODEL = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-sonnet-5';

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

  // RLS scopes this to the caller's own scans — a farmer can't ask about
  // someone else's scan by guessing an id.
  const { data: scan, error: scanErr } = await sb
    .from('plant_health_scans')
    .select('analysis')
    .eq('id', scanId)
    .maybeSingle();
  if (scanErr) return json({ error: 'lookup_failed', detail: scanErr.message }, 500);
  if (!scan) return json({ error: 'scan_not_found' }, 404);

  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicKey) return json({ error: 'server_misconfigured' }, 500);

  const prompt = `A farmer previously got this plant health report:\n\n${JSON.stringify(scan.analysis)}\n\n` +
    `They're now asking a follow-up question about this same scan: "${question}"\n\n` +
    `Answer directly and specifically, referencing the report above where relevant. ` +
    `Keep it to a short, plain-language paragraph or two. Remind them briefly this is an AI estimate ` +
    `if the question involves a treatment decision they'd act on.`;

  let aiRes: Response;
  try {
    aiRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 600,
        temperature: 0.3,
        messages: [{ role: 'user', content: prompt }],
      }),
    });
  } catch (e) {
    return json({ error: 'anthropic_unreachable', detail: String(e) }, 502);
  }

  if (!aiRes.ok) {
    const detail = await aiRes.text();
    return json({ error: 'anthropic_error', detail }, 502);
  }

  const aiData = await aiRes.json();
  const answer: string = aiData?.content?.find((c: { type: string }) => c.type === 'text')?.text ?? '';

  return json({ answer });
});