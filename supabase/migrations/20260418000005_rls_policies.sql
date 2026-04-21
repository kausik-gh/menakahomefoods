-- RLS Policies for Menaka Home Foods
-- Enable RLS on all tables

-- Create customers table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID UNIQUE,
  name TEXT NOT NULL DEFAULT '',
  phone TEXT UNIQUE NOT NULL DEFAULT '',
  address TEXT DEFAULT '',
  house_no TEXT DEFAULT '',
  street TEXT DEFAULT '',
  area TEXT DEFAULT '',
  city TEXT DEFAULT '',
  pincode TEXT DEFAULT '',
  language TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_auth_id ON public.customers(auth_id);

-- Create admins table if it doesn't exist (needed for policy references)
CREATE TABLE IF NOT EXISTS public.admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  phone TEXT UNIQUE NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- customers table
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'customers' AND policyname = 'customers_select_own') THEN
    CREATE POLICY customers_select_own ON public.customers
      FOR SELECT USING (auth.uid() = auth_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'customers' AND policyname = 'customers_update_own') THEN
    CREATE POLICY customers_update_own ON public.customers
      FOR UPDATE USING (auth.uid() = auth_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'customers' AND policyname = 'customers_insert_own') THEN
    CREATE POLICY customers_insert_own ON public.customers
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- orders table
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'orders' AND policyname = 'orders_select_policy') THEN
    CREATE POLICY orders_select_policy ON public.orders
      FOR SELECT USING (
        auth.uid()::text = customer_id::text
        OR auth.uid()::text = rider_id::text
        OR EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'orders' AND policyname = 'orders_insert_customer') THEN
    CREATE POLICY orders_insert_customer ON public.orders
      FOR INSERT WITH CHECK (auth.uid()::text = customer_id::text);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'orders' AND policyname = 'orders_update_policy') THEN
    CREATE POLICY orders_update_policy ON public.orders
      FOR UPDATE USING (
        auth.uid()::text = rider_id::text
        OR EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

-- subscriptions table
ALTER TABLE IF EXISTS public.subscriptions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'subscriptions_select_policy') THEN
    CREATE POLICY subscriptions_select_policy ON public.subscriptions
      FOR SELECT USING (
        auth.uid()::text = customer_id::text
        OR EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'subscriptions_insert_customer') THEN
    CREATE POLICY subscriptions_insert_customer ON public.subscriptions
      FOR INSERT WITH CHECK (auth.uid()::text = customer_id::text);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'subscriptions_update_customer') THEN
    CREATE POLICY subscriptions_update_customer ON public.subscriptions
      FOR UPDATE USING (auth.uid()::text = customer_id::text);
  END IF;
END $$;

-- rider_locations table (if exists)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rider_locations') THEN
    EXECUTE 'ALTER TABLE public.rider_locations ENABLE ROW LEVEL SECURITY';
  END IF;
END $$;

-- menu_items table
ALTER TABLE IF EXISTS public.menu_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'menu_items_select_all') THEN
    CREATE POLICY menu_items_select_all ON public.menu_items
      FOR SELECT USING (auth.role() = 'authenticated');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'menu_items' AND policyname = 'menu_items_admin_write') THEN
    CREATE POLICY menu_items_admin_write ON public.menu_items
      FOR ALL USING (
        EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

-- admins table
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'admins' AND policyname = 'admins_select_own') THEN
    CREATE POLICY admins_select_own ON public.admins
      FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

-- riders table
ALTER TABLE IF EXISTS public.riders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'riders' AND policyname = 'riders_select_policy') THEN
    CREATE POLICY riders_select_policy ON public.riders
      FOR SELECT USING (
        id::text = auth.uid()::text
        OR EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'riders' AND policyname = 'riders_update_own') THEN
    CREATE POLICY riders_update_own ON public.riders
      FOR UPDATE USING (
        id::text = auth.uid()::text
        OR EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'riders' AND policyname = 'riders_admin_insert') THEN
    CREATE POLICY riders_admin_insert ON public.riders
      FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.admins WHERE id::text = auth.uid()::text)
      );
  END IF;
END $$;
