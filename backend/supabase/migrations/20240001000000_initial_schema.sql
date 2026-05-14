-- 式神鑑定 初期スキーマ
-- docs/design.md §1.1 および §1.2 準拠

-- ユーザー
-- id は Supabase Auth の auth.users.id をそのまま使い、RLS の auth.uid() と一致させる
create table users (
  id            uuid primary key references auth.users(id) on delete cascade,
  apple_user_id text unique not null,
  birth_date    date,
  gender        text check (gender in ('yin','yang','none')),
  shikigami_id  smallint,
  created_at    timestamptz default now()
);

-- 鑑定履歴
create table fortunes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references users(id) on delete cascade,
  engine      text check (engine in ('seimei','nanboku','palm')),
  topic       text,
  input_hash  text not null,
  prompt      text,
  response    text not null,
  tokens_in   int,
  tokens_out  int,
  created_at  timestamptz default now()
);
create index fortunes_user_created_idx on fortunes (user_id, created_at desc);
create index fortunes_input_hash_idx on fortunes (input_hash);

-- 課金状態（RevenueCat と同期）
create table subscriptions (
  user_id     uuid primary key references users(id) on delete cascade,
  tier        text check (tier in ('free','premium','divine')) default 'free',
  expires_at  timestamptz,
  updated_at  timestamptz default now()
);

-- RLS 有効化
alter table users         enable row level security;
alter table fortunes      enable row level security;
alter table subscriptions enable row level security;

-- users ポリシー
create policy "users_self_read"
  on users for select using (auth.uid() = id);

create policy "users_self_write"
  on users for update using (auth.uid() = id);

create policy "users_self_insert"
  on users for insert with check (auth.uid() = id);

-- fortunes ポリシー（本人のみ全操作可）
create policy "fortunes_self"
  on fortunes for all using (auth.uid() = user_id);

-- subscriptions ポリシー（読み取りのみ。書き込みは service role のみ）
create policy "subscriptions_self_read"
  on subscriptions for select using (auth.uid() = user_id);
