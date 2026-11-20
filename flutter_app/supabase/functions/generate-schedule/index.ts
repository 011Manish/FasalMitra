// Regenerates the schedule for one farm profile.
//
// Called by the Flutter client immediately after a farm profile is created
// or edited. Runs with the caller's JWT so all DB writes go through RLS —
// there is no service-role escalation here on purpose.
//
// Body: { "farm_id": "<uuid>" }

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

type Fertilizer = { name: string; day_offset: number };
type CropRule = {
  crop_type: string;
  growth_days: number;
  harvest_window_days: number;
  watering_interval_days: number;
  watering_until_day: number;
  fertilizer_schedule: Fertilizer[];
};

const irrigationMultipliers: Record<string, number> = {
  rainfed: 1.5,
  drip: 0.8,
  sprinkler: 0.9,
  flood: 1.2,
  canal: 1.1,
};

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

function addDays(base: Date, days: number): Date {
  const out = new Date(base.getTime());
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function buildItems(rule: CropRule, plantationDate: string, irrigation: string) {
  const start = new Date(plantationDate + 'T00:00:00Z');
  const mult = irrigationMultipliers[irrigation] ?? 1;
  const interval = Math.max(1, Math.round(rule.watering_interval_days * mult));

  const items: { kind: string; title: string; due_date: string }[] = [];

  for (let day = interval; day <= rule.watering_until_day; day += interval) {
    items.push({ kind: 'watering', title: 'Water the field', due_date: isoDate(addDays(start, day)) });
  }

  for (const f of rule.fertilizer_schedule) {
    items.push({
      kind: 'fertilizer',
      title: `Apply: ${f.name}`,
      due_date: isoDate(addDays(start, f.day_offset)),
    });
  }

  const harvestStart = addDays(start, rule.growth_days);
  const harvestEnd = addDays(harvestStart, rule.harvest_window_days);
  items.push({
    kind: 'harvest',
    title: `Estimated harvest window (until ${isoDate(harvestEnd)})`,
    due_date: isoDate(harvestStart),
  });

  items.sort((a, b) => a.due_date.localeCompare(b.due_date));
  return items;
}

async function loadFarm(sb: SupabaseClient, farmId: string) {
  const { data, error } = await sb
    .from('farm_profiles')
    .select('id, crop_type, plantation_date, irrigation_system')
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

  let body: { farm_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const farmId = body.farm_id;
  if (!farmId || !/^[0-9a-f-]{36}$/i.test(farmId)) {
    return json({ error: 'invalid_farm_id' }, 400);
  }

  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const farm = await loadFarm(sb, farmId);
  if (!farm) {
    // Either the farm doesn't exist or RLS is hiding it. Either way,
    // don't leak which.
    return json({ error: 'farm_not_found' }, 404);
  }

  const { data: ruleRow, error: ruleErr } = await sb
    .from('crop_rules')
    .select('*')
    .eq('crop_type', farm.crop_type)
    .maybeSingle();
  if (ruleErr) return json({ error: 'crop_rule_lookup_failed', detail: ruleErr.message }, 500);
  if (!ruleRow) return json({ error: 'no_rule_for_crop' }, 400);

  const items = buildItems(ruleRow as CropRule, farm.plantation_date, farm.irrigation_system);

  // Replace pending items only. Anything the farmer has already marked
  // done/skipped stays as-is so history isn't rewritten every save.
  const { error: delErr } = await sb
    .from('schedule_items')
    .delete()
    .eq('farm_id', farmId)
    .eq('status', 'pending');
  if (delErr) return json({ error: 'delete_failed', detail: delErr.message }, 500);

  const rows = items.map((i) => ({ farm_id: farmId, ...i, status: 'pending' as const }));
  const { data: inserted, error: insErr } = await sb
    .from('schedule_items')
    .insert(rows)
    .select('*');
  if (insErr) return json({ error: 'insert_failed', detail: insErr.message }, 500);

  return json({ inserted_count: inserted?.length ?? 0, items: inserted });
});
