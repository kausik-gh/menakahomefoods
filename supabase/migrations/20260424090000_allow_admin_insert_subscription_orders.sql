-- Allow admins to insert customer orders while preserving customer self-insert.
-- This is required for the admin-triggered tomorrow-order generation flow.

DROP POLICY IF EXISTS orders_insert_customer ON public.orders;

CREATE POLICY orders_insert_customer ON public.orders
  FOR INSERT
  WITH CHECK (
    customer_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );
