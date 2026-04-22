-- Make subscriptions accessible regardless of role.
--
-- Why this exists:
-- - The user flow writes to public.subscriptions and immediately selects the
--   inserted row.
-- - Later RLS migrations added role-based subscription policies, including an
--   admin lookup, but subscriptions should not depend on role at all.
-- - This migration restores role-agnostic access for subscriptions only.

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
