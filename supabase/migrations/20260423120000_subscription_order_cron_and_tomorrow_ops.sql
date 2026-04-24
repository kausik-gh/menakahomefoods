-- Materialize next-day subscription meals into orders and keep rider counts in sync.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typnamespace = 'public'::regnamespace
      AND typname = 'subscription_status'
  ) THEN
    CREATE TYPE public.subscription_status AS ENUM ('active', 'paused', 'cancelled');
  END IF;
END
$$;

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS status public.subscription_status NOT NULL DEFAULT 'active'::public.subscription_status;

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS order_date DATE NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  ADD COLUMN IF NOT EXISTS source_subscription_id UUID,
  ADD COLUMN IF NOT EXISTS source_menu_item_id UUID,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_orders_order_date ON public.orders(order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_order_type_date ON public.orders(order_type, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_source_subscription ON public.orders(source_subscription_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_subscription_schedule_unique
  ON public.orders(source_subscription_id, order_date, meal)
  WHERE order_type = 'subscription'
    AND source_subscription_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.subscription_day_key(p_date DATE)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT (ARRAY['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'])[extract(dow FROM p_date)::int + 1];
$$;

CREATE OR REPLACE FUNCTION public.refresh_rider_current_orders_count(p_rider_id UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.users u
  SET current_orders_count = (
    SELECT count(*)
    FROM public.orders o
    WHERE o.rider_id = u.id
      AND o.status IN ('confirmed', 'preparing', 'out_for_delivery')
      AND coalesce(o.picked, false) = true
  )
  WHERE u.id = p_rider_id
    AND lower(coalesce(u.role, '')) = 'rider';
$$;

CREATE OR REPLACE FUNCTION public.sync_rider_order_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') AND OLD.rider_id IS NOT NULL THEN
    PERFORM public.refresh_rider_current_orders_count(OLD.rider_id);
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.rider_id IS NOT NULL THEN
    PERFORM public.refresh_rider_current_orders_count(NEW.rider_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS orders_sync_rider_counts ON public.orders;
CREATE TRIGGER orders_sync_rider_counts
  AFTER INSERT OR UPDATE OR DELETE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_rider_order_counts();

DROP INDEX IF EXISTS idx_orders_subscription_schedule_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_subscription_customer_meal_date_unique
  ON public.orders(customer_id, order_date, meal)
  WHERE order_type = 'subscription';

CREATE OR REPLACE FUNCTION public.generate_subscription_orders_for_next_day(
  p_reference_time TIMESTAMPTZ DEFAULT now()
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_date DATE := (timezone('Asia/Kolkata', p_reference_time))::date + 1;
  v_day_key TEXT := public.subscription_day_key((timezone('Asia/Kolkata', p_reference_time))::date + 1);
  v_inserted_count INTEGER := 0;
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Only admins can generate tomorrow orders.';
  END IF;

  INSERT INTO public.orders (
    customer_id,
    customer_name,
    customer_phone,
    customer_address,
    items,
    order_type,
    meal,
    status,
    picked,
    subtotal,
    delivery_fee,
    gst,
    total,
    order_date,
    source_subscription_id,
    source_menu_item_id
  )
  SELECT
    s.customer_id,
    s.customer_name,
    s.customer_phone,
    '',
    jsonb_build_array(
      jsonb_build_object(
        'dish_id', mi.id,
        'name', mi.name,
        'price', mi.price,
        'quantity', 1,
        'qty', 1
      )
    ),
    'subscription',
    meal_plan.meal::public.meal_type,
    'placed'::public.order_status,
    false,
    mi.price,
    0,
    0,
    mi.price,
    v_target_date,
    s.id,
    mi.id
  FROM public.subscriptions s
  CROSS JOIN LATERAL unnest(s.meals) AS meal_plan(meal)
  CROSS JOIN LATERAL (
    SELECT NULLIF(btrim(s.weekly_plan -> v_day_key ->> meal_plan.meal), '')::uuid AS menu_item_id
  ) AS plan_item
  JOIN public.menu_items mi
    ON mi.id = plan_item.menu_item_id
  WHERE s.status = 'active'
    AND v_target_date BETWEEN s.start_date AND s.end_date
    AND meal_plan.meal IN ('breakfast', 'lunch', 'dinner', 'snacks', 'beverages')
  ON CONFLICT DO NOTHING;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
  RETURN v_inserted_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_subscription_orders_for_next_day()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.generate_subscription_orders_for_next_day(now());
$$;

REVOKE ALL ON FUNCTION public.generate_subscription_orders_for_next_day() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.generate_subscription_orders_for_next_day() TO authenticated;
REVOKE ALL ON FUNCTION public.generate_subscription_orders_for_next_day(TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.generate_subscription_orders_for_next_day(TIMESTAMPTZ) TO authenticated;
