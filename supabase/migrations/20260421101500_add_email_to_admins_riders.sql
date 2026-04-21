-- Fix role lookup queries that filter by email in Flutter app.
-- Adds email columns required by:
-- - from('admins').eq('email', ...)
-- - from('riders').eq('email', ...)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'admins'
      AND column_name = 'email'
  ) THEN
    ALTER TABLE public.admins ADD COLUMN email TEXT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'riders'
      AND column_name = 'email'
  ) THEN
    ALTER TABLE public.riders ADD COLUMN email TEXT;
  END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_admins_email
  ON public.admins (email)
  WHERE email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_riders_email
  ON public.riders (email)
  WHERE email IS NOT NULL;
