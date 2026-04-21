-- Add rating columns to orders table for post-delivery rating feature
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  ADD COLUMN IF NOT EXISTS rating_comment TEXT,
  ADD COLUMN IF NOT EXISTS rider_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS rider_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS customer_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS customer_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS rider_phone TEXT;
