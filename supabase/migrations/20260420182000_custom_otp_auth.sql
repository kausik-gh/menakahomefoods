-- Custom OTP authentication support
-- Replaces Supabase email OTP flow with app-managed OTP verification.

CREATE TABLE IF NOT EXISTS public.otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verified BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_otp_codes_email_created_at
  ON public.otp_codes (email, created_at DESC);

ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'otp_codes'
      AND policyname = 'otp_codes_service_role_only'
  ) THEN
    CREATE POLICY otp_codes_service_role_only
      ON public.otp_codes
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'customers'
      AND column_name = 'email'
  ) THEN
    ALTER TABLE public.customers ADD COLUMN email TEXT;
  END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_email
  ON public.customers (email)
  WHERE email IS NOT NULL;

CREATE OR REPLACE FUNCTION public.auth_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM auth.users u
    WHERE lower(u.email) = lower(p_email)
  );
$$;

REVOKE ALL ON FUNCTION public.auth_user_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_user_exists(TEXT) TO service_role;
