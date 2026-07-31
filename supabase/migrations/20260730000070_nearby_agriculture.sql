CREATE TABLE IF NOT EXISTS public.saved_agri_places (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id      text NOT NULL,
  name          text NOT NULL,
  address       text,
  latitude      double precision NOT NULL,
  longitude     double precision NOT NULL,
  place_type    text NOT NULL,
  rating        double precision,
  distance_km   double precision,
  notes         text,
  saved_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, place_id)
);

ALTER TABLE public.saved_agri_places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner select saved_agri_places"
  ON public.saved_agri_places FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "owner insert saved_agri_places"
  ON public.saved_agri_places FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner update saved_agri_places"
  ON public.saved_agri_places FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "owner delete saved_agri_places"
  ON public.saved_agri_places FOR DELETE
  USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.agri_place_community_notes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id      text NOT NULL,
  place_name    text NOT NULL,
  note          text NOT NULL,
  helpful_count int NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.agri_place_community_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated read agri_place_community_notes"
  ON public.agri_place_community_notes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "owner insert agri_place_community_notes"
  ON public.agri_place_community_notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner delete agri_place_community_notes"
  ON public.agri_place_community_notes FOR DELETE
  USING (auth.uid() = user_id);