-- Make orders role-agnostic to match the current app flow.
-- Tomorrow-order generation now inserts directly from the admin client, and
-- this must not fail because of role-based RLS checks on public.orders.

ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS orders_select_policy ON public.orders;
DROP POLICY IF EXISTS orders_insert_customer ON public.orders;
DROP POLICY IF EXISTS orders_update_policy ON public.orders;
DROP POLICY IF EXISTS "orders_open_access" ON public.orders;

CREATE POLICY "orders_open_access"
ON public.orders
FOR ALL
TO public
USING (true)
WITH CHECK (true);
