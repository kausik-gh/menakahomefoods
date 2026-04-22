ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS picked BOOLEAN NOT NULL DEFAULT false;

UPDATE public.orders
SET picked = true
WHERE rider_id IS NOT NULL
  AND coalesce(picked, false) = false;

DROP POLICY IF EXISTS orders_select_policy ON public.orders;
CREATE POLICY orders_select_policy ON public.orders
  FOR SELECT USING (
    customer_id = public.current_user_row_id()
    OR rider_id = public.current_user_row_id()
    OR public.current_user_is_admin()
    OR (
      picked = false
      AND EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = public.current_user_row_id()
          AND u.role = 'rider'
      )
    )
  );

DROP POLICY IF EXISTS orders_update_policy ON public.orders;
CREATE POLICY orders_update_policy ON public.orders
  FOR UPDATE USING (
    rider_id = public.current_user_row_id()
    OR public.current_user_is_admin()
    OR (
      picked = false
      AND rider_id IS NULL
      AND EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = public.current_user_row_id()
          AND u.role = 'rider'
      )
    )
  )
  WITH CHECK (
    rider_id = public.current_user_row_id()
    OR public.current_user_is_admin()
  );
