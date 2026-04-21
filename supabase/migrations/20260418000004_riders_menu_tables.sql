-- Riders and Menu Items tables for Menaka Home Foods Admin Panel
-- Migration: 20260418000004_riders_menu_tables.sql

-- ─── RIDERS TABLE ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.riders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'inactive',
  current_orders_count INTEGER NOT NULL DEFAULT 0,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  location_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_riders_status ON public.riders(status);
CREATE INDEX IF NOT EXISTS idx_riders_created_at ON public.riders(created_at DESC);

ALTER TABLE public.riders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "riders_open_access" ON public.riders;
CREATE POLICY "riders_open_access"
ON public.riders FOR ALL TO public
USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.update_riders_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS riders_updated_at ON public.riders;
CREATE TRIGGER riders_updated_at
  BEFORE UPDATE ON public.riders
  FOR EACH ROW EXECUTE FUNCTION public.update_riders_updated_at();

-- ─── MENU ITEMS TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'Breakfast',
  meal_type TEXT NOT NULL DEFAULT 'breakfast',
  image_url TEXT NOT NULL DEFAULT '',
  is_veg BOOLEAN NOT NULL DEFAULT true,
  available_for_order BOOLEAN NOT NULL DEFAULT true,
  available_for_subscription BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_meal_type ON public.menu_items(meal_type);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(available_for_order);

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "menu_items_open_access" ON public.menu_items;
CREATE POLICY "menu_items_open_access"
ON public.menu_items FOR ALL TO public
USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.update_menu_items_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS menu_items_updated_at ON public.menu_items;
CREATE TRIGGER menu_items_updated_at
  BEFORE UPDATE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.update_menu_items_updated_at();

-- ─── SEED DATA ────────────────────────────────────────────────────────────────
DO $$
BEGIN
  -- Seed riders
  INSERT INTO public.riders (id, name, phone, status, current_orders_count)
  VALUES
    (gen_random_uuid(), 'Ravi Kumar', '+91 98765 11111', 'active', 2),
    (gen_random_uuid(), 'Suresh Babu', '+91 87654 22222', 'active', 0),
    (gen_random_uuid(), 'Pradeep Singh', '+91 76543 33333', 'active', 1),
    (gen_random_uuid(), 'Kiran Reddy', '+91 65432 44444', 'inactive', 0)
  ON CONFLICT (id) DO NOTHING;

  -- Seed menu items
  INSERT INTO public.menu_items (id, name, description, price, category, meal_type, image_url, is_veg, available_for_order, available_for_subscription)
  VALUES
    (gen_random_uuid(), 'Masala Dosa', 'Crispy dosa with spiced potato filling, sambar & chutneys', 89, 'Breakfast', 'breakfast', 'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg', true, true, true),
    (gen_random_uuid(), 'Idli Sambar', 'Soft steamed idlis with piping hot sambar and chutneys', 69, 'Breakfast', 'breakfast', 'https://images.pexels.com/photos/4331489/pexels-photo-4331489.jpeg', true, true, true),
    (gen_random_uuid(), 'Poha', 'Light flattened rice with mustard, curry leaves & peanuts', 59, 'Breakfast', 'breakfast', 'https://images.pexels.com/photos/7625056/pexels-photo-7625056.jpeg', true, true, false),
    (gen_random_uuid(), 'Veg Thali', 'Complete meal with rice, dal, sabzi, roti, pickle & papad', 149, 'Lunch', 'lunch', 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg', true, true, true),
    (gen_random_uuid(), 'Chicken Biryani', 'Fragrant basmati rice with tender chicken and aromatic spices', 199, 'Lunch', 'lunch', 'https://images.pexels.com/photos/1624487/pexels-photo-1624487.jpeg', false, true, true),
    (gen_random_uuid(), 'Dal Tadka', 'Yellow lentils tempered with ghee, cumin and spices', 99, 'Lunch', 'lunch', 'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg', true, true, true),
    (gen_random_uuid(), 'Paneer Butter Masala', 'Creamy tomato-based curry with soft paneer cubes', 159, 'Dinner', 'dinner', 'https://images.pexels.com/photos/2474661/pexels-photo-2474661.jpeg', true, true, true),
    (gen_random_uuid(), 'Fish Curry', 'Coastal-style fish curry with coconut milk and spices', 179, 'Dinner', 'dinner', 'https://images.pexels.com/photos/3655916/pexels-photo-3655916.jpeg', false, true, false),
    (gen_random_uuid(), 'Chapati with Sabzi', 'Soft whole wheat chapatis with seasonal vegetable curry', 89, 'Dinner', 'dinner', 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg', true, true, true)
  ON CONFLICT (id) DO NOTHING;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
