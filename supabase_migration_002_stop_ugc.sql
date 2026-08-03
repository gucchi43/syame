-- 一般ユーザーによる公開投稿(UGC)の停止
--
-- クライアント側(AddViewController)でも投稿を止めているが、
-- 既に配信済みの古いバージョンからは引き続き投稿できてしまうため、
-- サーバ側でも INSERT を封じる。
--
-- 既存データ(photos テーブルと Storage の画像)は削除しない。
-- 将来、審査済みコンテンツの陳列棚として転用する想定のため残置する。
--
-- 適用対象: 稼働中の Supabase プロジェクト
-- 前提: supabase_migration_001_security.sql が適用済みであること

-- 1. photos への INSERT を全面的に停止する
--    ポリシー自体を落とすことで、RLS 有効下では誰も INSERT できなくなる
DROP POLICY IF EXISTS "photos_insert" ON public.photos;

-- 2. Storage への画像アップロードを停止する
--    更新も同時に止める。削除は残す(既存の後始末をできるようにするため)
DROP POLICY IF EXISTS "photos_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "photos_storage_update" ON storage.objects;

-- 3. 保存数の増減 RPC を停止する
--    save 機能はフィード撤去とともに無くなるため、呼び出し元が消える
REVOKE EXECUTE ON FUNCTION public.change_save_count(UUID, INT) FROM PUBLIC, anon, authenticated;

-- 注意:
-- reports_insert は残している。通報機能を撤去するかどうかは未決のため
-- (TODO.md 論点3)。撤去を決めたら以下を実行する。
--   DROP POLICY IF EXISTS "reports_insert" ON public.reports;
--
-- photos_select は残す。フィードを畳んだ後もアプリからは参照しないが、
-- 既存の配信済みバージョンが読み取りに失敗して不安定になるのを避けるため。

-- 適用後の確認用クエリ
--   SELECT policyname, cmd FROM pg_policies
--    WHERE schemaname = 'public' AND tablename = 'photos';
--   -- photos_insert が消えていること
--
--   SELECT policyname, cmd FROM pg_policies
--    WHERE schemaname = 'storage' AND tablename = 'objects';
--   -- photos_storage_insert / photos_storage_update が消えていること
