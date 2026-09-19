---
name: protheus-empenho-lote-endereco
description: "Implementa empenho de materiais (SD4) dividido por lote e/ou endereço de WMS (SBF/SDC) em rotinas de PCP do Protheus (MATA680/MATA681, apontamento de produção), via MSExecAuto do MATA380/MATA381 - sem RecLock manual em SD4/SBF/SB8/SDC. Use esta skill sempre que o usuário pedir para 'dividir empenho por lote', 'empenho por endereço', 'quebrar SD4 em vários lotes', 'ExecAuto MATA380', 'ExecAuto MATA381', 'AUT_D4_END', ou relatar que a baixa de um componente com controle de lote está pegando o lote certo mas do endereço errado (ou vice-versa) - mesmo que o usuário não mencione MATA380/381 explicitamente, apenas descreva o sintoma de saldo de um componente disperso em vários lotes/endereços da SBF."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: ThinkFast
  version: '1.0.0'
  category: Code Generation
---

# Protheus - Empenho por Lote e Endereço (SD4/SBF/SDC via MATA380/MATA381)

## Overview

Quando um componente de uma Ordem de Produção tem controle de lote (`B1_RASTRO == "L"`) e/ou
controle de endereço/WMS (`B1_LOCALIZ == "S"`), o saldo físico dele na SBF pode estar disperso em
vários lotes e/ou vários endereços. O empenho padrão (SD4) representa apenas **uma** quantidade
por linha, com **um** lote - então, quando o saldo do endereço/lote pretendido não cobre sozinho a
quantidade necessária, é preciso **quebrar** o empenho em várias linhas de SD4.

Esta skill documenta o padrão correto (validado em produção) para fazer essa quebra
programaticamente, dentro de um Ponto de Entrada, delegando a gravação coordenada de
SD4/SB2/SB8/SBF/SDC para as rotinas padrão `MATA380`/`MATA381` via `MSExecAuto`, em vez de
`RecLock` manual nessas tabelas (que não sincroniza SBF/SDC corretamente e não é respeitado pela
baixa física padrão).

Esse conhecimento foi extraído de uma sessão real de debugging (cliente Empretec, PE `MT681AIN`,
ligado ao `MATA681` - apontamento de produção) que levou várias rodadas de tentativa e erro. O
arquivo completo e testado está em
[`references/MT681AIN-template.prw`](references/MT681AIN-template.prw) - leia-o como referência
de implementação completa, não apenas os trechos citados abaixo.

## When to Use

- Implementar um Ponto de Entrada (ou rotina custom) que precisa dividir o empenho (SD4) de um
  componente entre vários lotes e/ou endereços da SBF antes da baixa de materiais em PCP
  (apontamento de produção, MATA680/MATA681).
- O usuário relata que a baixa de um componente com lote/endereço "pega o lote certo mas o
  endereço errado" (ou o contrário) - sintoma clássico de que o saldo está disperso e a divisão
  não foi feita corretamente.
- Qualquer tarefa envolvendo `MSExecAuto` com `MATA380` ou `MATA381` (ajuste de empenho simples ou
  múltiplo).
- Debugar por que um `MSExecAuto` de PCP não está gravando o lote e/ou o endereço esperado em SD4.

**Não é o caso de uso desta skill**: reserva/empenho automático de materiais na criação/liberação
da OP (isso é feito por `MATA980`/rotinas de reserva padrão, não pela quebra pós-empenho aqui
descrita) e ExecAuto de módulos fora de PCP (Estoque, Faturamento, etc. têm suas próprias rotinas
- não confundir `MATA380`/`MATA381` com `MATA240` de estoque).

---

## Passo 0 (obrigatório): confirme os campos antes de escrever qualquer linha

O erro mais caro e mais fácil de cometer nesta área é usar o campo errado da SD4:

| Campo | Significado |
|---|---|
| `SD4->D4_COD` | **O componente/matéria-prima** que está sendo empenhado - é ESTE código que tem lote, endereço e saldo relevante na SBF. |
| `SD4->D4_PRODUTO` | **O produto pai** que está sendo produzido pela OP (o produto acabado/semi-acabado). Quase nunca controla lote/endereço da mesma forma que o componente, e normalmente não tem saldo na SBF do endereço de processo. |

Se o código posiciona SB1/SBF usando `D4_PRODUTO` e "não acha nada" (SB1 não encontrado, ou SBF
sem saldo, mesmo com dados aparentemente corretos), a causa mais provável é essa troca. **Sempre
confirme, olhando a estrutura real da SD4 e o dado de teste, qual campo o cenário do usuário
exige** - não assuma que `D4_PRODUTO` é "o produto" só porque o nome sugere isso.

---

## O padrão: duas chamadas de MSExecAuto (nunca uma só)

### Por que duas chamadas, e não uma

A descoberta empírica mais cara desta sessão: **enviar a quebra por lote (`D4_LOTECTL`/
`D4_NUMLOTE`) e o endereço (`AUT_D4_END`) juntos, na mesma chamada de inclusão do MATA381, não
funciona** - nem o lote nem o endereço são gravados, sem nenhum erro reportado por
`lMsErroAuto`/`GetAutoGRLog()`. A causa exata não foi confirmada (é provável que a validação
interna do MATA381 para `AUT_D4_END` dependa da linha já existir com RecNo real antes de aceitar
o endereço), mas o comportamento é consistente e reproduzível.

A solução que funciona é separar em duas etapas:

1. **Excluir** o empenho original inteiro via `MSExecAuto` do **MATA380**, opção 5 (não dá para
   "alterar" um empenho existente para virar vários - é preciso excluir e recriar).
2. **Incluir**, via `MSExecAuto` do **MATA381** (suporta múltiplos itens, ao contrário do MATA380),
   opção 3, um registro de SD4 por lote necessário - **sem** endereço ainda.
3. **Alterar**, em uma chamada de `MSExecAuto` do MATA381 **separada por linha já incluída**,
   opção 4, só para acrescentar o endereço (`AUT_D4_END`) - sem tocar em quantidade/lote.

Ver [`references/execauto-mata380-381.md`](references/execauto-mata380-381.md) para o formato de
chamada completo de cada rotina (`MATA380` é mais simples - um item plano; `MATA381` usa
`xAutoCab`/`xAutoItens` e suporta múltiplas linhas numa chamada) e o formato oficial confirmado do
campo virtual `AUT_D4_END` (TDN TOTVS, artigo PSIGAPCP0301).

### Esqueleto do fluxo (ver o arquivo completo em references/ para os detalhes)

```
1. Localizar o(s) lote(s) com saldo no endereço pretendido (SBF, ordenados por como fizer sentido
   no cenário - FIFO por BF_NUMLOTE, por data de validade, etc.)
2. Se apenas 1 lote cobre a quantidade total -> nem precisa quebrar, so grava o lote na linha ja
   existente (via MATA381 opcao 4, ou MATA380 se so uma linha)
3. Se precisar quebrar em N lotes:
   a. Excluir o empenho original (MATA380 opcao 5)
   b. Incluir N novas linhas de SD4, uma por lote, SEM endereco (MATA381 opcao 3, uma chamada com
      N itens em xAutoItens)
   c. Para cada uma das N linhas incluidas, uma chamada separada de MATA381 opcao 4 so com
      AUT_D4_END
4. Sempre checar lMsErroAuto apos CADA MSExecAuto e logar GetAutoGRLog() se falhar
5. Se a exclusao (passo a) deu certo mas a inclusao (passo b) falhar, o componente fica SEM
   NENHUM empenho - aborte toda a transacao (UserException) para nao deixar o registro orfao
```

---

## Armadilhas conhecidas (leia antes de gastar horas debugando)

Cada uma destas foi um erro real cometido e corrigido nesta sessão - todas reprodutíveis e fáceis
de repetir num novo projeto se não forem lembradas.

### 1. Nomes de função truncados a 10 caracteres pelo compilador AdvPL/RPO

O compilador da TOTVS compara nomes de função (inclusive `Static Function`) pelos **primeiros 10
caracteres significativos** para detectar duplicidade. `MT681ItemEmp` e `MT681ItemEnd` colidem
("Redefinition of function MT681ITEME") porque ambos começam com `MT681ItemE`. Ao nomear funções
auxiliares com prefixos parecidos, sempre confira se os 10 primeiros caracteres de cada nome são
únicos no arquivo.

### 2. `PadR` obrigatório ao concatenar campos de tamanho fixo em chaves manuais

Ao montar uma chave de busca manual concatenando campos (ex.: `xFilial("SBF") + cLocal +
cEndereco + cProduto` para um `DbSeek` na SBF), **todo campo de tamanho fixo precisa estar
preenchido até o tamanho real do campo** (`PadR(cEndereco, TamSX3("BF_LOCALIZ")[1])`), nunca
`AllTrim`. Um valor mais curto desalinha os bytes dos campos seguintes na concatenação, e a busca
"vaza" silenciosamente para registros de outras chaves (endereços diferentes, por exemplo) sem dar
nenhum erro. Esse é o padrão já usado nos fontes padrão TOTVS (ver `Acda030.prw`, `Acda035.prw`).

### 3. Formato oficial do campo virtual `AUT_D4_END` (MATA381)

Confirmado pelo exemplo oficial da TOTVS no TDN (artigo PSIGAPCP0301 "Exemplo de ExecAuto da
rotina Empenhos Múltiplos (MATA381)", função `Inc381Auto`): o valor de `AUT_D4_END` é um **array
de linhas de endereço**, cada linha sendo, por sua vez, um array de campos no formato padrão de
item de ExecAuto: `{"DC_LOCALIZ", endereco, Nil}` e `{"DC_QUANT", quantidade, Nil}`. **Não** é o
array posicional `{quantidade, endereco, numserie, qtdSegUM, deletado}` usado internamente pelo
`GravaEmp`/`MATA381` (esse formato posicional é montado *depois* de processar `AUT_D4_END`, não é
o que se envia). Ver o exemplo completo em
[`references/execauto-mata380-381.md`](references/execauto-mata380-381.md).

### 4. `MemoWrite` neste ambiente pode não aceitar parâmetro de "append"

Se for usar `MemoWrite` para gravar log de diagnóstico, teste primeiro se a assinatura de 3
parâmetros (`MemoWrite(cArq, cConteudo, lAppend)`) é aceita no ambiente - em pelo menos um
ambiente Protheus testado, o compilador rejeitou com `W0007 Too many parameters calling
memowrite`. Alternativa segura e portável: ler o conteúdo existente com `MemoRead()` (se o arquivo
já existir, via `File()`), concatenar a nova linha, e regravar tudo com `MemoWrite(cArq,
cConteudo)` (2 parâmetros).

### 5. `MakDir` pode não existir no AppMap do ambiente

A função `MakDir()` (criação de diretório) não estava disponível em pelo menos um ambiente testado
(`InterFunctionCall: cannot find function MAKDIR in AppMap`). Antes de assumir que ela existe,
teste, ou simplesmente omita a chamada - o `MemoWrite` do Protheus normalmente já cria as pastas
intermediárias do caminho sozinho ao gravar um arquivo com subpasta que ainda não existe.

### 6. Sempre checar `lMsErroAuto` + `GetAutoGRLog()` após todo `MSExecAuto`

`MSExecAuto` não lança exceção quando a rotina automática rejeita os dados por validação de
negócio - ele só marca a variável `Private lMsErroAuto := .F.` (que **você precisa declarar antes
de cada chamada**, já que é uma Private compartilhada) como `.T.`. Nunca assuma sucesso silencioso.
Depois de cada chamada, cheque `lMsErroAuto` e, se `.T.`, capture o detalhe com `GetAutoGRLog()`
(retorna um array de strings com a mensagem de validação) para log - sem isso, um `MSExecAuto` que
simplesmente não faz nada (nem grava, nem erra) é impossível de diagnosticar.

### 7. Cuidado com exclusão bem-sucedida seguida de inclusão que falha

Como o padrão exige excluir o empenho original antes de recriar (ver seção acima), existe uma
janela real onde a exclusão (destrutiva) já foi commitada mas a inclusão (recriação) falha. Isso
deixa o componente **sem nenhum empenho** - um estado pior que o bug original. Sempre trate esse
caso: se a etapa de inclusão falhar depois de uma exclusão bem-sucedida, aborte toda a transação
(`UserException(cMsg)`, capturável por um `Begin Sequence...Recover Using oErro` no nível mais
alto do Ponto de Entrada) em vez de deixar a rotina padrão confirmar o apontamento com o registro
órfão.

### 8. Log de diagnóstico sem UI, dentro de `Begin Transaction`

Pontos de Entrada que rodam dentro do `Begin Transaction`/`End Transaction` da rotina padrão não
podem chamar funções de UI (`Aviso`, `MsgAlert`, `MsgYesNo`, etc. - travam cenários multiusuário e
podem gerar deadlock). Para depurar esse tipo de PE, use duas funções de log em arquivo dedicado
(ver o exemplo completo em `MT681ItLot`/`MT681LogErro`/`MT681LogTrace` no template):
- uma de **rastreamento** (`trace`), que grava incondicionalmente em pontos-chave do fluxo (início
  da PE, quantos lotes achou, se cada etapa deu certo) - essencial quando o problema não gera
  nenhum erro formal, só um comportamento inesperado;
- uma de **erro** (`erro`), que grava o detalhe de `GetAutoGRLog()` só quando `lMsErroAuto` for
  `.T.`.

### 9. Quando o ExecAuto de empenho não resolve a ambiguidade da baixa física

Em cenários mais antigos/sem WMS novo (`MV_WMSNEW` desligado), a baixa física de estoque por
lote (fora do escopo do empenho em si) pode ser cega a endereço - ela decrementa a SBF pelo
primeiro registro que achar por produto+armazém+lote, ignorando qual endereço específico foi
empenhado. Se, mesmo com o empenho corretamente dividido por lote/endereço via `MATA380`/`MATA381`,
a baixa final continuar inconsistente, a alternativa validada em outro projeto real (Ortosíntese,
`OPCPA002.prw`) é **segregar fisicamente o estoque antes do consumo**: transferir (via
`MSExecAuto`/`MATA261`, transferência entre locais/endereços) a quantidade/lote exatos para um
endereço/armazém **exclusivo** daquele consumo, e só então deixar a baixa padrão consumir dali -
eliminando a ambiguidade por construção, em vez de tentar resolvê-la só no nível do empenho.

### 10. Saldo insuficiente no endereço (apontamento parcial): NÃO force a diferença em um lote

Quando a soma dos saldos dos lotes achados no endereço é **menor** que a quantidade do empenho
original (cenário comum de apontamento parcial, onde só parte do saldo total já chegou aquele
endereço), a tentação é forçar o último lote a "absorver" a diferença para não perder quantidade.
**Isso faz o `MATA381` rejeitar a inclusão** (a quantidade informada excede o saldo real daquele
lote, e a validação interna do `MATA381` - a mesma usada pela tela interativa, `SaldoLote` - barra
isso). O tratamento correto é: aloque em cada lote **no máximo o seu próprio saldo**
(`Min(saldoDoLote, restante)`) e, se sobrar quantidade sem lote correspondente, inclua-a como
**uma linha adicional de SD4 sem lote/endereço atribuído** (`D4_LOTECTL`/`D4_NUMLOTE` vazios, sem
`AUT_D4_END`). Essa linha "sem lote" fica exatamente no mesmo estado em que o componente estaria
se esta customização não existisse, e a lógica padrão do sistema de baixa parcial cuida dela
normalmente - não é preciso (nem é seguro) tentar simular esse comportamento manualmente.

---

## Quick Reference

| Recurso | Conteúdo |
|---|---|
| [references/execauto-mata380-381.md](references/execauto-mata380-381.md) | Formato de chamada do `MSExecAuto` para `MATA380` (simples) e `MATA381` (múltiplo), formato oficial de `AUT_D4_END`, `xAutoCab`/`xAutoItens`, e a alternativa de segregação física (`MATA261`). |
| [references/MT681AIN-template.prw](references/MT681AIN-template.prw) | Ponto de Entrada completo e testado (Empretec, `MT681AIN`/`MATA681`) implementando todo o fluxo descrito nesta skill - use como base/adaptação, não como cópia literal (nomes de função, campos e regras de negócio específicos do cliente original devem ser revisados). |

---

## Antes de considerar a implementação pronta

Siga o checklist de "Completeness Verification" do `skills/CLAUDE.md` deste workspace, e
adicionalmente, específico para esta skill:

- [ ] Confirmou que está usando `D4_COD` (componente), não `D4_PRODUTO` (produto pai), em todos os
      pontos relevantes de SD4/SB1/SBF/SDC.
- [ ] Nenhum nome de função colide nos primeiros 10 caracteres com outro do mesmo arquivo.
- [ ] Toda concatenação manual de chave usa `PadR(..., TamSX3("CAMPO")[1])` para campos de tamanho
      fixo, não `AllTrim`.
- [ ] Lote e endereço são enviados em chamadas de `MSExecAuto` **separadas** (nunca juntos na
      mesma inclusão).
- [ ] Todo `MSExecAuto` tem `lMsErroAuto` checado logo em seguida, com log do detalhe
      (`GetAutoGRLog()`) em caso de falha.
- [ ] Existe tratamento explícito para o caso de exclusão bem-sucedida seguida de
      inclusão/alteração que falha (não deixar o componente sem empenho).
- [ ] Testado o cenário de saldo insuficiente no endereço (apontamento parcial) - a diferença vira
      uma linha sem lote/endereço atribuído, nunca é forçada em um lote que não a comporta.
- [ ] Testado em ambiente de homologação com um caso real de saldo disperso em mais de um
      lote/endereço - **não é suficiente confiar só na leitura do código**; o comportamento do
      `MSExecAuto` para `AUT_D4_END` tem nuances não documentadas oficialmente e variou entre
      tentativas nesta mesma sessão.
