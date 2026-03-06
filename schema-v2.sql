-- =============================================
-- INTERACTIO v2 — Schéma complet
-- Supabase → SQL Editor → Coller et exécuter
-- =============================================

-- Nettoyage complet (repart de zéro)
drop table if exists responses cascade;
drop table if exists sessions cascade;
drop table if exists interactions cascade;
drop table if exists animators cascade;
drop table if exists profiles cascade;

-- =============================================
-- 1. ANIMATEURS (identification par PIN)
-- =============================================
create table animators (
  id              uuid        primary key default gen_random_uuid(),
  pin_hash        text        unique not null,
  pin_hint        text,
  failed_attempts int         default 0,
  locked_until    timestamptz,
  created_at      timestamptz default now(),
  last_seen_at    timestamptz default now()
);

-- =============================================
-- 2. INTERACTIONS
-- =============================================
create table interactions (
  id          uuid        primary key default gen_random_uuid(),
  animator_id uuid        references animators(id) on delete set null,
  code        text        unique not null,
  title       text        not null,
  type        text        not null check (type in ('poll','brainstorm','quiz','wordcloud')),
  content     jsonb       not null default '{}',
  options     jsonb       not null default '{}',
  created_at  timestamptz default now()
);

-- =============================================
-- 3. SESSIONS
-- (une même interaction peut être lancée N fois)
-- =============================================
create table sessions (
  id             uuid        primary key default gen_random_uuid(),
  interaction_id uuid        not null references interactions(id) on delete cascade,
  started_at     timestamptz default now(),
  ended_at       timestamptz,
  is_active      boolean     default true
);

-- =============================================
-- 4. RÉPONSES (toujours anonymes)
-- =============================================
create table responses (
  id                uuid        primary key default gen_random_uuid(),
  session_id        uuid        not null references sessions(id) on delete cascade,
  interaction_id    uuid        not null references interactions(id) on delete cascade,
  participant_token text        not null,
  answer            jsonb       not null,
  created_at        timestamptz default now()
);

-- =============================================
-- INDEX
-- =============================================
create index idx_animators_pin         on animators(pin_hash);
create index idx_interactions_code     on interactions(code);
create index idx_interactions_animator on interactions(animator_id);
create index idx_sessions_interaction  on sessions(interaction_id);
create index idx_responses_session     on responses(session_id);
create index idx_responses_interaction on responses(interaction_id);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================
alter table animators    enable row level security;
alter table interactions enable row level security;
alter table sessions     enable row level security;
alter table responses    enable row level security;

-- Animators
create policy "animators_insert" on animators for insert with check (true);
create policy "animators_select" on animators for select using (true);
create policy "animators_update" on animators for update using (true);

-- Interactions
create policy "interactions_select" on interactions for select using (true);
create policy "interactions_insert" on interactions for insert with check (true);
create policy "interactions_update" on interactions for update using (true);
create policy "interactions_delete" on interactions for delete using (true);

-- Sessions
create policy "sessions_select" on sessions for select using (true);
create policy "sessions_insert" on sessions for insert with check (true);
create policy "sessions_update" on sessions for update using (true);

-- Réponses
create policy "responses_select" on responses for select using (true);
create policy "responses_insert" on responses for insert with check (true);

-- =============================================
-- REALTIME
-- =============================================
alter publication supabase_realtime add table responses;
alter publication supabase_realtime add table sessions;
