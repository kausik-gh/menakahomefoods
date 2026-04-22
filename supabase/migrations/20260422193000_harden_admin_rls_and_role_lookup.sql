-- Harden admin role lookup and remove recursive RLS dependencies.
--
-- Why this exists:
-- - The original RLS policies queried public.admins from inside other RLS
--   policies, including public.admins itself.
-- - That can recurse during subscription inserts that immediately SELECT the
--   inserted row, producing:
--   "infinite recursion detected in policy for relation \"admins\""
-- - Earlier helper functions also assumed public.admins.role existed, but this
--   repository never created that column.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'admins'
      AND column_name = 'email'
  ) THEN
    ALTER TABLE public.admins ADD COLUMN email TEXT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'admins'
      AND column_name = 'role'
  ) THEN
    ALTER TABLE public.admins ADD COLUMN role TEXT;
  END IF;
END
$$;

UPDATE public.admins
SET role = 'admin'
WHERE role IS NULL OR btrim(role) = '';

CREATE UNIQUE INDEX IF NOT EXISTS idx_admins_email
  ON public.admins (email)
  WHERE email IS NOT NULL;

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE lower(coalesce(email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
      AND lower(coalesce(btrim(role), '')) = 'admin'
  );
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
    FROM public.admins
    WHERE lower(coalesce(email, '')) = lower(btrim(coalesce(p_email, '')))
      AND lower(coalesce(btrim(role), '')) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_email(TEXT) TO authenticated;

DROP POLICY IF EXISTS orders_select_policy ON public.orders;
CREATE POLICY orders_select_policy ON public.orders
  FOR SELECT USING (
    auth.uid()::text = customer_id::text
    OR auth.uid()::text = rider_id::text
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS orders_update_policy ON public.orders;
CREATE POLICY orders_update_policy ON public.orders
  FOR UPDATE USING (
    auth.uid()::text = rider_id::text
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS subscriptions_select_policy ON public.subscriptions;
CREATE POLICY subscriptions_select_policy ON public.subscriptions
  FOR SELECT USING (
    auth.uid()::text = customer_id::text
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS menu_items_admin_write ON public.menu_items;
CREATE POLICY menu_items_admin_write ON public.menu_items
  FOR ALL USING (public.current_user_is_admin());

DROP POLICY IF EXISTS admins_select_own ON public.admins;
CREATE POLICY admins_select_own ON public.admins
  FOR SELECT USING (
    lower(coalesce(email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
    AND lower(coalesce(btrim(role), '')) = 'admin'
  );

DROP POLICY IF EXISTS riders_select_policy ON public.riders;
CREATE POLICY riders_select_policy ON public.riders
  FOR SELECT USING (
    id::text = auth.uid()::text
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS riders_update_own ON public.riders;
CREATE POLICY riders_update_own ON public.riders
  FOR UPDATE USING (
    id::text = auth.uid()::text
    OR public.current_user_is_admin()
  );

DROP POLICY IF EXISTS riders_admin_insert ON public.riders;
CREATE POLICY riders_admin_insert ON public.riders
  FOR INSERT WITH CHECK (public.current_user_is_admin());
