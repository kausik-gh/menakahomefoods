-- Restore admin insert access for tomorrow-order generation.
-- The admin dashboard inserts customer-owned subscription orders directly into
-- public.orders, so the INSERT policy must allow recognized admins in
-- addition to self-service customer inserts.

ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS orders_insert_customer ON public.orders;

CREATE POLICY orders_insert_customer ON public.orders
  FOR INSERT
  TO public
  WITH CHECK (
    customer_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );
