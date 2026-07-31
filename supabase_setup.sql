-- =============================================
-- PKB (Photo Keyboard) Supabase Schema Setup
-- 新規プロジェクトを構築するための冪等なスクリプト。
-- 既に稼働中のプロジェクトには supabase_migration_001_security.sql を適用すること。
-- =============================================

-- 1. photos テーブル
CREATE TABLE IF NOT EXISTS public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  image_height INT NOT NULL,
  image_width INT NOT NULL,
  image_url TEXT NOT NULL DEFAULT '',
  genre TEXT NOT NULL,
  total_save_count INT NOT NULL DEFAULT 0,
  weekly_save_count INT NOT NULL DEFAULT 0,
  -- クライアントとサーバで書式が食い違わないよう、値の生成はDB側に統一する
  week_start_day TEXT NOT NULL DEFAULT to_char(date_trunc('week', now()), 'YYYY-MM-DD'),
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  locale TEXT NOT NULL DEFAULT 'JP' CHECK (locale IN ('JP', 'WORLD')),
  is_debug BOOLEAN NOT NULL DEFAULT false,
  -- 通報が閾値に達したコンテンツを全ユーザーから隠すためのフラグ
  is_hidden BOOLEAN NOT NULL DEFAULT false,
  report_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. reports テーブル
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_id TEXT NOT NULL,
  content_id UUID REFERENCES public.photos(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- 同一ユーザーによる通報の連投を防ぐ
  UNIQUE (user_id, content_id)
);

-- 3. app_config テーブル (RemoteConfig代替)
CREATE TABLE IF NOT EXISTS public.app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 初期データ
INSERT INTO public.app_config (key, value) VALUES
  ('must_update_ver', '1.0.0'),
  ('must_update_message', 'アップデートしてください')
ON CONFLICT (key) DO NOTHING;

-- 4. インデックス
CREATE INDEX IF NOT EXISTS idx_photos_locale_debug ON public.photos (locale, is_debug);
CREATE INDEX IF NOT EXISTS idx_photos_created_at ON public.photos (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_photos_genre ON public.photos (genre);
-- 先頭カラムを範囲検索にすると並び替えに使えないため、絞り込み条件を前に置く
CREATE INDEX IF NOT EXISTS idx_photos_weekly
  ON public.photos (locale, is_debug, updated_at, weekly_save_count DESC);

-- 5. updated_at の自動更新
-- クライアント任せにすると送り忘れ・改竄が可能で、「人気」タブの絞り込みを直接左右してしまう
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS photos_set_updated_at ON public.photos;
CREATE TRIGGER photos_set_updated_at
  BEFORE UPDATE ON public.photos
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 6. save count の加減算 (RPC)
-- クライアントが読んで計算して書き戻すと同時保存で更新が失われ、任意の値も書けてしまう。
-- UPDATE 権限はクライアントに与えず、この関数経由でのみ増減させる。
CREATE OR REPLACE FUNCTION public.change_save_count(photo_id UUID, delta INT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_start_day TEXT := to_char(date_trunc('week', now()), 'YYYY-MM-DD');
BEGIN
  IF delta NOT IN (-1, 1) THEN
    RAISE EXCEPTION 'delta must be -1 or 1';
  END IF;

  UPDATE public.photos
  SET total_save_count = GREATEST(0, total_save_count + delta),
      weekly_save_count = GREATEST(0,
        CASE WHEN week_start_day IS DISTINCT FROM current_start_day THEN 0 ELSE weekly_save_count END + delta),
      week_start_day = current_start_day
  WHERE id = photo_id;
END;
$$;

-- Supabase は public スキーマの新規関数に anon への EXECUTE を既定で付与するため、
-- FROM PUBLIC の REVOKE だけでは未認証ユーザーが呼べてしまう。anon から明示的に剥奪する。
REVOKE ALL ON FUNCTION public.change_save_count(UUID, INT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.change_save_count(UUID, INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.change_save_count(UUID, INT) TO authenticated;

-- 7. 通報の集計と自動非表示
CREATE OR REPLACE FUNCTION public.apply_report()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.photos
  SET report_count = report_count + 1,
      is_hidden = (report_count + 1) >= 3
  WHERE id = NEW.content_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reports_apply_report ON public.reports;
CREATE TRIGGER reports_apply_report
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.apply_report();

-- 8. RLS (Row Level Security)
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- photos: 非表示にされていないものは全員読み取り可
DROP POLICY IF EXISTS "photos_select" ON public.photos;
CREATE POLICY "photos_select" ON public.photos
  FOR SELECT USING (is_hidden = false);

-- photos: 認証ユーザーが自分名義でのみ作成可
DROP POLICY IF EXISTS "photos_insert" ON public.photos;
CREATE POLICY "photos_insert" ON public.photos
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- photos: UPDATE はクライアントに開放しない (save count は change_save_count 経由)
DROP POLICY IF EXISTS "photos_update" ON public.photos;

-- photos: 投稿者のみ削除可 (通報対応・退会時のデータ削除に必要)
DROP POLICY IF EXISTS "photos_delete" ON public.photos;
CREATE POLICY "photos_delete" ON public.photos
  FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);

-- reports: 認証ユーザーが自分名義でのみ作成可
DROP POLICY IF EXISTS "reports_insert" ON public.reports;
CREATE POLICY "reports_insert" ON public.reports
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- app_config: 全員読み取り可
DROP POLICY IF EXISTS "app_config_select" ON public.app_config;
CREATE POLICY "app_config_select" ON public.app_config
  FOR SELECT USING (true);

-- 9. Storage バケット
-- サイズ・MIMEを制限しないとストレージ枯渇や任意ファイルのホスティングに悪用される
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('photos', 'photos', true, 5242880, ARRAY['image/jpeg', 'image/png'])
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage RLS: 全員読み取り可
DROP POLICY IF EXISTS "photos_storage_select" ON storage.objects;
CREATE POLICY "photos_storage_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'photos');

-- Storage RLS: 認証ユーザーが所定のパスへ自分名義でのみアップロード可
DROP POLICY IF EXISTS "photos_storage_insert" ON storage.objects;
CREATE POLICY "photos_storage_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] IN ('JP', 'WORLD')
  );

-- Storage RLS: アップロードした本人のみ更新・削除可
DROP POLICY IF EXISTS "photos_storage_update" ON storage.objects;
CREATE POLICY "photos_storage_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'photos' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'photos' AND owner = auth.uid());

DROP POLICY IF EXISTS "photos_storage_delete" ON storage.objects;
CREATE POLICY "photos_storage_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'photos' AND owner = auth.uid());

-- 10. 匿名認証を有効化するための設定
-- ダッシュボードの Authentication > Providers > Anonymous Sign-Ins で有効化すること。
-- 併せて Auth > Rate Limits と CAPTCHA を設定し、匿名アカウントの大量生成を防ぐこと。

-- 11. トリガー関数は直接呼び出せないが、権限を明示的に絞っておく
REVOKE EXECUTE ON FUNCTION public.apply_report() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;
