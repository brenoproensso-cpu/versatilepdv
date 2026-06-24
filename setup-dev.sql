-- ============================================================
-- Versatile PDV - Setup Ambiente de Desenvolvimento
-- Execute este script no SQL Editor do seu projeto Supabase DEV
-- ============================================================

-- 1. EXTENSAO pgcrypto (necessaria para hash de senhas)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ============================================================
-- 2. TABELAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.usuarios (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome      text NOT NULL,
  username  text NOT NULL UNIQUE,
  senha     text NOT NULL,
  role      text NOT NULL DEFAULT 'vendedor',
  ativo     boolean NOT NULL DEFAULT true,
  criado    timestamptz NOT NULL DEFAULT now(),
  permissoes jsonb
);

CREATE TABLE IF NOT EXISTS public.produtos (
  id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cod    text,
  nome   text NOT NULL,
  marca  text,
  cor    text,
  custo  numeric NOT NULL DEFAULT 0,
  preco  numeric NOT NULL DEFAULT 0,
  min    integer NOT NULL DEFAULT 2,
  obs    text,
  grade  jsonb NOT NULL DEFAULT '[]'::jsonb,
  qtd    integer NOT NULL DEFAULT 0,
  tam    text,
  criado timestamptz NOT NULL DEFAULT now(),
  foto   text
);

CREATE TABLE IF NOT EXISTS public.clientes (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome      text NOT NULL,
  cpf       text,
  nasc      date,
  whatsapp  text,
  email     text,
  endereco  text,
  obs       text,
  criado    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.vendas (
  id                 text PRIMARY KEY,
  data               timestamptz NOT NULL DEFAULT now(),
  cliente_id         uuid,
  cliente_nome       text DEFAULT '',
  pgto               text,
  recebido           numeric NOT NULL DEFAULT 0,
  troco              numeric NOT NULL DEFAULT 0,
  modalidade         text DEFAULT 'Presencial',
  itens              jsonb NOT NULL DEFAULT '[]'::jsonb,
  subtotal           numeric NOT NULL DEFAULT 0,
  desconto           numeric NOT NULL DEFAULT 0,
  total              numeric NOT NULL DEFAULT 0,
  vendedor_nome      text,
  vendedor_id        uuid,
  created_at         timestamptz NOT NULL DEFAULT now(),
  bandeira           text,
  parcelas           integer DEFAULT 1,
  taxa_maquininha    numeric DEFAULT 0,
  valor_liquido      numeric,
  desconto_maquininha numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.movimentos (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo        text NOT NULL,
  descricao   text,
  val         numeric NOT NULL DEFAULT 0,
  data        timestamptz NOT NULL DEFAULT now(),
  venda_id    text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.caixas (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  data           date NOT NULL,
  hora           text,
  vendedor_id    uuid,
  vendedor_nome  text,
  total          numeric NOT NULL DEFAULT 0,
  qtd_vendas     integer NOT NULL DEFAULT 0,
  obs            text,
  criado         timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.auditoria (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id    uuid,
  usuario_nome  text,
  acao          text NOT NULL,
  detalhe       text,
  extra         text,
  data          date NOT NULL DEFAULT CURRENT_DATE,
  hora          text,
  "timestamp"   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.configuracoes (
  chave      text PRIMARY KEY,
  valor      text NOT NULL,
  criado     timestamptz NOT NULL DEFAULT now(),
  atualizado timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.conversas (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telefone         text NOT NULL UNIQUE,
  nome_cliente     text,
  status           text NOT NULL DEFAULT 'novo',
  venda_pendente   jsonb,
  ultima_interacao timestamptz NOT NULL DEFAULT now(),
  criado_em        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.followups (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversa_id    uuid NOT NULL,
  agendado_para  timestamptz NOT NULL,
  executado      boolean NOT NULL DEFAULT false,
  motivo         text,
  criado_em      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.mensagens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversa_id uuid NOT NULL,
  remetente   text NOT NULL,
  tipo        text NOT NULL,
  conteudo    text,
  midia_url   text,
  criado_em   timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 3. RLS (Row Level Security)
-- ============================================================

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caixas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensagens ENABLE ROW LEVEL SECURITY;

-- Bloquear acesso direto anon a usuarios (login via RPC)
CREATE POLICY block_anon_usuarios ON public.usuarios
  FOR ALL TO anon
  USING (false) WITH CHECK (false);

-- Acesso total para demais tabelas (anon + authenticated)
CREATE POLICY acesso_total_produtos ON public.produtos
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_clientes ON public.clientes
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_vendas ON public.vendas
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_movimentos ON public.movimentos
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_caixas ON public.caixas
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_auditoria ON public.auditoria
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_configuracoes ON public.configuracoes
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_conversas ON public.conversas
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_followups ON public.followups
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY acesso_total_mensagens ON public.mensagens
  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 4. FUNCOES RPC (SECURITY DEFINER)
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_login(p_username text, p_senha text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user record;
BEGIN
  SELECT id, nome, username, role, ativo, criado, permissoes
  INTO v_user
  FROM public.usuarios
  WHERE lower(username) = lower(p_username)
    AND ativo = true
    AND senha = crypt(p_senha, senha);

  IF v_user IS NULL THEN
    RETURN json_build_object('ok', false);
  END IF;

  RETURN json_build_object(
    'ok', true,
    'usuario', json_build_object(
      'id', v_user.id,
      'nome', v_user.nome,
      'username', v_user.username,
      'role', v_user.role,
      'ativo', v_user.ativo,
      'criado', v_user.criado,
      'permissoes', v_user.permissoes
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_save_usuario(
  p_id uuid,
  p_nome text,
  p_username text,
  p_senha text,
  p_role text,
  p_ativo boolean,
  p_permissoes jsonb
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_id uuid;
  v_hashed text;
BEGIN
  IF EXISTS(
    SELECT 1 FROM public.usuarios
    WHERE lower(username) = lower(p_username)
      AND id != COALESCE(p_id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RETURN json_build_object('ok', false, 'msg', 'Username já existe');
  END IF;

  IF p_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.usuarios WHERE id = p_id) THEN
    IF p_senha IS NOT NULL AND p_senha != '' THEN
      v_hashed := crypt(p_senha, gen_salt('bf', 10));
      UPDATE public.usuarios
      SET nome=p_nome, username=p_username, senha=v_hashed,
          role=p_role, ativo=p_ativo, permissoes=p_permissoes
      WHERE id = p_id;
    ELSE
      UPDATE public.usuarios
      SET nome=p_nome, username=p_username,
          role=p_role, ativo=p_ativo, permissoes=p_permissoes
      WHERE id = p_id;
    END IF;
    RETURN json_build_object('ok', true, 'id', p_id);
  ELSE
    IF p_senha IS NULL OR p_senha = '' THEN
      RETURN json_build_object('ok', false, 'msg', 'Senha obrigatória');
    END IF;
    v_hashed := crypt(p_senha, gen_salt('bf', 10));
    INSERT INTO public.usuarios(nome, username, senha, role, ativo, permissoes)
    VALUES(p_nome, p_username, v_hashed, p_role, p_ativo, p_permissoes)
    RETURNING id INTO v_id;
    RETURN json_build_object('ok', true, 'id', v_id);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_delete_usuario(p_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  DELETE FROM public.usuarios WHERE id = p_id;
  RETURN json_build_object('ok', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_list_usuarios()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  RETURN COALESCE((
    SELECT json_agg(
      json_build_object(
        'id', id,
        'nome', nome,
        'username', username,
        'role', role,
        'ativo', ativo,
        'criado', criado,
        'permissoes', permissoes
      ) ORDER BY criado
    )
    FROM public.usuarios
  ), '[]'::json);
END;
$$;

-- ============================================================
-- 5. REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.produtos;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clientes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.vendas;
ALTER PUBLICATION supabase_realtime ADD TABLE public.movimentos;
ALTER PUBLICATION supabase_realtime ADD TABLE public.caixas;

ALTER TABLE public.produtos REPLICA IDENTITY FULL;
ALTER TABLE public.clientes REPLICA IDENTITY FULL;
ALTER TABLE public.vendas REPLICA IDENTITY FULL;
ALTER TABLE public.movimentos REPLICA IDENTITY FULL;
ALTER TABLE public.caixas REPLICA IDENTITY FULL;

-- ============================================================
-- 6. SEED DATA - Usuario admin (senha: admin123)
-- ============================================================

INSERT INTO public.usuarios (nome, username, senha, role, ativo, permissoes)
VALUES (
  'Administrador',
  'admin',
  crypt('admin123', gen_salt('bf', 10)),
  'admin',
  true,
  '{"vendas":1,"produtos":1,"clientes":1,"caixa":1,"relatorios":1,"usuarios":1,"config":1,"trocas":1,"aniversariantes":1}'::jsonb
);
