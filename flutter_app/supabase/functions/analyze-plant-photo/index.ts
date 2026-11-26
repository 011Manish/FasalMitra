// Plant health scan. Pl@ntNet names the likely disease or pest from the photo.
// If GEMINI_API_KEY is set, Gemini also writes the full report; without it the
// report holds only the Pl@ntNet matches.
//
// Runs with the caller's JWT so DB writes go through RLS (no service-role).
// Upstream errors are logged by status only and never sent to the phone: the
// Pl@ntNet key travels in the request URL and must never appear in any output.
//
// Body: { "farm_id": "<uuid>" | null, "storage_path": "<uid>[/<farm_id>]/plant-scans/<file>" }

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';
import { encodeBase64 } from 'https://deno.land/std@0.208.0/encoding/base64.ts';

const BUCKET = 'farm-media';
const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.0-flash';
const PLANTNET_URL = 'https://my-api.plantnet.org/v2/diseases/identify';
const PLANTNET_TIMEOUT_MS = 8000;
const GEMINI_TIMEOUT_MS = 25000;
const MAX_MATCHES = 3;
const HIGH_SCORE = 0.7;
const MEDIUM_SCORE = 0.4;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Match = { code: string; label: string; score: number };
type PlantnetResult =
  | { status: 'ok'; matches: Match[] }
  | { status: 'skipped' | 'rate_limited' | 'failed' };

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
Respond with ONLY a single valid JSON object, no markdown fences, no commentary before or after.
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

function confidenceFor(matches: Match[]): 'high' | 'medium' | 'low' {
  const top = matches[0]?.score ?? 0;
  if (top >= HIGH_SCORE) return 'high';
  if (top >= MEDIUM_SCORE) return 'medium';
  return 'low';
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

async function identifyWithPlantnet(
  buffer: ArrayBuffer,
  mediaType: string,
  key: string | undefined,
): Promise<PlantnetResult> {
  // Pl@ntNet accepts only JPEG and PNG.
  if (!key || (mediaType !== 'image/jpeg' && mediaType !== 'image/png')) {
    return { status: 'skipped' };
  }

  const form = new FormData();
  form.append(
    'images',
    new Blob([buffer], { type: mediaType }),
    mediaType === 'image/png' ? 'photo.png' : 'photo.jpg',
  );

  let res: Response;
  try {
    res = await fetch(
      `${PLANTNET_URL}?nb-results=${MAX_MATCHES}&lang=en&api-key=${encodeURIComponent(key)}`,
      { method: 'POST', body: form, signal: AbortSignal.timeout(PLANTNET_TIMEOUT_MS) },
    );
  } catch (e) {
    // Never log the error object: its message can contain the URL and the key.
    console.error('plantnet request failed:', e instanceof Error ? e.name : 'unknown');
    return { status: 'failed' };
  }

  if (res.status === 429) return { status: 'rate_limited' };
  // Treated as "nothing matched". If every scan shows this, check the logs.
  if (res.status === 404) {
    console.error('plantnet status: 404');
    return { status: 'ok', matches: [] };
  }
  if (!res.ok) {
    console.error('plantnet status:', res.status);
    return { status: 'failed' };
  }

  const data = await res.json().catch(() => null);
  const results: Record<string, unknown>[] = Array.isArray(data?.results) ? data.results : [];
  const matches: Match[] = results.slice(0, MAX_MATCHES).flatMap((r) => {
    const score = Number(r.score);
    const code = String(r.name ?? '');
    const label = typeof r.description === 'string' && r.description ? r.description : code;
    if (!Number.isFinite(score) || !label) return [];
    return [{ code, label, score: Math.max(0, Math.min(1, score)) }];
  });
  return { status: 'ok', matches };
}

async function askGemini(
  key: string,
  contextLine: string,
  matches: Match[],
  base64Image: string,
  mediaType: string,
): Promise<Record<string, unknown> | null> {
  const hint = matches.length
    ? `An image classifier suggests these possible matches. Use them only as hints: ${
      matches.map((m) => `${m.label} (${Math.round(m.score * 100)}%)`).join('; ')
    }.`
    : '';

  let res: Response;
  try {
    res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify({
          contents: [{
            parts: [
              { text: `${contextLine}\n${hint}\n\n${ANALYSIS_SCHEMA_PROMPT}` },
              { inline_data: { mime_type: mediaType, data: base64Image } },
            ],
          }],
          generationConfig: { temperature: 0.2, maxOutputTokens: 1400 },
        }),
        signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
      },
    );
  } catch (e) {
    console.error('gemini request failed:', e instanceof Error ? e.name : 'unknown');
    return null;
  }

  if (!res.ok) {
    console.error('gemini status:', res.status);
    return null;
  }

  const data = await res.json().catch(() => null);
  const rawText: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  const cleaned = rawText.replace(/^```json\s*|```$/g, '').trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    console.error('gemini reply was not valid JSON');
    return null;
  }
}

function plantnetOnlyAnalysis(matches: Match[]): Record<string, unknown> {
  const top = matches[0];
  const summary = top
    ? `The closest match is ${top.label} (${Math.round(top.score * 100)}% confidence). ` +
      'This only names a possible problem. It does not say how to treat it, so ask a local agricultural expert before using any treatment.'
    : 'No known disease or pest was matched in this photo. This service covers only some crops and problems, so this does not mean the plant is healthy.';
  return {
    source: 'plantnet',
    plantnet: matches,
    confidence_level: confidenceFor(matches),
    summary,
  };
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing_authorization' }, 401);

  let body: { farm_id?: string | null; storage_path?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const farmId = body.farm_id ?? null;
  const storagePath = body.storage_path;
  if (farmId !== null && !/^[0-9a-f-]{36}$/i.test(farmId)) {
    return json({ error: 'invalid_farm_id' }, 400);
  }
  if (!storagePath || storagePath.includes('..')) {
    return json({ error: 'invalid_storage_path' }, 400);
  }

  const plantnetKey = Deno.env.get('PLANTNET_API_KEY');
  const geminiKey = Deno.env.get('GEMINI_API_KEY');
  if (!plantnetKey && !geminiKey) return json({ error: 'server_misconfigured' }, 500);

  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userErr } = await sb.auth.getUser();
  if (userErr || !user) return json({ error: 'invalid_session' }, 401);

  const farm = farmId ? await loadFarm(sb, farmId) : null;
  if (farmId && (!farm || farm.user_id !== user.id)) {
    return json({ error: 'farm_not_found' }, 404);
  }

  const expectedPrefix = farmId
    ? `${user.id}/${farmId}/plant-scans/`
    : `${user.id}/plant-scans/`;
  if (!storagePath.startsWith(expectedPrefix)) {
    return json({ error: 'storage_path_mismatch' }, 403);
  }

  const { data: blob, error: dlErr } = await sb.storage.from(BUCKET).download(storagePath);
  if (dlErr || !blob) return json({ error: 'photo_not_found' }, 404);

  const buffer = await blob.arrayBuffer();
  const mediaType = mediaTypeFor(storagePath);

  const plantnet = await identifyWithPlantnet(buffer, mediaType, plantnetKey);
  const matches = plantnet.status === 'ok' ? plantnet.matches : [];

  let analysis: Record<string, unknown> | null = null;
  if (geminiKey) {
    const contextLine = farm?.crop_type
      ? `The farmer says this field is growing: ${farm.crop_type}.`
      : '';
    analysis = await askGemini(
      geminiKey,
      contextLine,
      matches,
      encodeBase64(new Uint8Array(buffer)),
      mediaType,
    );
    if (analysis) {
      analysis.health_score = clampScore(analysis.health_score);
      analysis.plantnet = matches;
    }
  }

  if (!analysis) {
    if (plantnet.status === 'ok') {
      analysis = plantnetOnlyAnalysis(matches);
    } else if (plantnet.status === 'rate_limited') {
      return json({ error: 'plantnet_rate_limited' }, 429);
    } else if (plantnetKey && plantnet.status === 'skipped') {
      return json({ error: 'unsupported_image_type' }, 415);
    } else {
      return json({ error: 'analysis_failed' }, 502);
    }
  }

  const confidenceLevel = normalizeConfidence(
    analysis.confidence_level ?? confidenceFor(matches),
  );
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

  if (insErr) {
    console.error('insert failed:', insErr.message);
    return json({ error: 'insert_failed' }, 500);
  }

  return json(inserted);
});