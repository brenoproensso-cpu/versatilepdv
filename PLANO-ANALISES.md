# Plano — Aba "Análises" (Versatile PDV)

> Status: **planejamento, não implementado ainda**. Guardado aqui pra retomar depois,
> sem precisar re-explicar o contexto. Cole este arquivo de volta na conversa quando
> quiser continuar.

## Onde fica
Aba própria no menu lateral, separada do Painel do dia a dia — algo como **"Análises"**,
não misturada com os cards operacionais que o time já usa toda hora.

## Comparações de período (todas via seletor, reaproveitando helpers que já existem
no código: `today()`, `thisMonth()`, `shiftMonth()`, `semanaAtual(offset)`)
- Semana atual vs semana passada
- Mês atual vs mês passado
- Período customizado (escolher duas datas/intervalos quaisquer pra comparar)

## Métricas — nível 1 (dados que já existem no banco, dá pra fazer sem depender de nada externo)
- Faturamento total (com variação % entre os períodos)
- Nº de vendas e ticket médio
- Pares vendidos, por produto e por categoria
- **Lucratividade**: quais produtos dão mais lucro (usar `custo` x `preço` x qtd vendida —
  já existe cálculo parecido em Financeiro → Lucro por Produto, reaproveitar)
- **Sugestão de reposição**: cruzar velocidade de venda (giro) por produto/tamanho com
  estoque atual, pra apontar o que é prioridade comprar antes de faltar — não é só
  "estoque baixo" (que já existe no Painel), é "vai faltar logo baseado no ritmo de venda"

## Métricas — nível 2 (dependem de fonte de dados externa, maior custo/complexidade)
- Análise de mercado / redes sociais via API externa — **ainda sem definição**: precisa
  decidir quais fontes (Instagram? Google Trends? concorrentes?), se tem custo de API,
  e se faz sentido pro porte da loja antes de entrar em detalhe técnico.

## Pendências antes de implementar
1. Confirmar layout: cards com %, gráfico, tabela — ou combinação.
2. Detalhar exatamente o que "sugestão de reposição" deve calcular (regra de giro/estoque).
3. Decidir se a parte de redes sociais/mercado entra nessa primeira versão ou fica pra depois.
