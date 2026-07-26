// One-shot plant health analysis: farmer uploads a photo, this calls Claude
// vision once and returns a full report. No follow-up conversation here —
// see plant-scan-followup for that.
//
// Runs with the caller's JWT so DB writes go through RLS — no service-role
// escalation, same as regenerate-schedule.
//
// Body: { "farm_id": "<uuid>", "storage_path": "<uid>/<farm_id>/plant-scans/<file>" }

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';
import { encodeBase64 } from 'https://deno.land/std@0.208.0/encoding/base64.ts';

const BUCKET = 'farm-media';
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

function mediaTypeFor(path: string): string {
  const ext = path.toLowerCase().slice(path.lastIndexOf('.'));
  switch (ext) {
    case '.png': return 'image/png';
    case '.webp': return 'image/webp';
    case '.heic': return 'image/heic';
    default: return 'image/jpeg';
  }
}

const ANALYSIS_SCHEMA_PROMPT = `You are assisting a farmer by analyzing a single photo of their crop.
Respond with ONLY a single valid JSON object — no markdown fences, no commentary before or after.
Match this schema exactly:

{
  "disease_or_pest": {
    "detected": boolean,
    "name": string | null,
    "type": "disease" | "pest" | "none",
    "details": string
  },
  "nutrient_deficiency": {
    "detected": boolean,
    "nutrient": string | null,
    "details": string
  },
  "health_score": number,            // 0-100, overall plant health
  "growth_stage": string,            // e.g. "seedling", "vegetative", "flowering", "fruiting", "mature"
  "treatment_plan": string[],        // ordered, concrete steps
  "dosage_guidance": string,         // medicine/treatment dosage, or "not applicable" if no treatment needed
  "organic_alternatives": string[],  // non-chemical options
  "prevention_steps": string[],
  "estimated_recovery_time": string, // e.g. "7-10 days", or "not applicable" if plant is healthy
  "confidence_level": "high" | "medium" | "low",
  "summary": string                  // 2-3 sentence plain-language summary
}

Be direct and specific. If the plant looks healthy, say so plainly rather than inventing a problem.
If the photo is unclear or doesn't show enough of the plant to assess confidently, say so in "summary"
and set "confidence_level" to "low".`;

function clampScore(n: unknown): number {
  const num = typeof n === 'number' ? n : Number(n);
  if (!Number.isFinite(num)) return 0;
  return Math.max(0, Math.min(100, Math.round(num)));
}

function normalizeConfidence(c: unknown): 'high' | 'medium' | 'low' {
  return c === 'high' || c === 'medium' || c === 'low' ? c : 'medium';
}

async function loadFarm(sb: SupabaseClient, farmId: string) {
  const { data, error } = await sb
    .from('farm_profiles')
    .select('id, crop_type, user_id')
    .eq('id', farmId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing_authorization' }, 401);

  let body: { farm_id?: string; storage_path?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const farmId = body.farm_id;
  const storagePath = body.storage_path;
  if (!farmId || !/^[0-9a-f-]{36}$/i.test(farmId)) {
    return json({ error: 'invalid_farm_id' }, 400);
  }
  if (!storagePath || storagePath.includes('..')) {
    return json({ error: 'invalid_storage_path' }, 400);
  }

  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userErr } = await sb.auth.getUser();
  if (userErr || !user) return json({ error: 'invalid_session' }, 401);

  const farm = await loadFarm(sb, farmId);
  if (!farm || farm.user_id !== user.id) {
    // Either the farm doesn't exist, isn't the caller's, or RLS is hiding
    // it — don't leak which.
    return json({ error: 'farm_not_found' }, 404);
  }

  // The path is client-supplied; make sure it actually points at this
  // caller's own scan folder before we go fetch and pay to analyze it.
  const expectedPrefix = `${user.id}/${farmId}/plant-scans/`;
  if (!storagePath.startsWith(expectedPrefix)) {
    return json({ error: 'storage_path_mismatch' }, 403);
  }

  const { data: blob, error: dlErr } = await sb.storage.from(BUCKET).download(storagePath);
  if (dlErr || !blob) return json({ error: 'photo_not_found', detail: dlErr?.message }, 404);

  const bytes = new Uint8Array(await blob.arrayBuffer());
  const base64Image = encodeBase64(bytes);
  const mediaType = mediaTypeFor(storagePath);

  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicKey) return json({ error: 'server_misconfigured' }, 500);

  const contextLine = farm.crop_type
    ? `The farmer says this field is growing: ${farm.crop_type}.`
    : '';

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
        max_tokens: 1400,
        temperature: 0.2,
        messages: [{
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: mediaType, data: base64Image } },
            { type: 'text', text: `${contextLine}\n\n${ANALYSIS_SCHEMA_PROMPT}` },
          ],
        }],
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
  const rawText: string = aiData?.content?.find((c: { type: string }) => c.type === 'text')?.text ?? '';
  const cleaned = rawText.replace(/^```json\s*|```$/g, '').trim();

  let analysis: Record<string, unknown>;
  try {
    analysis = JSON.parse(cleaned);
  } catch {
    return json({ error: 'analysis_parse_failed', detail: rawText }, 502);
  }

  analysis.health_score = clampScore(analysis.health_score);
  const confidenceLevel = normalizeConfidence(analysis.confidence_level);
  analysis.confidence_level = confidenceLevel;

  const { data: inserted, error: insErr } = await sb
    .from('plant_health_scans')
    .insert({
      user_id: user.id,
      farm_id: farmId,
      photo_storage_path: storagePath,
      analysis,
      confidence_level: confidenceLevel,
    })
    .select('*')
    .single();

  if (insErr) return json({ error: 'insert_failed', detail: insErr.message }, 500);

  return json(inserted);
});