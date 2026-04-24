-- Normalize admin access policies on public.orders.
-- The live database contains a manually-created policy:
--   auth.role() = 'admin'
-- That is incorrect for this app because Supabase auth.role() returns
-- database roles like 'authenticated', while application admin state is stored
-- in public.users and exposed through public.current_user_is_admin().

ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin full access on orders" ON public.orders;

CREATE POLICY "Admin full access on orders" ON public.orders
  FOR ALL
  TO public
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());

DROP POLICY IF EXISTS orders_insert_customer ON public.orders;

CREATE POLICY orders_insert_customer ON public.orders
  FOR INSERT
  TO public
  WITH CHECK (
    customer_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );
