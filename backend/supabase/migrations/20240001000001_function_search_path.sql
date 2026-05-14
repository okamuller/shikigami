-- 当日の鑑定回数を JST 基準で返す関数
-- Edge Function から RPC 呼び出しで使用する
create or replace function public.get_fortune_quota(p_user_id uuid)
returns int
language sql stable security definer
set search_path = public
as $$
  select count(*)::int
  from fortunes
  where user_id = p_user_id
    and created_at >= date_trunc('day', now() at time zone 'Asia/Tokyo') at time zone 'Asia/Tokyo'
    and created_at <  (date_trunc('day', now() at time zone 'Asia/Tokyo') + interval '1 day') at time zone 'Asia/Tokyo';
$$;
