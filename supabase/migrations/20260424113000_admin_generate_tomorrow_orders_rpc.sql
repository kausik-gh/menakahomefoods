-- Server-side admin RPC for generating tomorrow subscription orders.
-- This avoids client-side inserts that depend on the live orders/subscriptions RLS state.

CREATE OR REPLACE FUNCTION public.admin_generate_tomorrow_subscription_orders()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_date DATE := (timezone('Asia/Kolkata', now()))::date + 1;
  v_day_key TEXT := public.subscription_day_key((timezone('Asia/Kolkata', now()))::date + 1);
  v_inserted_count INTEGER := 0;
  v_existing_count INTEGER := 0;
  v_missing_menu_item_count INTEGER := 0;
  v_considered_subscription_count INTEGER := 0;
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Only admins can generate tomorrow orders.';
  END IF;

  SELECT count(*)
  INTO v_considered_subscription_count
  FROM public.subscriptions s
  WHERE s.status = 'active'
    AND v_target_date BETWEEN s.start_date AND s.end_date;

  WITH planned AS (
    SELECT
      s.customer_id,
      s.customer_name,
      s.customer_phone,
      meal_plan.meal AS meal,
      NULLIF(btrim(s.weekly_plan -> v_day_key ->> meal_plan.meal), '') AS menu_item_id
    FROM public.subscriptions s
    CROSS JOIN LATERAL unnest(s.meals) AS meal_plan(meal)
    WHERE s.status = 'active'
      AND v_target_date BETWEEN s.start_date AND s.end_date
      AND meal_plan.meal IN ('breakfast', 'lunch', 'dinner', 'snacks', 'beverages')
  ),
  existing AS (
    SELECT p.*
    FROM planned p
    JOIN public.orders o
      ON o.order_type = 'subscription'
     AND o.order_date = v_target_date
     AND o.customer_id = p.customer_id
     AND o.meal::text = p.meal
  ),
  missing_menu_item AS (
    SELECT p.*
    FROM planned p
    LEFT JOIN public.menu_items mi
      ON mi.id::text = p.menu_item_id
    WHERE p.menu_item_id IS NULL
       OR mi.id IS NULL
  ),
  insert_rows AS (
    SELECT
      p.customer_id,
      p.customer_name,
      p.customer_phone,
      p.meal,
      mi.id AS menu_item_id,
      mi.name AS menu_item_name,
      coalesce(mi.price, 0) AS menu_item_price
    FROM planned p
    JOIN public.menu_items mi
      ON mi.id::text = p.menu_item_id
    LEFT JOIN public.orders o
      ON o.order_type = 'subscription'
     AND o.order_date = v_target_date
     AND o.customer_id = p.customer_id
     AND o.meal::text = p.meal
    WHERE o.id IS NULL
  )
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
    order_date
  )
  SELECT
    i.customer_id,
    i.customer_name,
    i.customer_phone,
    '',
    jsonb_build_array(
      jsonb_build_object(
        'dish_id', i.menu_item_id,
        'name', i.menu_item_name,
        'price', i.menu_item_price,
        'quantity', 1,
        'qty', 1
      )
    ),
    'subscription',
    i.meal::public.meal_type,
    'placed'::public.order_status,
    false,
    i.menu_item_price,
    0,
    0,
    i.menu_item_price,
    v_target_date
  FROM insert_rows i;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

  WITH planned AS (
    SELECT
      s.customer_id,
      meal_plan.meal AS meal,
      NULLIF(btrim(s.weekly_plan -> v_day_key ->> meal_plan.meal), '') AS menu_item_id
    FROM public.subscriptions s
    CROSS JOIN LATERAL unnest(s.meals) AS meal_plan(meal)
    WHERE s.status = 'active'
      AND v_target_date BETWEEN s.start_date AND s.end_date
      AND meal_plan.meal IN ('breakfast', 'lunch', 'dinner', 'snacks', 'beverages')
  )
  SELECT count(*)
  INTO v_existing_count
  FROM planned p
  JOIN public.orders o
    ON o.order_type = 'subscription'
   AND o.order_date = v_target_date
   AND o.customer_id = p.customer_id
   AND o.meal::text = p.meal;

  WITH planned AS (
    SELECT
      NULLIF(btrim(s.weekly_plan -> v_day_key ->> meal_plan.meal), '') AS menu_item_id
    FROM public.subscriptions s
    CROSS JOIN LATERAL unnest(s.meals) AS meal_plan(meal)
    WHERE s.status = 'active'
      AND v_target_date BETWEEN s.start_date AND s.end_date
      AND meal_plan.meal IN ('breakfast', 'lunch', 'dinner', 'snacks', 'beverages')
  )
  SELECT count(*)
  INTO v_missing_menu_item_count
  FROM planned p
  LEFT JOIN public.menu_items mi
    ON mi.id::text = p.menu_item_id
  WHERE p.menu_item_id IS NULL
     OR mi.id IS NULL;

  RETURN jsonb_build_object(
    'target_date', v_target_date,
    'inserted_count', v_inserted_count,
    'existing_count', greatest(v_existing_count - v_inserted_count, 0),
    'missing_menu_item_count', v_missing_menu_item_count,
    'considered_subscription_count', v_considered_subscription_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_generate_tomorrow_subscription_orders() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_generate_tomorrow_subscription_orders() TO authenticated;
