-- Fix infinite recursion in admins RLS policies.
-- Root cause:
-- - policies queried public.admins from inside public.admins policy evaluation
-- - that re-entered admins RLS and caused infinite recursion
--
-- This migration replaces recursive EXISTS(...) checks with a SECURITY DEFINER
-- helper that evaluates admin membership by authenticated email + role.

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      AND lower(trim(role)) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated;

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
    lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    AND lower(trim(role)) = 'admin'
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
