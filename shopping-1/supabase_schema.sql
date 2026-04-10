-- ============================================================
-- MSF Shopping List – Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── DROP EXISTING (kør dette for at starte frisk) ────────────
-- Tabeller droppes først – CASCADE fjerner tilhørende triggers automatisk
DROP TABLE IF EXISTS public.placements      CASCADE;
DROP TABLE IF EXISTS public.product_themes  CASCADE;
DROP TABLE IF EXISTS public.products        CASCADE;
DROP TABLE IF EXISTS public.themes          CASCADE;
DROP TABLE IF EXISTS public.profiles        CASCADE;

-- Trigger på auth.users droppes separat (ikke en public tabel)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Functions droppes sidst
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user()          CASCADE;
DROP FUNCTION IF EXISTS public.seed_dummy_data()          CASCADE;
DROP FUNCTION IF EXISTS public.current_user_role()        CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Profiles ────────────────────────────────────────────────
CREATE TABLE public.profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email       TEXT,
  full_name   TEXT,
  user_role   TEXT NOT NULL DEFAULT 'user'
                CHECK (user_role IN ('admin', 'user')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Themes ──────────────────────────────────────────────────
CREATE TABLE public.themes (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Products ────────────────────────────────────────────────
CREATE TABLE public.products (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name            TEXT NOT NULL,
  unicat_name     TEXT,
  description     TEXT,
  price_example   TEXT,
  price_eur       NUMERIC(10, 6) NOT NULL DEFAULT 0,
  is_active       BOOLEAN DEFAULT TRUE,
  last_edited_by  UUID REFERENCES public.profiles(id),
  last_edited_at  TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Product ↔ Themes (junction) ────────────────────────────
CREATE TABLE public.product_themes (
  product_id  UUID REFERENCES public.products(id) ON DELETE CASCADE,
  theme_id    UUID REFERENCES public.themes(id)   ON DELETE CASCADE,
  PRIMARY KEY (product_id, theme_id)
);

-- ── Placements ──────────────────────────────────────────────
CREATE TABLE public.placements (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id  UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  channel     TEXT NOT NULL
                CHECK (channel IN ('landingpage', 'some', 'print', 'paid')),
  title       TEXT NOT NULL DEFAULT '',
  url         TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── updated_at trigger ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_placements_updated_at
  BEFORE UPDATE ON public.placements
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ── Auto-create profile on signup ───────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, user_role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'user'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── RLS ─────────────────────────────────────────────────────
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placements    ENABLE ROW LEVEL SECURITY;

-- Helper function: current user role
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT user_role FROM public.profiles WHERE id = auth.uid();
$$;

-- profiles
CREATE POLICY "profiles: authenticated read all"
  ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles: own insert"
  ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles: own update"
  ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- themes
CREATE POLICY "themes: authenticated read"
  ON public.themes FOR SELECT TO authenticated USING (true);
CREATE POLICY "themes: admin insert"
  ON public.themes FOR INSERT TO authenticated
  WITH CHECK (public.current_user_role() = 'admin');
CREATE POLICY "themes: admin update"
  ON public.themes FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'admin');
CREATE POLICY "themes: admin delete"
  ON public.themes FOR DELETE TO authenticated
  USING (public.current_user_role() = 'admin');

-- products
CREATE POLICY "products: authenticated read"
  ON public.products FOR SELECT TO authenticated USING (true);
CREATE POLICY "products: admin insert"
  ON public.products FOR INSERT TO authenticated
  WITH CHECK (public.current_user_role() = 'admin');
CREATE POLICY "products: admin update"
  ON public.products FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'admin');
CREATE POLICY "products: admin delete"
  ON public.products FOR DELETE TO authenticated
  USING (public.current_user_role() = 'admin');

-- product_themes
CREATE POLICY "product_themes: authenticated read"
  ON public.product_themes FOR SELECT TO authenticated USING (true);
CREATE POLICY "product_themes: admin insert"
  ON public.product_themes FOR INSERT TO authenticated
  WITH CHECK (public.current_user_role() = 'admin');
CREATE POLICY "product_themes: admin delete"
  ON public.product_themes FOR DELETE TO authenticated
  USING (public.current_user_role() = 'admin');

-- placements (all authenticated users can CRUD)
CREATE POLICY "placements: authenticated read"
  ON public.placements FOR SELECT TO authenticated USING (true);
CREATE POLICY "placements: authenticated insert"
  ON public.placements FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "placements: authenticated update"
  ON public.placements FOR UPDATE TO authenticated USING (true);
CREATE POLICY "placements: authenticated delete"
  ON public.placements FOR DELETE TO authenticated USING (true);

-- ── Seed dummy data (run ONCE after schema is applied) ───────
-- Execute: SELECT public.seed_dummy_data();
CREATE OR REPLACE FUNCTION public.seed_dummy_data()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_theme_id   UUID;
  v_product_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM public.themes LIMIT 1) THEN
    RETURN 'Data already exists – skipped.';
  END IF;

  INSERT INTO public.themes (name) VALUES
    ('Medical Material')  RETURNING id INTO v_theme_id;

  INSERT INTO public.themes (name) VALUES
    ('Vaccination'),
    ('Malaria'),
    ('Nutrition');

  INSERT INTO public.products
    (name, unicat_name, description, price_example, price_eur)
  VALUES (
    'Dummy Product (Rediger mig)',
    'SAMPLE, PRODUCT, dummy',
    'Dette er et demo-produkt. Klik "Rediger Stamdata" for at opdatere det med rigtige oplysninger.',
    '100 stk. til behandling af patienter i felten',
    0.15
  ) RETURNING id INTO v_product_id;

  INSERT INTO public.product_themes (product_id, theme_id)
  VALUES (v_product_id, v_theme_id);

  RETURN 'Dummy data inserted successfully.';
END;
$$;

-- ── Make first user admin (run AFTER first signup) ───────────
-- UPDATE public.profiles SET user_role = 'admin' WHERE email = 'your@email.com';
