-- Admin role lookup RPC for Flutter client.
-- Uses SECURITY DEFINER so the app can verify admin status by email even when
-- admins.id does not match auth.uid() and RLS blocks direct table reads.

CREATE OR REPLACE FUNCTION public.is_admin_email(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admins
    WHERE lower(email) = lower(trim(coalesce(p_email, '')))
      AND lower(trim(role)) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_email(TEXT) TO authenticated;
