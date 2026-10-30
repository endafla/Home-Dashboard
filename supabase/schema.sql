-- Home Board: Supabase schema
-- Every row belongs to a household. Only signed-in members of that household can read or write it.

create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table household_members (
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  primary key (household_id, user_id)
);

create or replace function is_member(h uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from household_members where household_id = h and user_id = auth.uid())
$$;

-- Baby
create table feeds (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  kind text not null check (kind in ('left','right','bottle')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  ml int check (ml is null or ml between 1 and 500),
  logged_by uuid default auth.uid()
);
create table nappies (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  kind text not null check (kind in ('wet','dirty','both')),
  at timestamptz not null default now(),
  logged_by uuid default auth.uid()
);
create table sleeps (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  logged_by uuid default auth.uid()
);
create table medicines (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  interval_hours numeric not null check (interval_hours > 0),
  note text,
  active boolean not null default true
);
create table doses (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  medicine_id uuid not null references medicines(id) on delete cascade,
  at timestamptz not null default now(),
  logged_by uuid default auth.uid()
);
create table temperatures (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  celsius numeric(3,1) not null check (celsius between 30 and 45),
  at timestamptz not null default now()
);
create table growth (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  measured_on date not null,
  weight_kg numeric(5,3),
  length_cm numeric(4,1),
  head_cm numeric(4,1)
);
create table appointments (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  kind text not null check (kind in ('phn','gp','vaccine','hospital','other')),
  title text not null,
  on_date date not null,
  at_time time,
  done boolean not null default false
);

-- Dinner planner: one evening meal per day
create table dinners (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  on_date date not null,
  meal text not null,
  note text,
  ingredients text,
  unique (household_id, on_date)
);

-- Lists: shopping, todos, questions for nurse/GP
create table list_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  list text not null check (list in ('shopping','todos','questions')),
  text text not null,
  assignee uuid references auth.users(id),
  done boolean not null default false,
  created_at timestamptz not null default now()
);

-- Household reminders: dog, home, car
create table reminders (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  category text not null check (category in ('dog','home','car')),
  title text not null,
  due_on date not null,
  repeat_days int not null default 0
);

-- Bins: one row per bin type; dates are computed from anchor + interval
create table bins (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  name text not null,
  colour text not null,
  anchor_date date not null,
  every_weeks int not null default 2 check (every_weeks between 1 and 8)
);

-- Money: names, dates and optional amounts only. No account details.
create table bills (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  category text not null check (category in ('dd','renewal','annual','sub')),
  title text not null,
  due_on date not null,
  repeats text not null default 'monthly' check (repeats in ('monthly','yearly','none')),
  amount numeric(10,2)
);

-- Row level security: members only, on every table
do $$
declare t text;
begin
  foreach t in array array['feeds','nappies','sleeps','medicines','doses','temperatures','growth',
                           'appointments','list_items','reminders','bins','bills','dinners'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "members read" on %I for select using (is_member(household_id))', t);
    execute format('create policy "members write" on %I for all using (is_member(household_id)) with check (is_member(household_id))', t);
    execute format('create index on %I (household_id)', t);
  end loop;
end $$;

alter table households enable row level security;
create policy "members read household" on households for select using (is_member(id));
alter table household_members enable row level security;
create policy "members read members" on household_members for select using (is_member(household_id));

-- Live sync to tablet and phones
alter publication supabase_realtime add table feeds, nappies, sleeps, doses, list_items, dinners;
