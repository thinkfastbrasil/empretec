#include "totvs.ch"

/*/{Protheus.doc} MT681AIN
Ponto de entrada - Antes do inicio da baixa dos componentes no Apontamento de Producao.

Acionado na rotina MATA681 (SIGAPCP), dentro da transacao do apontamento, logo apos a confirmacao
dos dados (AxInclui/AxIncluiAuto) e ANTES da geracao do movimento de baixa dos componentes
(A680GeraD3/A637BxComp) - ou seja, antes do apontamento efetivamente baixar o empenho da ordem de
producao.

Percorre o empenho de materiais (SD4) da ordem de producao que esta sendo apontada (SH6->H6_OP) e,
para cada componente:
  - Localiza o saldo no endereco de processo da OP na SBF, pelo armazem (D4_LOCAL), produto
    (D4_COD) e endereco (SC2->C2_ITEMCTA - campo reaproveitado para armazenar o endereco de
    processo da ordem de producao, no mesmo padrao ja usado em MA680INC/MT681INC);
  - Para produtos com controle de lote (SB1->B1_RASTRO == "L"), o saldo do endereco pode estar
    distribuido em varios lotes na SBF. Nesse caso, o empenho original (SD4->D4_QUANT) e excluido
    (MSExecAuto MATA380, opcao 5) e recriado em duas etapas via MSExecAuto do MATA381: (1) inclusao
    (opcao 3) de um registro de SD4 por lote utilizado, ate completar a quantidade total do
    empenho, SEM endereco ainda; (2) uma alteracao (opcao 4) por registro incluido na etapa 1, so
    para informar o endereco de processo da OP (cEndereco) no campo virtual AUT_D4_END - a quebra
    em duas etapas evitou que o ExecAuto rejeitasse (ou ignorasse) lote e endereco quando enviados
    juntos na mesma inclusao. Delega a gravacao coordenada de SD4/SB2/SB8/SBF/SDC para a rotina
    padrao (GravaEmp, via MATA381) em vez de manipular essas tabelas diretamente;
  - Para produtos com controle de endereco (SB1->B1_LOCALIZ == "S") mas sem controle de lote, gera
    o empenho por endereco na SDC (SDC->DC_LOCALIZ) diretamente, quando ainda nao existir um
    registro de SDC para o produto/armazem/OP/operacao.

Este ponto de entrada nao recebe parametros via PARAMIXB (MATA681 o aciona sem argumentos:
Execblock('MT681AIN', .F., .F.)) e seu retorno nao e avaliado pela rotina padrao.

@obs2 A divisao por lote (MT681AjustaEmp/MT681ExclEmp/MT681ItLot/MT681ItEnd/MT681ExecMata381)
      exclui o empenho original via MSExecAuto do MATA380 (opcao 5 - mesmo padrao ja usado em
      producao pela ThinkFast em OPCPA002.prw, funcao _fExcEmpe) e recria os registros de SD4 em
      DUAS chamadas separadas de MSExecAuto do MATA381: (1) inclusao (opcao 3, MT681ItLot) de um
      registro por lote, SEM endereco; (2) alteracao (opcao 4, MT681ItEnd) por registro ja
      incluido, so para informar o endereco de processo da OP no campo virtual AUT_D4_END -
      formato confirmado pelo exemplo oficial da TOTVS (TDN, artigo PSIGAPCP0301 "Exemplo de
      ExecAuto da rotina Empenhos Multiplos (MATA381)", funcao Inc381Auto): AUT_D4_END recebe um
      array de linhas de endereco, cada linha sendo um array de campos {"DC_LOCALIZ", endereco,
      Nil} e {"DC_QUANT", quantidade, Nil}. As duas etapas foram separadas porque enviar lote e
      endereco juntos na mesma inclusao nao gravava nem o lote nem o endereco. Ainda assim, ha
      relatos de instabilidade em foruns de desenvolvedores TOTVS para cenarios de multiplos
      lotes/enderecos via ExecAuto (inclusive um defeito catalogado pela propria TOTVS para
      alteracao de empenho com endereco via MATA381) - valide obrigatoriamente em ambiente de
      homologacao (SD4/SBF/SB8/SDC resultantes e o Kardex gerado pela baixa) antes de usar em
      producao.

@type user function
@author ThinkFast
@since 16/09/2026
@return Nil, nao influencia o fluxo padrao do MATA681
@obs Nao adicionar prefixo U_ na declaracao da funcao. Executado dentro do Begin/End Transaction do
     MATA681 - nao chamar funcoes de UI (Aviso/MsgAlert/MsgYesNo/etc) neste ponto de entrada nem nas
     funcoes por ele chamadas.
@see MATA681
/*/
User Function MT681AIN

	Local aAreaSD4   := SD4->(GetArea())
	Local aAreaSB1   := SB1->(GetArea())
	Local aAreaSBF   := SBF->(GetArea())
	Local aAreaSDC   := SDC->(GetArea())
	Local aAreaSC2   := SC2->(GetArea())
	Local cOP        := SH6->H6_OP
	Local cEndereco  := ""

	Begin Sequence

		MT681LogTrace("===== Inicio MT681AIN - OP=" + AllTrim(cOP) + " =====")

		cEndereco := MT681BscEnd(cOP)

		MT681LogTrace("Endereco de processo (SC2->C2_ITEMCTA) = '" + cEndereco + "'")

		If !Empty(cEndereco)
			MT681EmpOP(cOP, cEndereco)
		Else
			MT681LogTrace("Endereco vazio - MT681EmpOP NAO executado")
		EndIf

	Recover Using oErro
		MT681LogTrace("ERRO (Begin Sequence): " + oErro:Description)
		FWLogMsg("ERROR", , "EP", "MT681AIN", , "01", oErro:Description, 0, 0, {})
	End Sequence

	RestArea(aAreaSC2)
	RestArea(aAreaSDC)
	RestArea(aAreaSBF)
	RestArea(aAreaSB1)
	RestArea(aAreaSD4)

Return Nil

/*/{Protheus.doc} MT681BscEnd
Localiza o endereco de processo vinculado a ordem de producao, a partir do campo reaproveitado
SC2->C2_ITEMCTA (mesmo padrao ja utilizado em MA680INC.prw e MT681INC.prw).
@type static function
@author ThinkFast
@since 16/09/2026
@param cOP, caractere, Numero da ordem de producao (SH6->H6_OP)
@return caractere, Codigo do endereco de processo da OP; vazio se a OP nao for localizada na SC2
/*/
Static Function MT681BscEnd(cOP)

	Local cEndereco := ""

	DbSelectArea("SC2")
	SC2->(DbSetOrder(1)) // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD (Ordem de Producao)

	If SC2->(DbSeek(xFilial("SC2") + cOP))
		cEndereco := AllTrim(SC2->C2_ITEMCTA)
	EndIf

Return cEndereco

/*/{Protheus.doc} MT681EmpOP
Percorre todo o empenho de materiais (SD4) da ordem de producao informada e trata o empenho de
cada componente encontrado.

Os RecNos dos registros de SD4 da OP sao coletados previamente, em um array, antes de tratar
qualquer componente. Isso e necessario porque o tratamento de um componente com saldo dividido em
varios lotes (MT681AjustaEmp) exclui e recria registros de SD4 para a mesma OP durante o percurso -
percorrer diretamente pelo indice (DbSkip) faria os registros recriados serem alcancados e tratados
novamente dentro do mesmo laco, causando duplicidade.
@type static function
@author ThinkFast
@since 16/09/2026
@param cOP, caractere, Numero da ordem de producao (SH6->H6_OP)
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681EmpOP(cOP, cEndereco)

	Local cChaveOP := xFilial("SD4") + cOP
	Local aRecnos  := {}
	Local nI

	DbSelectArea("SD4")
	SD4->(DbSetOrder(2)) // D4_FILIAL+D4_OP

	If SD4->(DbSeek(cChaveOP))

		While SD4->(!Eof()) .And. SD4->(D4_FILIAL + D4_OP) == cChaveOP

			AAdd(aRecnos, SD4->(Recno()))

			SD4->(DbSkip())

		EndDo

	EndIf

	For nI := 1 To Len(aRecnos)

		SD4->(DbGoTo(aRecnos[nI]))

		MT681EmpItem(cEndereco)

	Next nI

Return Nil

/*/{Protheus.doc} MT681EmpItem
Trata o empenho do componente posicionado na SD4: busca o saldo no endereco de processo (SBF) e,
conforme o controle do produto (SB1), divide o empenho pelos lotes localizados e/ou gera o empenho
por endereco na SDC.
@type static function
@author ThinkFast
@since 16/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681EmpItem(cEndereco)

	Local aLotes := {}

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD

	If !SB1->(DbSeek(xFilial("SB1") + SD4->D4_COD))
		MT681LogTrace("Produto " + AllTrim(SD4->D4_COD) + " nao encontrado na SB1 - ignorado")
		Return Nil
	EndIf

	If SB1->B1_RASTRO == "L"

		aLotes := MT681AchLot(cEndereco)

		MT681LogTrace("Produto " + AllTrim(SD4->D4_COD) + " OP " + AllTrim(SD4->D4_OP) + ;
			" TRT " + AllTrim(SD4->D4_TRT) + " local " + AllTrim(SD4->D4_LOCAL) + ": " + ;
			AllTrim(Str(Len(aLotes))) + " lote(s) achado(s) no endereco '" + cEndereco + ;
			"' - D4_QUANT original=" + AllTrim(Str(SD4->D4_QUANT)))

		If Len(aLotes) == 0
			MT681LogTrace("Nenhum lote com saldo no endereco - nada feito, empenho original mantido")
			Return Nil
		EndIf

		MT681AjustaEmp(cEndereco, aLotes)

	Else

		DbSelectArea("SBF")
		SBF->(DbSetOrder(1)) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE

		If !SBF->(DbSeek(xFilial("SBF") + SD4->D4_LOCAL + MT681PadEnd(cEndereco) + SD4->D4_COD))
			MT681LogTrace("Produto " + AllTrim(SD4->D4_COD) + " sem controle de lote e sem " + ;
				"saldo na SBF no endereco '" + cEndereco + "' - ignorado")
			Return Nil
		EndIf

		If SB1->B1_LOCALIZ == "S"
			MT681GrvSDC(cEndereco)
		EndIf

	EndIf

Return Nil

/*/{Protheus.doc} MT681AchLot
Localiza, na SBF, todos os lotes com saldo disponivel para o produto/armazem posicionados na SD4,
no endereco de processo informado. Somente lotes cujo saldo esteja no proprio endereco de processo
da OP (cEndereco == SC2->C2_ITEMCTA) sao considerados - saldos do mesmo lote em outros enderecos
sao ignorados.
@type static function
@author ThinkFast
@since 16/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return array, Um item por lote com saldo (>0) encontrado, na ordem da SBF: {BF_LOTECTL,
        BF_NUMLOTE, BF_QUANT}
/*/
Static Function MT681AchLot(cEndereco)

	Local aLotes := {}
	Local cChave := xFilial("SBF") + SD4->D4_LOCAL + MT681PadEnd(cEndereco) + SD4->D4_COD

	DbSelectArea("SBF")
	SBF->(DbSetOrder(1)) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE

	If SBF->(DbSeek(cChave))

		While SBF->(!Eof()) .And. ;
				SBF->(BF_FILIAL + BF_LOCAL + BF_LOCALIZ + BF_PRODUTO) == cChave

			If SBF->BF_QUANT > 0
				AAdd(aLotes, {SBF->BF_LOTECTL, SBF->BF_NUMLOTE, SBF->BF_QUANT})
			EndIf

			SBF->(DbSkip())

		EndDo

	EndIf

Return aLotes

/*/{Protheus.doc} MT681PadEnd
Ajusta o endereco de processo (cEndereco, vindo de SC2->C2_ITEMCTA ja sem espacos - AllTrim) para o
tamanho fixo do campo BF_LOCALIZ, de forma que possa ser concatenado com outros campos da SBF na
montagem de chaves de busca (DbSeek)/comparacao. Sem esse ajuste, um endereco mais curto que o
campo BF_LOCALIZ desalinha os campos concatenados apos ele (BF_PRODUTO), fazendo a busca por
engano alcancar saldos de outros enderecos.
@type static function
@author ThinkFast
@since 19/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA), sem
       espacos (AllTrim)
@return caractere, cEndereco ajustado para o tamanho do campo BF_LOCALIZ
/*/
Static Function MT681PadEnd(cEndereco)
Return PadR(cEndereco, TamSX3("BF_LOCALIZ")[1])

/*/{Protheus.doc} MT681AjustaEmp
Divide o empenho (SD4->D4_QUANT) do componente posicionado na SD4 entre os lotes informados, ate
completar a quantidade total do empenho, delegando a gravacao para a rotina padrao (em vez de
RecLock direto em SD4/SBF/SDC): o registro original e excluido (MT681ExclEmp, MSExecAuto do
MATA380) e recriado em DUAS etapas via MSExecAuto do MATA381 - (1) inclusao (opcao 3) de um
registro de SD4 por lote, SEM endereco, via MT681ItLot; (2) uma alteracao (opcao 4) por registro
ja incluido, so para informar o endereco de processo da OP (cEndereco) via MT681ItEnd
(AUT_D4_END). Enviar lote (etapa 1) e endereco (etapa 2) em chamadas separadas evita que o
ExecAuto rejeite/ignore a gravacao quando ambos sao enviados juntos na mesma inclusao. Caso a
soma dos saldos dos lotes localizados no endereco nao seja suficiente para cobrir o empenho
original (ex.: apontamento parcial, onde so parte do saldo ja chegou aquele endereco), a
diferenca vira uma linha adicional de SD4 SEM lote/endereco atribuido - forcar essa diferenca em
algum lote especifico faria o MATA381 rejeitar a inclusao (a quantidade excederia o saldo real do
lote); deixando-a sem lote, a baixa parcial padrao do sistema trata essa linha exatamente como
trataria se esta PE nao existisse. Se a etapa 1 (inclusao) falhar, aborta toda a transacao do
MATA681 (UserException) para nao perder o empenho; se so a etapa 2 (endereco) falhar, o empenho
fica correto por lote mas sem endereco - erro registrado (MT681LogErro) sem abortar a transacao.
@type static function
@author ThinkFast
@since 19/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@param aLotes, array, Lotes com saldo, no formato retornado por MT681AchLot
@return Nil
/*/
Static Function MT681AjustaEmp(cEndereco, aLotes)

	Local cProduto      := SD4->D4_COD
	Local cLocal        := SD4->D4_LOCAL
	Local cOp           := SD4->D4_OP
	Local cTrt          := SD4->D4_TRT
	Local cRoteiro      := SD4->D4_ROTEIRO
	Local cOperac       := SD4->D4_OPERAC
	Local dData         := SD4->D4_DATA
	Local nQtdRest      := SD4->D4_QUANT
	Local xAutoItens    := {}
	Local aItensCriados := {}
	Local nQtdLote
	Local nI

	MT681LogTrace("MT681AjustaEmp: produto=" + AllTrim(cProduto) + " op=" + AllTrim(cOp) + ;
		" trt=" + AllTrim(cTrt) + " local=" + AllTrim(cLocal) + " qtdOriginal=" + ;
		AllTrim(Str(nQtdRest)) + " qtdeLotes=" + AllTrim(Str(Len(aLotes))))

	If MT681ExclEmp()
		// Exclusao falhou - nada foi alterado, mantem o empenho original intacto
		MT681LogTrace("MT681AjustaEmp: exclusao (MATA380 opcao 5) FALHOU - abortando, " + ;
			"empenho original mantido")
		Return Nil
	EndIf

	MT681LogTrace("MT681AjustaEmp: exclusao (MATA380 opcao 5) OK")

	For nI := 1 To Len(aLotes)

		If nQtdRest <= 0
			Exit
		EndIf

		nQtdLote := Min(aLotes[nI][3], nQtdRest)

		AAdd(xAutoItens, MT681ItLot(cProduto, cLocal, cOp, cTrt, cRoteiro, cOperac, dData, ;
			aLotes[nI][1], aLotes[nI][2], nQtdLote))

		AAdd(aItensCriados, {aLotes[nI][1], aLotes[nI][2], nQtdLote})

		nQtdRest -= nQtdLote

	Next nI

	If nQtdRest > 0
		// Saldo dos lotes achados no endereco nao cobre o empenho original (ex.: apontamento
		// parcial, onde so parte do saldo ja chegou aquele endereco). A sobra vira uma linha de
		// SD4 sem lote/endereco atribuido - a mesma situacao (e o mesmo tratamento) que o
		// componente teria SEM esta PE, deixando a baixa parcial padrao do sistema cuidar dela
		// (nao forcamos essa quantidade em nenhum lote especifico, pois isso faria o MATA381
		// rejeitar a inclusao por exceder o saldo real do lote).
		MT681LogTrace("MT681AjustaEmp: saldo dos lotes insuficiente - sobra " + ;
			AllTrim(Str(nQtdRest)) + " sem lote atribuido (baixa parcial padrao)")

		AAdd(xAutoItens, MT681ItLot(cProduto, cLocal, cOp, cTrt, cRoteiro, cOperac, dData, ;
			"", "", nQtdRest))
	EndIf

	MT681LogTrace("MT681AjustaEmp: " + AllTrim(Str(Len(xAutoItens))) + " item(ns) montado(s) " + ;
		"para a etapa 1 (inclusao por lote, sem endereco)")

	If Len(xAutoItens) == 0
		Return Nil
	EndIf

	// Etapa 1: inclui o empenho ja quebrado por lote (sem endereco ainda), um registro de SD4
	// por lote - isolado da etapa de endereco para diagnosticar se a quebra por lote em si
	// funciona via ExecAuto, independente do endereco.
	If MT681ExecMata381(cOp, xAutoItens, 3, "MT681AjustaEmp-Inclusao")
		// A exclusao do empenho original (MT681ExclEmp) ja foi feita e nao pode ser desfeita
		// aqui - se a inclusao (MATA381) falhar, o componente ficaria sem NENHUM empenho.
		// Aborta toda a transacao do MATA681 (capturada pelo Begin Sequence de MT681AIN) para
		// nao gravar um apontamento com empenho perdido.
		MT681LogTrace("MT681AjustaEmp: etapa 1 (inclusao MATA381 opcao 3) FALHOU - abortando " + ;
			"toda a transacao do MATA681")
		UserException("MT681AIN: falha ao recriar o empenho (MATA381) do produto " + ;
			AllTrim(cProduto) + " na OP " + AllTrim(cOp) + " apos excluir o empenho original " + ;
			"(MATA380). Apontamento abortado para nao perder o empenho - veja o log de erro " + ;
			"anterior (MT681LogErro) para o detalhe da rejeicao do ExecAuto.")
		Return Nil
	EndIf

	MT681LogTrace("MT681AjustaEmp: etapa 1 (inclusao MATA381 opcao 3) OK - " + ;
		AllTrim(Str(Len(aItensCriados))) + " registro(s) de SD4 incluido(s) por lote")

	// Etapa 2: uma alteracao (MATA381 opcao 4) por lote ja incluido na etapa 1, so para
	// informar o endereco de processo da OP (AUT_D4_END) - nao altera quantidade/lote, que ja
	// foram gravados corretamente na etapa 1.
	For nI := 1 To Len(aItensCriados)

		If MT681ExecMata381(cOp, ;
				{MT681ItEnd(cProduto, cLocal, cOp, cTrt, aItensCriados[nI][1], ;
					aItensCriados[nI][2], aItensCriados[nI][3], cEndereco)}, ;
				4, "MT681AjustaEmp-Endereco")

			// A quebra por lote (etapa 1) ja foi gravada - se so o endereco falhar, o empenho
			// fica correto por lote, porem sem endereco (a baixa pode ficar ambigua de novo).
			// Loga o erro (MT681LogErro, dentro de MT681ExecMata381) mas nao aborta a
			// transacao, pois a quantidade/lote em si continuam corretos.
			MT681LogTrace("MT681AjustaEmp: etapa 2 (alteracao MATA381 opcao 4, endereco) " + ;
				"FALHOU no lote '" + AllTrim(aItensCriados[nI][1]) + "'")
			Exit

		Else

			MT681LogTrace("MT681AjustaEmp: etapa 2 (alteracao MATA381 opcao 4, endereco) OK " + ;
				"no lote '" + AllTrim(aItensCriados[nI][1]) + "'")

		EndIf

	Next nI

Return Nil

/*/{Protheus.doc} MT681ExclEmp
Exclui, via MSExecAuto do MATA380 (opcao 5), o registro de empenho posicionado na SD4 - mesmo
padrao ja usado em producao pela ThinkFast em OPCPA002.prw (funcao _fExcEmpe), la para o mesmo
fim de remover um empenho antes de recria-lo dividido por lote/endereco.
@type static function
@author ThinkFast
@since 19/09/2026
@return logico, .T. se o ExecAuto rejeitou a exclusao (lMsErroAuto); .F. se deu certo
/*/
Static Function MT681ExclEmp()

	Local aMata380 := {}

	Private lMsErroAuto := .F.

	AAdd(aMata380, {"D4_COD",   SD4->D4_COD, Nil})
	AAdd(aMata380, {"D4_LOCAL", SD4->D4_LOCAL,   Nil})
	AAdd(aMata380, {"D4_OP",    SD4->D4_OP,      Nil})

	MSExecAuto({|x, y| Mata380(x, y)}, aMata380, 5)

	If lMsErroAuto
		MT681LogErro("MT681ExclEmp/MATA380")
	EndIf

Return lMsErroAuto

/*/{Protheus.doc} MT681ItLot
Monta, no formato padrao de item do ExecAuto (array de {campo, valor, validacao}), um registro de
empenho (SD4) para o lote e quantidade informados - SEM endereco (etapa 1 de MT681AjustaEmp; o
endereco e informado depois, separadamente, por MT681ItEnd/etapa 2).
@type static function
@author ThinkFast
@since 19/09/2026
@param cProduto, caractere, Produto do componente (SD4->D4_COD)
@param cLocal, caractere, Armazem do componente (SD4->D4_LOCAL)
@param cOp, caractere, Ordem de producao (SD4->D4_OP)
@param cTrt, caractere, Sequencia do item na estrutura (SD4->D4_TRT)
@param cRoteiro, caractere, Roteiro de operacoes (SD4->D4_ROTEIRO)
@param cOperac, caractere, Operacao do roteiro (SD4->D4_OPERAC)
@param dData, data, Data do empenho (SD4->D4_DATA)
@param cLoteCtl, caractere, Lote do empenho (BF_LOTECTL localizado por MT681AchLot)
@param cNumLote, caractere, Sub-lote do empenho (BF_NUMLOTE localizado por MT681AchLot)
@param nQtd, numerico, Quantidade do empenho para este lote
@return array, Item no formato esperado por xAutoItens do MSExecAuto do MATA381
/*/
Static Function MT681ItLot(cProduto, cLocal, cOp, cTrt, cRoteiro, cOperac, dData, ;
		cLoteCtl, cNumLote, nQtd)

	Local aItem := {}

	AAdd(aItem, {"D4_COD",     cProduto, Nil})
	AAdd(aItem, {"D4_LOCAL",   cLocal,   Nil})
	AAdd(aItem, {"D4_OP",      cOp,      Nil})
	AAdd(aItem, {"D4_TRT",     cTrt,     Nil})
	AAdd(aItem, {"D4_ROTEIRO", cRoteiro, Nil})
	AAdd(aItem, {"D4_OPERAC",  cOperac,  Nil})
	AAdd(aItem, {"D4_DATA",    dData,    Nil})
	AAdd(aItem, {"D4_QTDEORI", nQtd,     Nil})
	AAdd(aItem, {"D4_QUANT",   nQtd,     Nil})
	AAdd(aItem, {"D4_LOTECTL", cLoteCtl, Nil})
	AAdd(aItem, {"D4_NUMLOTE", cNumLote, Nil})

Return aItem

/*/{Protheus.doc} MT681ItEnd
Monta, no formato padrao de item do ExecAuto, uma alteracao (MATA381 opcao 4) para informar o
endereco de processo da OP (cEndereco) em um registro de SD4 ja incluido na etapa 1
(MT681ItLot/opcao 3), identificado pelas mesmas chaves (produto/armazem/OP/trt/lote/sub-lote)
com que foi gravado. O endereco e informado no campo virtual AUT_D4_END - conforme exemplo
oficial TOTVS (TDN PSIGAPCP0301, Inc381Auto), o valor de AUT_D4_END e um array de "linhas" de
endereco, cada linha sendo, por sua vez, um array de campos {"DC_LOCALIZ", endereco, Nil}/
{"DC_QUANT", quantidade, Nil}.
@type static function
@author ThinkFast
@since 19/09/2026
@param cProduto, caractere, Produto do componente (SD4->D4_COD)
@param cLocal, caractere, Armazem do componente (SD4->D4_LOCAL)
@param cOp, caractere, Ordem de producao (SD4->D4_OP)
@param cTrt, caractere, Sequencia do item na estrutura (SD4->D4_TRT)
@param cLoteCtl, caractere, Lote do empenho ja gravado na etapa 1
@param cNumLote, caractere, Sub-lote do empenho ja gravado na etapa 1
@param nQtd, numerico, Quantidade do empenho ja gravada na etapa 1 (repetida aqui, sem alterar)
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return array, Item no formato esperado por xAutoItens do MSExecAuto do MATA381
/*/
Static Function MT681ItEnd(cProduto, cLocal, cOp, cTrt, cLoteCtl, cNumLote, nQtd, cEndereco)

	Local aItem     := {}
	Local aEnder    := {}
	Local aLinEnder := {}

	AAdd(aItem, {"D4_COD",     cProduto, Nil})
	AAdd(aItem, {"D4_LOCAL",   cLocal,   Nil})
	AAdd(aItem, {"D4_OP",      cOp,      Nil})
	AAdd(aItem, {"D4_TRT",     cTrt,     Nil})
	AAdd(aItem, {"D4_LOTECTL", cLoteCtl, Nil})
	AAdd(aItem, {"D4_NUMLOTE", cNumLote, Nil})
	AAdd(aItem, {"D4_QUANT",   nQtd,     Nil})

	AAdd(aLinEnder, {"DC_LOCALIZ", cEndereco, Nil})
	AAdd(aLinEnder, {"DC_QUANT",   nQtd,      Nil})
	AAdd(aEnder, aLinEnder)

	AAdd(aItem, {"AUT_D4_END", aEnder, Nil})

Return aItem

/*/{Protheus.doc} MT681ExecMata381
Executa o MSExecAuto do MATA381 com xAutoCab padronizado (apenas D4_OP, conforme exemplo oficial
TOTVS TDN PSIGAPCP0301/Inc381Auto), registrando (MT681LogErro) o detalhe da rejeicao quando o
ExecAuto falha (lMsErroAuto).
@type static function
@author ThinkFast
@since 19/09/2026
@param cOp, caractere, Ordem de producao (SD4->D4_OP)
@param xAutoItens, array, Itens para o MSExecAuto, no formato retornado por MT681ItLot/
       MT681ItEnd
@param nOpc, numerico, Opcao do ExecAuto (3-Incluir, 4-Alterar, 5-Excluir)
@param cOrigemLog, caractere, Identificacao da chamada, usada em MT681LogErro caso falhe
@return logico, .T. se o ExecAuto rejeitou a operacao (lMsErroAuto); .F. se deu certo
/*/
Static Function MT681ExecMata381(cOp, xAutoItens, nOpc, cOrigemLog)

	Local xAutoCab := {}

	Private lMsErroAuto := .F.

	AAdd(xAutoCab, {"D4_OP", cOp, Nil})

	MSExecAuto({|x, y, z| Mata381(x, y, z)}, xAutoCab, xAutoItens, nOpc)

	If lMsErroAuto
		MT681LogErro(cOrigemLog)
	EndIf

Return lMsErroAuto

/*/{Protheus.doc} MT681LogErro
Registra, em arquivo texto dedicado (via MemoWrite, sem depender de UI nem do log geral do
AppServer) e tambem via FWLogMsg, os detalhes do ultimo erro de validacao do MSExecAuto
(GetAutoGRLog), identificando a funcao/rotina de origem. O arquivo e gravado na pasta MT681AIN, na
raiz do RootPath do AppServer (o proprio MemoWrite cria a pasta se ainda nao existir), com nome
unico por chamada (data/hora/origem).
@type static function
@author ThinkFast
@since 19/09/2026
@param cOrigem, caractere, Identificacao da chamada de ExecAuto que falhou (funcao/rotina)
@return Nil
/*/
Static Function MT681LogErro(cOrigem)

	Local aErro  := GetAutoGRLog()
	Local cArq   := "MT681AIN\MT681AIN_erro_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ;
		"_" + cOrigem + ".log"
	Local cMsg   := "Origem: " + cOrigem + CRLF + "Data/Hora: " + DToC(Date()) + " " + Time() + CRLF + CRLF
	Local nI

	If Len(aErro) == 0
		cMsg += "(GetAutoGRLog() nao retornou nenhuma mensagem - lMsErroAuto = .T. sem detalhe)" + CRLF
	Else
		For nI := 1 To Len(aErro)
			cMsg += aErro[nI] + CRLF
		Next nI
	EndIf

	MemoWrite(cArq, cMsg)

	FWLogMsg("ERROR", , "EP", "MT681AIN", , "02", cOrigem + " - detalhe gravado em " + cArq, 0, 0, {})

Return Nil

/*/{Protheus.doc} MT681LogTrace
Grava uma linha de rastreamento (data/hora + mensagem) em arquivo texto dedicado dentro da pasta
MT681AIN, na raiz do RootPath do AppServer (o proprio MemoWrite cria a pasta se ainda nao
existir), usado para acompanhar o fluxo desta PE passo a passo durante os testes - sem depender
de UI, do console geral do AppServer, ou de o ExecAuto sinalizar um erro formal (lMsErroAuto)
para termos visibilidade de onde a execucao chegou ou parou. Um arquivo por dia
(MT681AIN_trace_AAAAMMDD.log); como o MemoWrite deste ambiente nao aceita parametro de
"acrescentar" (append), a funcao le o conteudo existente (MemoRead) e regrava tudo de uma vez,
com a nova linha ao final.
@type static function
@author ThinkFast
@since 19/09/2026
@param cMsg, caractere, Mensagem a ser registrada
@return Nil
/*/
Static Function MT681LogTrace(cMsg)

	Local cArq      := "MT681AIN\MT681AIN_trace_" + DToS(Date()) + ".log"
	Local cConteudo := ""

	If File(cArq)
		cConteudo := MemoRead(cArq)
	EndIf

	cConteudo += DToC(Date()) + " " + Time() + " - " + cMsg + CRLF

	MemoWrite(cArq, cConteudo)

Return Nil

/*/{Protheus.doc} MT681GrvSDC
Gera (ou corrige) o empenho por endereco na SDC para o componente posicionado na SD4, usada apenas
no caminho de produtos com controle de endereco mas SEM controle de lote (SB1->B1_RASTRO != "L")
- quando ha controle de lote, a gravacao de SD4/SDC/SBF/SB8 e feita via MATA380 (exclusao) e
MATA381 (inclusao)/GravaEmp (MT681AjustaEmp), nao por aqui. O lote (D4_LOTECTL+D4_NUMLOTE) faz
parte da chave de busca. Como
DC_LOCALIZ nao faz parte dessa chave (o indice/estrutura padrao da SDC nao inclui o endereco na
chave usada aqui), se ja existir um registro de SDC para o produto/armazem/OP/operacao/lote (por
exemplo, gerado por uma reserva anterior a esta PE, com outro endereco), o registro e atualizado
(nao apenas ignorado) para sempre refletir o endereco de processo da OP (cEndereco) e a quantidade
atual do empenho (SD4->D4_QUANT). Sem essa atualizacao, a baixa padrao poderia usar um endereco
desatualizado, mesmo com o lote correto.
@type static function
@author ThinkFast
@since 16/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681GrvSDC(cEndereco)

	Local cChaveSDC := xFilial("SDC") + SD4->(D4_COD + D4_LOCAL + D4_OP + D4_TRT + D4_LOTECTL + D4_NUMLOTE)
	Local lNovo      := .F.

	DbSelectArea("SDC")
	SDC->(DbSetOrder(2)) // DC_FILIAL+DC_PRODUTO+DC_LOCAL+DC_OP+DC_TRT+DC_LOTECTL+DC_NUMLOTE

	lNovo := !SDC->(DbSeek(cChaveSDC))

	RecLock("SDC", lNovo)

		If lNovo
			SDC->DC_FILIAL  := xFilial("SDC")
			SDC->DC_PRODUTO := SD4->D4_COD
			SDC->DC_LOCAL   := SD4->D4_LOCAL
			SDC->DC_OP      := SD4->D4_OP
			SDC->DC_TRT     := SD4->D4_TRT
			SDC->DC_LOTECTL := SD4->D4_LOTECTL
			SDC->DC_NUMLOTE := SD4->D4_NUMLOTE
			If SDC->(FieldPos("DC_QTDORIG")) > 0
				SDC->DC_QTDORIG := SD4->D4_QUANT
			EndIf
		EndIf

		SDC->DC_LOCALIZ := cEndereco
		SDC->DC_QUANT   := SD4->D4_QUANT

	MsUnLock()

Return Nil
