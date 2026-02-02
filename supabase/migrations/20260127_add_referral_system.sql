-- Add referral columns to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS referral_code text UNIQUE,
ADD COLUMN IF NOT EXISTS referred_by text,
ADD COLUMN IF NOT EXISTS referral_count bigint DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_active_at timestamptz;

-- Index for faster leaderboard queries
CREATE INDEX IF NOT EXISTS idx_users_referral_count ON public.users(referral_count DESC);
CREATE INDEX IF NOT EXISTS idx_users_points ON public.users(points DESC);

-- Function to increment referral count
CREATE OR REPLACE FUNCTION increment_referral_count(referrer_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET referral_count = referral_count + 1,
      points = points + 50 -- Bonus points for referral
  WHERE referral_code = referrer_code;
END;
$$;

NOTIFY pgrst, 'reload schema';
