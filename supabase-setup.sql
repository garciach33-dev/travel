-- ============================================================
--  旅行規劃與紀錄工具 — Supabase 資料庫設定（共用空間 / 端對端加密）
--  用法：Supabase 後台 → 左側 SQL Editor → New query
--        把整份貼上 → 按 Run。跑一次就好。
-- ============================================================

create extension if not exists pgcrypto;

-- 說明：一列 = 一個共用空間，內含該空間的所有旅程。
-- 內容在瀏覽器裡就用 AES-GCM 加密過了，
-- 這個資料庫（包含你這個專案的管理者）只看得到密文，讀不到內容。

-- ---------- 資料表 ----------
create table if not exists public.trips (
  code       text primary key,          -- 共用空間名稱（4～24 英數字）
  pass_hash  text not null,             -- 驗證 token 的 bcrypt 雜湊（真正的密碼從未離開瀏覽器）
  data       jsonb not null,            -- 加密後的整個工作區：{"e":1,"iv":"...","ct":"..."}
  rev        bigint not null default 1, -- 版本號，用來偵測多人同時修改
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 開啟 RLS 且「不」建立任何 policy
-- → 任何人拿 anon key 都無法直接讀寫這張表，只能走下面的函式
alter table public.trips enable row level security;

-- ---------- 建立行程 ----------
create or replace function public.trip_create(p_code text, p_pass text, p_data jsonb)
returns bigint
language plpgsql security definer set search_path = public as $$
begin
  -- p_pass 收到的是瀏覽器算好的驗證 token（不是使用者的密碼），密碼長度由前端把關
  if p_code is null or length(p_code) < 4 or length(p_code) > 24 then
    raise exception '空間名稱長度需為 4～24 字元';
  end if;
  insert into public.trips(code, pass_hash, data, rev)
  values (upper(p_code), crypt(p_pass, gen_salt('bf')), p_data, 1);
  return 1;
end $$;

-- ---------- 讀取行程 ----------
create or replace function public.trip_load(p_code text, p_pass text)
returns table(data jsonb, rev bigint, updated_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  return query
    select t.data, t.rev, t.updated_at
      from public.trips t
     where t.code = upper(p_code)
       and t.pass_hash = crypt(p_pass, t.pass_hash);
end $$;

-- ---------- 儲存行程（樂觀鎖）----------
-- p_rev = 本機拿到的版本號；若雲端已被別人改過會回傳 conflict = true
-- p_rev = -1 代表強制覆蓋
create or replace function public.trip_save(p_code text, p_pass text, p_data jsonb, p_rev bigint)
returns table(rev bigint, conflict boolean)
language plpgsql security definer set search_path = public as $$
declare cur bigint;
begin
  select t.rev into cur
    from public.trips t
   where t.code = upper(p_code)
     and t.pass_hash = crypt(p_pass, t.pass_hash);

  if cur is null then
    raise exception '空間名稱或密碼不正確';
  end if;

  if p_rev >= 0 and cur <> p_rev then
    return query select cur, true;
    return;
  end if;

  update public.trips
     set data = p_data,
         rev = cur + 1,
         updated_at = now()
   where code = upper(p_code);

  return query select cur + 1, false;
end $$;

-- ---------- 變更密碼 ----------
-- 內容用新密碼重新加密後整份換掉，同時換掉驗證 token
create or replace function public.trip_repass(p_code text, p_pass text, p_new_pass text, p_data jsonb)
returns bigint
language plpgsql security definer set search_path = public as $$
declare cur bigint;
begin
  select t.rev into cur
    from public.trips t
   where t.code = upper(p_code)
     and t.pass_hash = crypt(p_pass, t.pass_hash);

  if cur is null then
    raise exception '空間名稱或密碼不正確';
  end if;

  update public.trips
     set pass_hash = crypt(p_new_pass, gen_salt('bf')),
         data = p_data,
         rev = cur + 1,
         updated_at = now()
   where code = upper(p_code);

  return cur + 1;
end $$;

-- ---------- 刪除行程 ----------
create or replace function public.trip_delete(p_code text, p_pass text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.trips
   where code = upper(p_code)
     and pass_hash = crypt(p_pass, pass_hash);
end $$;

-- ---------- 權限：只開放這四個函式 ----------
revoke all on table public.trips from anon, authenticated, public;

revoke all on function public.trip_create(text, text, jsonb) from public;
revoke all on function public.trip_load(text, text) from public;
revoke all on function public.trip_save(text, text, jsonb, bigint) from public;
revoke all on function public.trip_repass(text, text, text, jsonb) from public;
revoke all on function public.trip_delete(text, text) from public;

grant execute on function public.trip_create(text, text, jsonb) to anon, authenticated;
grant execute on function public.trip_load(text, text) to anon, authenticated;
grant execute on function public.trip_save(text, text, jsonb, bigint) to anon, authenticated;
grant execute on function public.trip_repass(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.trip_delete(text, text) to anon, authenticated;

-- ============================================================
--  完成。回到 Settings → API 複製 Project URL 與 anon key，
--  貼進 index.html 開頭的 SUPA_URL / SUPA_KEY。
-- ============================================================
