# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Customizações Protheus ERP para o cliente **Empretec**, desenvolvidas pela ThinkFast. O código é em AdvPL (`.prw`) e roda sobre o Protheus AppServer TOTVS.

> **Idioma padrão**: todas as interações, comentários, mensagens de commit e documentação devem ser em **português do Brasil**.

Para convenções completas de linguagem AdvPL/TLPP, padrões de código, SonarQube, MVC e REST, leia [`skills/CLAUDE.md`](skills/CLAUDE.md) — essas regras se aplicam integralmente a este projeto.

---

## Build e Compilação

- **IDE**: VS Code com a extensão **TOTVS Developer Studio (TDS)** / TOTVS Language Server
- **Compilação**: Use o atalho `Ctrl+F9` (compilar arquivo) ou `Ctrl+Shift+F9` (compilar pasta) no VS Code com TDS instalado. Não há Makefile; cada `.prw` é compilado individualmente para o RPO do AppServer
- **Includes**: caminho configurado em `.vscode/settings.json` → `totvsLanguageServer.editor.linter.includes`, apontando para a pasta local `C:\Users\mauri\OneDrive\Documentos\TF\Clientes\Empretec\includes` (fora deste repositório) — contém os `.ch` de framework padrão TOTVS
- **Debug**: `.vscode/launch.json` ainda não possui configuração de debug definida neste repositório

---

## Fonte de Consulta TOTVS Padrão

A pasta local `C:\TOTVS` (fora deste repositório) contém o fonte padrão do Protheus/TOTVS para consulta — **não faz parte deste projeto e não deve ser editada**, apenas usada como referência ao entender o comportamento original de uma rotina/função antes de customizá-la ou ao comparar um ponto de entrada com a rotina padrão que ele intercepta.

- `C:\TOTVS\Fontes Protheus\Master\Master\Fontes\` — fontes `.prw`/`.tlpp` padrão organizados por módulo (nomes em português, ex.: `Automação de Coleta de Dados`, `Materiais`, `Financeiro`, `Faturamento`, `Fiscal`). Módulo mais relevante para as rotinas ACD deste projeto: `Automação de Coleta de Dados` (`Acda*.prw`, `Acdi*.prw`).
- `C:\TOTVS\Fontes Protheus\Master\Master\Arquivos_Auxiliares\` — arquivos auxiliares padrão por módulo (RH, Faturamento, Financeiro, Fiscal, etc.)
- `C:\TOTVS\Fontes Protheus\TSS-Master\` — fonte padrão do TSS (TOTVS Serviços Fiscais)
- `C:\TOTVS\RELATORIOS PADRAO\` — pacotes `.ZIP` de relatórios padrão por módulo/segmento, baixados do portal TOTVS
- `C:\TOTVS\26-08-17-FONTE_RELATORIO_CUSTOMIZADOS_BACKOFFICE\` — snapshot de relatórios customizados do Backoffice

Sempre que for necessário entender o comportamento padrão de uma rotina antes de customizá-la, ou localizar o ponto de entrada correto que uma função dispara, consulte primeiro os fontes em `C:\TOTVS` antes de assumir a assinatura/comportamento por conhecimento geral do framework.

---

## Estrutura do Repositório

```
ACD/              → Pontos de entrada de imagem/etiqueta do módulo ACD (Automação de Coleta de Dados)
  acdimg00.prw       → Ponto de entrada IMG00 (imagem de rosto/identificação — padrão Microsiga)
  acdimg01.prw       → Ponto de entrada IMG01 (imagem de identificação do produto)
  acdimg02.prw       → Ponto de entrada IMG02
  impetiemp.prw      → Impressão avulsa de etiquetas de produto (uso na implantação)

A650LEMP.prw      → Ponto de entrada de Gestão de Fretes (GFE) — redireciona local de armazém '01' → '97'
MA680INC.prw      → Ponto de entrada de estoque (SIGAEST) — endereçamento automático no armazém de processo '97'
MT681INC.prw      → Ponto de entrada de faturamento (SIGAFAT) — mesmo endereçamento automático no armazém de processo '97'

skills/           → Guidelines AdvPL/TLPP (CLAUDE.md) e skill references (compartilhado entre projetos ThinkFast)
```

> Este repositório ainda não usa a convenção de pastas `fontes/<MODULO>/pontos de entrada|rotinas|relatorios|...` — os fontes hoje estão na raiz e em `ACD/`. Ao crescer o projeto, mantenha o padrão real acima; não presuma a existência de pastas que não foram criadas.

---

## Módulos e Integrações

| Pasta/Arquivo | Descrição |
|---|---|
| `ACD` | Armazém / Automação de Coleta de Dados — pontos de entrada de imagem e impressão de etiquetas |
| `A650LEMP.prw` | Gestão de Fretes (GFE) — ajuste de local de armazém |
| `MA680INC.prw` | Estoque (SIGAEST) — endereçamento automático no armazém de processo |
| `MT681INC.prw` | Faturamento (SIGAFAT) — endereçamento automático no armazém de processo |

> Lista construída a partir do conteúdo real dos fontes deste repositório. Atualize esta tabela conforme novos módulos/arquivos forem adicionados — não copie tabelas de outros projetos ThinkFast sem validar contra o conteúdo real deste repositório.

---

## Padrões Específicos do Projeto

- O armazém de processo `'97'` aparece como destino recorrente de endereçamento automático (`A100Distri`) em `MA680INC.prw` e `MT681INC.prw` — mantenha esse padrão ao criar novos pontos de entrada de endereçamento, salvo indicação em contrário do usuário.
- `A650LEMP.prw` reescreve o local `'01'` para `'97'` no fluxo de frete (GFE) — considere esse mapeamento ao mexer em rotinas de frete que leem o local de armazém.
- Os arquivos deste repositório ainda usam acentuação em CP-1252 (ex.: `Usu�rio`, `a��o` nos comentários existentes) — ao editar esses arquivos, preserve a codificação CP-1252 conforme a regra geral em [`skills/CLAUDE.md`](skills/CLAUDE.md); não converta para UTF-8.
