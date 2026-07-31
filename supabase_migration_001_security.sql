-- =============================================
-- 稼働中の Supabase プロジェクトに適用するマイグレーション
-- 目的: 全開放されている photos_update ポリシーの撤廃と、モデレーション基盤の追加
-- 適用手順: Supabase ダッシュボードの SQL Editor に貼り付けて実行
-- =============================================

-- 1. 列の追加
ALTER TABLE public.photos ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.photos ADD COLUMN IF NOT EXISTS report_count INT NOT NULL DEFAULT 0;

ALTER TABLE public.photos
  ALTER COLUMN week_start_day SET DEFAULT to_char(date_trunc('week', now()), 'YYYY-MM-DD');
UPDATE public.photos
  SET week_start_day = to_char(date_trunc('week', now()), 'YYYY-MM-DD')
  WHERE week_start_day IS NULL;
ALTER TABLE public.photos ALTER COLUMN week_start_day SET NOT NULL;

-- 2. 外部キーに削除時の挙動を追加 (退会・モデレーション削除が詰まるため)
ALTER TABLE public.photos DROP CONSTRAINT IF EXISTS photos_owner_id_fkey;
ALTER TABLE public.photos
  ADD CONSTRAINT photos_owner_id_fkey
  FOREIGN KEY (owner_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_user_id_fkey;
ALTER TABLE public.reports
  ADD CONSTRAINT reports_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_content_id_fkey;
ALTER TABLE public.reports
  ADD CONSTRAINT reports_content_id_fkey
  FOREIGN KEY (content_id) REFERENCES public.photos(id) ON DELETE CASCADE;

-- 通報の連投防止 (既存の重複は先に削除する)
DELETE FROM public.reports a
  USING public.reports b
  WHERE a.ctid < b.ctid
    AND a.user_id = b.user_id
    AND a.content_id = b.content_id;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_user_id_content_id_key;
ALTER TABLE public.reports ADD CONSTRAINT reports_user_id_content_id_key UNIQUE (user_id, content_id);

-- 3. updated_at の自動更新
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

-- 4. save count の加減算関数
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

-- 5. 通報の集計と自動非表示
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

-- 6. ポリシーの張り替え
-- 誰でも全レコードを書き換えられる状態だったため撤廃する
DROP POLICY IF EXISTS "photos_update" ON public.photos;

DROP POLICY IF EXISTS "photos_select" ON public.photos;
CREATE POLICY "photos_select" ON public.photos
  FOR SELECT USING (is_hidden = false);

DROP POLICY IF EXISTS "photos_insert" ON public.photos;
CREATE POLICY "photos_insert" ON public.photos
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "photos_delete" ON public.photos;
CREATE POLICY "photos_delete" ON public.photos
  FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "reports_insert" ON public.reports;
CREATE POLICY "reports_insert" ON public.reports
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 7. Storage の制限
UPDATE storage.buckets
  SET file_size_limit = 5242880,
      allowed_mime_types = ARRAY['image/jpeg', 'image/png']
  WHERE id = 'photos';

DROP POLICY IF EXISTS "photos_storage_insert" ON storage.objects;
CREATE POLICY "photos_storage_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] IN ('JP', 'WORLD')
  );

DROP POLICY IF EXISTS "photos_storage_update" ON storage.objects;
CREATE POLICY "photos_storage_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'photos' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'photos' AND owner = auth.uid());

DROP POLICY IF EXISTS "photos_storage_delete" ON storage.objects;
CREATE POLICY "photos_storage_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'photos' AND owner = auth.uid());

-- 8. トリガー関数は直接呼び出せないが、権限を明示的に絞っておく
REVOKE EXECUTE ON FUNCTION public.apply_report() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;
