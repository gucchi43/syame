-- =============================================
-- PKB (Photo Keyboard) Supabase Schema Setup
-- =============================================

-- 1. photos テーブル
CREATE TABLE public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  image_height INT NOT NULL,
  image_width INT NOT NULL,
  image_url TEXT NOT NULL DEFAULT '',
  genre TEXT NOT NULL,
  total_save_count INT NOT NULL DEFAULT 0,
  weekly_save_count INT NOT NULL DEFAULT 0,
  week_start_day TEXT,
  owner_id UUID REFERENCES auth.users(id),
  locale TEXT NOT NULL DEFAULT 'JP',
  is_debug BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. reports テーブル
CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  owner_id TEXT NOT NULL,
  content_id UUID REFERENCES public.photos(id),
  reason TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. app_config テーブル (RemoteConfig代替)
CREATE TABLE public.app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 初期データ
INSERT INTO public.app_config (key, value) VALUES
  ('must_update_ver', '1.0.0'),
  ('must_update_message', 'アップデートしてください');

-- 4. インデックス
CREATE INDEX idx_photos_locale_debug ON public.photos (locale, is_debug);
CREATE INDEX idx_photos_created_at ON public.photos (created_at DESC);
CREATE INDEX idx_photos_genre ON public.photos (genre);
CREATE INDEX idx_photos_weekly ON public.photos (updated_at, weekly_save_count DESC);

-- 5. RLS (Row Level Security)
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- photos: 全員読み取り可
CREATE POLICY "photos_select" ON public.photos
  FOR SELECT USING (true);

-- photos: 認証ユーザーのみ作成可
CREATE POLICY "photos_insert" ON public.photos
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- photos: 認証ユーザーは誰でも save count を更新可
CREATE POLICY "photos_update" ON public.photos
  FOR UPDATE USING (true)
  WITH CHECK (true);

-- reports: 認証ユーザーのみ作成可
CREATE POLICY "reports_insert" ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- app_config: 全員読み取り可
CREATE POLICY "app_config_select" ON public.app_config
  FOR SELECT USING (true);

-- 6. Storage バケット
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true);

-- Storage RLS: 全員読み取り可
CREATE POLICY "photos_storage_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'photos');

-- Storage RLS: 認証ユーザーのみアップロード可
CREATE POLICY "photos_storage_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'photos' AND auth.role() = 'authenticated');

-- 7. 匿名認証を有効化するための設定
-- ※ ダッシュボードの Authentication > Providers > Anonymous Sign-Ins で有効化してください
