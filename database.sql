
-- BANCO DE DADOS SARA NEVES

create table public.appointments (
  id uuid primary key default gen_random_uuid(),

  customer_name text not null,
  customer_phone text not null,

  service text not null,
  appointment_date date not null,
  appointment_time time not null,

  status text not null default 'pending'
    check (status in (
      'pending',
      'awaiting_payment',
      'confirmed',
      'cancelled'
    )),

  created_at timestamptz not null default now()
);

-- Ativar segurança por linha
alter table public.appointments
enable row level security;

-- Clientes podem solicitar agendamentos
create policy "Clientes podem solicitar agendamento"
on public.appointments
for insert
to anon, authenticated
with check (
  status = 'pending'
  and length(customer_name) between 2 and 100
  and length(customer_phone) between 8 and 20
  and length(service) between 2 and 100
);

-- Tabela de administradores
create table public.admin_users (
  user_id uuid primary key references auth.users(id)
);

alter table public.admin_users
enable row level security;

-- Cada administrador pode consultar seu próprio cadastro
create policy "Administrador consulta seu cadastro"
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());

-- Administradores podem visualizar agendamentos
create policy "Administradores visualizam agendamentos"
on public.appointments
for select
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where admin_users.user_id = auth.uid()
  )
);

-- Administradores podem atualizar agendamentos
create policy "Administradores atualizam agendamentos"
on public.appointments
for update
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where admin_users.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.admin_users
    where admin_users.user_id = auth.uid()
  )
);
