-- Unify customers, admins, and riders into public.users.
-- This keeps rider operational fields while moving all role checks to users.role.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'customers'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'users'
  ) THEN
    ALTER TABLE public.customers RENAME TO users;
  END IF;
END
$$;

ALTER TABLE IF EXISTS public.users
  DROP CONSTRAINT IF EXISTS fk_customer_auth;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'auth_id'
  ) THEN
    ALTER TABLE public.users ADD COLUMN auth_id UUID;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'role'
  ) THEN
    ALTER TABLE public.users ADD COLUMN role TEXT DEFAULT 'customer';
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'status'
  ) THEN
    ALTER TABLE public.users ADD COLUMN status TEXT DEFAULT 'inactive';
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'current_orders_count'
  ) THEN
    ALTER TABLE public.users ADD COLUMN current_orders_count INTEGER DEFAULT 0;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'lat'
  ) THEN
    ALTER TABLE public.users ADD COLUMN lat DOUBLE PRECISION;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'lng'
  ) THEN
    ALTER TABLE public.users ADD COLUMN lng DOUBLE PRECISION;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'location_updated_at'
  ) THEN
    ALTER TABLE public.users ADD COLUMN location_updated_at TIMESTAMPTZ;
  END IF;
END
$$;

UPDATE public.users
SET auth_id = id
WHERE auth_id IS NULL;

UPDATE public.users
SET role = 'customer'
WHERE role IS NULL OR btrim(role) = '';

UPDATE public.users
SET status = 'inactive'
WHERE status IS NULL OR btrim(status) = '';

UPDATE public.users
SET current_orders_count = 0
WHERE current_orders_count IS NULL;

ALTER TABLE public.users
  ALTER COLUMN role SET DEFAULT 'customer';

ALTER TABLE public.users
  ALTER COLUMN role SET NOT NULL;

ALTER TABLE public.users
  ALTER COLUMN status SET DEFAULT 'inactive';

ALTER TABLE public.users
  ALTER COLUMN current_orders_count SET DEFAULT 0;

INSERT INTO public.users (
  id,
  auth_id,
  email,
  name,
  phone,
  role,
  status,
  current_orders_count,
  created_at,
  updated_at
)
SELECT
  a.id,
  au.id,
  lower(a.email),
  coalesce(u.name, ''),
  coalesce(u.phone, ''),
  'admin',
  'active',
  0,
  coalesce(a.created_at, now()),
  now()
FROM public.admins a
LEFT JOIN auth.users au
  ON lower(coalesce(au.email, '')) = lower(coalesce(a.email, ''))
LEFT JOIN public.users u
  ON lower(coalesce(u.email, '')) = lower(coalesce(a.email, ''))
WHERE a.email IS NOT NULL
  AND btrim(a.email) <> ''
ON CONFLICT (email) DO UPDATE
SET auth_id = coalesce(EXCLUDED.auth_id, public.users.auth_id),
    role = 'admin',
    status = 'active',
    updated_at = now();

INSERT INTO public.users (
  id,
  auth_id,
  email,
  name,
  phone,
  role,
  status,
  current_orders_count,
  lat,
  lng,
  location_updated_at,
  created_at,
  updated_at
)
SELECT
  r.id,
  coalesce(r.auth_id, au.id),
  lower(r.email),
  coalesce(r.name, ''),
  coalesce(r.phone, ''),
  'rider',
  coalesce(nullif(btrim(r.status), ''), 'inactive'),
  coalesce(r.current_orders_count, 0),
  r.lat,
  r.lng,
  r.location_updated_at,
  coalesce(r.created_at, now()),
  coalesce(r.updated_at, now())
FROM public.riders r
LEFT JOIN auth.users au
  ON lower(coalesce(au.email, '')) = lower(coalesce(r.email, ''))
WHERE r.email IS NOT NULL
  AND btrim(r.email) <> ''
ON CONFLICT (email) DO UPDATE
SET auth_id = coalesce(EXCLUDED.auth_id, public.users.auth_id),
    role = 'rider',
    name = coalesce(EXCLUDED.name, public.users.name),
    phone = coalesce(EXCLUDED.phone, public.users.phone),
    status = coalesce(EXCLUDED.status, public.users.status),
    current_orders_count = coalesce(EXCLUDED.current_orders_count, public.users.current_orders_count),
    lat = coalesce(EXCLUDED.lat, public.users.lat),
    lng = coalesce(EXCLUDED.lng, public.users.lng),
    location_updated_at = coalesce(EXCLUDED.location_updated_at, public.users.location_updated_at),
    updated_at = now();

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_auth_id
  ON public.users (auth_id)
  WHERE auth_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.current_user_row_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT u.id
  FROM public.users u
  WHERE u.auth_id = auth.uid()
     OR lower(coalesce(u.email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  ORDER BY CASE WHEN u.auth_id = auth.uid() THEN 0 ELSE 1 END, u.created_at
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.current_user_row_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_row_id() TO authenticated;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT lower(coalesce(u.role, 'customer'))
  FROM public.users u
  WHERE u.auth_id = auth.uid()
     OR lower(coalesce(u.email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  ORDER BY CASE WHEN u.auth_id = auth.uid() THEN 0 ELSE 1 END, u.created_at
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.current_user_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT coalesce(public.current_user_role(), '') = 'admin';
$$;

REVOKE ALL ON FUNCTION public.current_user_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_admin_email(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE lower(coalesce(email, '')) = lower(btrim(coalesce(p_email, '')))
      AND lower(coalesce(role, '')) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_email(TEXT) TO authenticated;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS customers_select_own ON public.users;
DROP POLICY IF EXISTS customers_update_own ON public.users;
DROP POLICY IF EXISTS customers_insert_own ON public.users;
DROP POLICY IF EXISTS users_select_self_or_admin ON public.users;
DROP POLICY IF EXISTS users_update_self_or_admin ON public.users;
DROP POLICY IF EXISTS users_insert_self_or_admin ON public.users;

CREATE POLICY users_select_self_or_admin ON public.users
  FOR SELECT USING (
    public.current_user_is_admin()
    OR id = public.current_user_row_id()
  );

CREATE POLICY users_update_self_or_admin ON public.users
  FOR UPDATE USING (
    public.current_user_is_admin()
    OR id = public.current_user_row_id()
  )
  WITH CHECK (
    public.current_user_is_admin()
    OR id = public.current_user_row_id()
  );

CREATE POLICY users_insert_self_or_admin ON public.users
  FOR INSERT WITH CHECK (
    public.current_user_is_admin()
    OR auth_id = auth.uid()
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

DROP POLICY IF EXISTS orders_select_policy ON public.orders;
CREATE POLICY orders_select_policy ON public.orders
  FOR SELECT USING (
    customer_id = public.current_user_row_id()
    OR rider_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS orders_insert_customer ON public.orders;
CREATE POLICY orders_insert_customer ON public.orders
  FOR INSERT WITH CHECK (customer_id = public.current_user_row_id());

DROP POLICY IF EXISTS orders_update_policy ON public.orders;
CREATE POLICY orders_update_policy ON public.orders
  FOR UPDATE USING (
    rider_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS menu_items_admin_write ON public.menu_items;
CREATE POLICY menu_items_admin_write ON public.menu_items
  FOR ALL USING (public.current_user_is_admin());

DROP POLICY IF EXISTS "subscriptions_open_access" ON public.subscriptions;
DROP POLICY IF EXISTS subscriptions_select_policy ON public.subscriptions;
DROP POLICY IF EXISTS subscriptions_insert_customer ON public.subscriptions;
DROP POLICY IF EXISTS subscriptions_update_customer ON public.subscriptions;

CREATE POLICY "subscriptions_open_access"
ON public.subscriptions
FOR ALL
TO public
USING (true)
WITH CHECK (true);

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_rider_id_fkey;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_rider_id_fkey
  FOREIGN KEY (rider_id)
  REFERENCES public.users(id)
  ON DELETE SET NULL;

DROP POLICY IF EXISTS admins_select_own ON public.admins;
DROP POLICY IF EXISTS admin_select ON public.admins;
DROP POLICY IF EXISTS order_insert ON public.orders;
DROP POLICY IF EXISTS order_select ON public.orders;
DROP POLICY IF EXISTS order_update ON public.orders;
DROP POLICY IF EXISTS orders_open_access ON public.orders;
DROP POLICY IF EXISTS "riders_open_access" ON public.riders;
DROP POLICY IF EXISTS rider_insert ON public.riders;
DROP POLICY IF EXISTS rider_select ON public.riders;
DROP POLICY IF EXISTS rider_update ON public.riders;
DROP POLICY IF EXISTS riders_select_policy ON public.riders;
DROP POLICY IF EXISTS riders_update_own ON public.riders;
DROP POLICY IF EXISTS riders_admin_insert ON public.riders;

DROP TABLE IF EXISTS public.admins;
DROP TABLE IF EXISTS public.riders;
