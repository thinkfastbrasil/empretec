# ExecAuto de Empenho: MATA380 e MATA381

Referência detalhada para chamar `MSExecAuto` sobre as rotinas padrão de ajuste de empenho do PCP.
Leia [`../SKILL.md`](../SKILL.md) primeiro para o contexto geral (por que duas chamadas, armadilhas
conhecidas) - este arquivo cobre só o formato exato de cada chamada.

## Índice

- [MATA380 - Ajuste de Empenho (simples)](#mata380---ajuste-de-empenho-simples)
- [MATA381 - Ajuste de Empenho Múltiplo](#mata381---ajuste-de-empenho-múltiplo)
- [Formato oficial de `AUT_D4_END`](#formato-oficial-de-aut_d4_end)
- [Checar erro após o ExecAuto](#checar-erro-após-o-execauto)
- [Alternativa: segregação física via MATA261](#alternativa-segregação-física-via-mata261)

---

## MATA380 - Ajuste de Empenho (simples)

`MATA380` trabalha com **um item plano por chamada** (não tem conceito de cabeçalho+itens como o
MATA381) e **não suporta endereço** - só produto/armazém/OP/lote/quantidade. Use-o para:

- **Excluir** um empenho existente (opção 5) - inclusive como primeiro passo antes de recriar por
  lote via MATA381.
- Incluir um único empenho simples, sem necessidade de dividir por lote/endereço.

### Exclusão (opção 5)

Posicione a SD4 no registro a excluir (via `DbGoTo`) antes de chamar - os campos do array servem
de contexto/validação, não de busca:

```advpl
Local aMata380 := {}

AAdd(aMata380, {"D4_COD",   SD4->D4_COD,   Nil})  // componente - NUNCA D4_PRODUTO
AAdd(aMata380, {"D4_LOCAL", SD4->D4_LOCAL, Nil})
AAdd(aMata380, {"D4_OP",    SD4->D4_OP,    Nil})

Private lMsErroAuto := .F.

MSExecAuto({|x, y| Mata380(x, y)}, aMata380, 5)

If lMsErroAuto
    // logar GetAutoGRLog() - ver secao "Checar erro"
EndIf
```

### Inclusão simples (opção 3)

```advpl
Local aMata380 := {}

AAdd(aMata380, {"D4_COD",     cProduto, Nil})   // componente
AAdd(aMata380, {"D4_LOCAL",   cLocal,   Nil})
AAdd(aMata380, {"D4_OP",      cOp,      Nil})
AAdd(aMata380, {"D4_TRT",     cTrt,     Nil})
AAdd(aMata380, {"D4_ROTEIRO", cRoteiro, Nil})
AAdd(aMata380, {"D4_OPERAC",  cOperac,  Nil})
AAdd(aMata380, {"D4_DATA",    dData,    Nil})
AAdd(aMata380, {"D4_QTDEORI", nQtd,     Nil})
AAdd(aMata380, {"D4_QUANT",   nQtd,     Nil})
AAdd(aMata380, {"D4_LOTECTL", cLoteCtl, Nil})    // opcional, se o produto controla lote
AAdd(aMata380, {"D4_NUMLOTE", cNumLote, Nil})    // opcional, sub-lote

Private lMsErroAuto := .F.

MSExecAuto({|x, y| Mata380(x, y)}, aMata380, 3)
```

> Um exemplo real desse padrão (exclusão + inclusão simples, sem endereço) está em produção no
> projeto Ortosíntese, `OPCPA002.prw`, funções `_fExcEmpe`/`_fEmpenho`.

---

## MATA381 - Ajuste de Empenho Múltiplo

`MATA381` suporta **múltiplos itens numa única chamada** via `xAutoCab` (cabeçalho, identifica a
OP) + `xAutoItens` (array de itens, um por linha de SD4 a incluir/alterar). É a rotina certa para
"quebrar por lote" - cada item de `xAutoItens` vira uma linha de SD4.

### Assinatura

```advpl
MSExecAuto({|x, y, z| Mata381(x, y, z)}, xAutoCab, xAutoItens, nOpc)
```

- `nOpc`: 3 = Incluir, 4 = Alterar, 5 = Excluir (mas para excluir prefira `MATA380`, mais simples).
- `xAutoCab`: header - **na prática só precisa de `D4_OP`**, conforme o exemplo oficial da TOTVS
  (ver abaixo). Não é necessário nenhum outro campo de cabeçalho, nem um campo tipo "INDEX" - essa
  ideia veio de um post de fórum não-oficial e **não é confirmada**; o exemplo oficial do TDN não
  usa isso.
- `xAutoItens`: array de itens - cada item é, por sua vez, um array de triplas
  `{"NOME_CAMPO", valor, Nil}` (o `Nil` é o bloco de validação, normalmente não usado).

### Exemplo oficial da TOTVS (TDN, artigo PSIGAPCP0301 "Exemplo de ExecAuto da rotina Empenhos
Múltiplos (MATA381)", função `Inc381Auto`)

Este é o exemplo **confirmado pela documentação oficial** - baseie qualquer implementação nele, não
em posts de fórum de terceiros (que existem, mas têm relatos de comportamento inconsistente).

```advpl
User Function Inc381Auto()
    Local aCab       := {}
    Local aItens     := {}
    Local aLine      := {}
    Local aLineNLI   := {}
    Local aEnder     := {}
    Local aLineEnder := {}

    PRIVATE lMsErroAuto := .F.

    // Cabeçalho: so precisa do numero da OP
    aCab := {{"D4_OP", "00130301001", NIL}}

    // --- Item 1: empenho simples, sem lote ---
    aLine := {}
    aAdd(aLine, {"D4_OP",      "00130301001",      NIL})
    aAdd(aLine, {"D4_COD",     "MP01",             NIL})
    aAdd(aLine, {"D4_LOCAL",   "01",               NIL})
    aAdd(aLine, {"D4_DATA",    CtoD("18/09/2018"), NIL})
    aAdd(aLine, {"D4_QTDEORI", 10,                 NIL})
    aAdd(aLine, {"D4_QUANT",   10,                 NIL})
    aAdd(aLine, {"D4_TRT",     "001",              NIL})
    aAdd(aItens, aLine)

    // --- Item 2: empenho com lote, sem endereco ---
    aLine := {}
    aAdd(aLine, {"D4_OP",      "00130301001",      NIL})
    aAdd(aLine, {"D4_COD",     "MP02",             NIL})
    aAdd(aLine, {"D4_LOCAL",   "01",               NIL})
    aAdd(aLine, {"D4_DATA",    CtoD("18/09/2018"), NIL})
    aAdd(aLine, {"D4_QTDEORI", 3,                  NIL})
    aAdd(aLine, {"D4_QUANT",   3,                  NIL})
    aAdd(aLine, {"D4_LOTECTL", "L1",               NIL})
    aAdd(aLine, {"D4_TRT",     "002",              NIL})
    aAdd(aItens, aLine)

    // --- Item 3: empenho com lote E endereco ---
    aLine := {}
    aAdd(aLine, {"D4_OP",      "00130301001",      NIL})
    aAdd(aLine, {"D4_COD",     "MP03",             NIL})
    aAdd(aLine, {"D4_LOCAL",   "01",               NIL})
    aAdd(aLine, {"D4_DATA",    CtoD("17/09/2018"), NIL})
    aAdd(aLine, {"D4_QTDEORI", 10,                 NIL})
    aAdd(aLine, {"D4_QUANT",   10,                 NIL})
    aAdd(aLine, {"D4_LOTECTL", "L1",               NIL})
    aAdd(aLine, {"D4_TRT",     "003",              NIL})
    aAdd(aLine, {"D4_ROTEIRO", "01",               NIL})

    // Informacoes do endereco - DOIS enderecos para o MESMO lote/linha
    aEnder := {}

    aLineEnder := {}
    aAdd(aLineEnder, {"DC_LOCALIZ", "END01", Nil})
    aAdd(aLineEnder, {"DC_QUANT",   5,       Nil})
    aAdd(aEnder, aLineEnder)   // primeiro endereco

    aLineEnder := {}
    aAdd(aLineEnder, {"DC_LOCALIZ", "END02", Nil})
    aAdd(aLineEnder, {"DC_QUANT",   5,       Nil})
    aAdd(aEnder, aLineEnder)   // segundo endereco

    aAdd(aLine, {"AUT_D4_END", aEnder, Nil})   // acrescenta os enderecos na linha do empenho

    aAdd(aItens, aLine)

    MSExecAuto({|x, y, z| mata381(x, y, z)}, aCab, aItens, 3)

    If lMsErroAuto
        MostraErro()   // so no exemplo interativo oficial - dentro de um PE, use GetAutoGRLog()
    Else
        Alert("Incluido com sucesso.")   // idem - nao chamar em PE dentro de transacao
    EndIf
Return
```

**Ponto-chave**: no exemplo oficial, o item 3 já nasce **com lote e endereço juntos, numa única
inclusão**, e funciona - a diferença para o cenário problemático (quebra em várias linhas do MESMO
componente) é que aqui é **uma linha nova única** recebendo lote+endereço, não uma linha sendo
**dividida em N linhas**. Na prática desta skill (quebra por lote), enviar lote+endereço juntos
numa inclusão que gera múltiplas linhas relacionadas ao mesmo componente/OP se mostrou instável -
por isso o padrão recomendado (ver `SKILL.md`) separa em duas chamadas mesmo que o exemplo oficial
sugira que dá para fazer numa só. Se o seu cenário for **uma única linha nova, isolada**, o padrão
combinado do exemplo oficial pode funcionar sem a etapa 2; teste primeiro.

---

## Formato oficial de `AUT_D4_END`

Confirmado pelo exemplo acima:

- É um **array de linhas de endereço** (uma entrada por endereço usado por aquela linha de
  empenho).
- Cada linha é, por sua vez, um **array de campos no formato padrão de item de ExecAuto**:
  `{"DC_LOCALIZ", cEndereco, Nil}` e `{"DC_QUANT", nQuantidade, Nil}`.
- **Não** é o array posicional `{quantidade, endereco, numserie, qtdSegUM, deletado}` que aparece
  internamente em `mata381.prx` (função `a381Ender`/variável `aEnderecos`) - aquele formato é
  resultado do PROCESSAMENTO de `AUT_D4_END`, feito pela própria rotina; **não é o que você monta e
  envia**.
- Não confundir com um array simples de strings de endereço (`{"END01", "END02"}`) - isso não é
  aceito, mesmo passando na checagem de tipo (`ValType(...) == "A"`), porque a rotina espera as
  triplas de campo/valor para extrair `DC_LOCALIZ`/`DC_QUANT` de cada linha.

---

## Checar erro após o ExecAuto

`MSExecAuto` nunca lança exceção por rejeição de validação de negócio - ele só marca
`lMsErroAuto := .T.`. Sempre:

```advpl
Private lMsErroAuto := .F.   // declarar ANTES de cada chamada (Private compartilhada)

MSExecAuto({|x, y, z| Mata381(x, y, z)}, xAutoCab, xAutoItens, nOpc)

If lMsErroAuto
    Local aErro := GetAutoGRLog()   // array de strings com o detalhe da rejeicao
    // gravar aErro em log de arquivo (nao ha UI dentro de Begin Transaction) - ver
    // MT681LogErro no template para um exemplo completo de log em arquivo dedicado
EndIf
```

`GetAutoGRLog()` é a mesma função que a interativa `MostraErro()` usa internamente para popular o
arquivo de log exibido ao usuário - pode ser lida diretamente, sem nenhuma tela.

---

## Alternativa: segregação física via MATA261

Quando mesmo um empenho corretamente dividido por lote/endereço não é suficiente porque a **baixa
física** (não o empenho em si) ignora o endereço específico ao decrementar a SBF (comum em
ambientes sem WMS novo, `MV_WMSNEW` desligado), a alternativa validada em produção
(Ortosíntese, `OPCPA002.prw`) é segregar fisicamente o estoque antes do consumo:

1. Excluir o empenho antigo (`MATA380` opção 5, igual ao padrão desta skill).
2. Transferir (via `MSExecAuto`/`MATA261` - transferência entre locais/endereços) a
   quantidade/lote exatos do endereço de origem para um endereço/armazém **exclusivo** daquele
   consumo (ex.: armazém dedicado tipo "96", endereço "FABRICA" - configurável via `GetMV`).
3. Recriar o empenho (`MATA380` opção 3) apontando para esse armazém/endereço de destino, que por
   ser exclusivo não tem ambiguidade nenhuma - a baixa padrão, mesmo cega a endereço, só encontra
   uma opção possível ali.

Essa técnica custa mais (gera um documento real de movimentação de estoque, `SD3`, a cada
consumo) mas contorna definitivamente a limitação da baixa física quando o `MATA380`/`MATA381`
sozinhos não bastam. Use como plano B se, depois de implementar o padrão principal desta skill e
validar em homologação, a baixa final ainda não respeitar o endereço empenhado.
