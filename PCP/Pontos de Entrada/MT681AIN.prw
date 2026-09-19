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
    (D4_PRODUTO) e endereco (SC2->C2_ITEMCTA - campo reaproveitado para armazenar o endereco de
    processo da ordem de producao, no mesmo padrao ja usado em MA680INC/MT681INC);
  - Para produtos com controle de lote (SB1->B1_RASTRO == "L"), preenche o lote do empenho
    (SD4->D4_LOTECTL) com o lote localizado na SBF;
  - Para produtos com controle de endereco (SB1->B1_LOCALIZ == "S"), gera o empenho por endereco na
    SDC (SDC->DC_LOCALIZ), quando ainda nao existir um registro para o produto/armazem/OP/operacao.

Este ponto de entrada nao recebe parametros via PARAMIXB (MATA681 o aciona sem argumentos:
Execblock('MT681AIN', .F., .F.)) e seu retorno nao e avaliado pela rotina padrao.

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

		cEndereco := MT681BscEnd(cOP)

		If !Empty(cEndereco)
			MT681EmpOP(cOP, cEndereco)
		EndIf

	Recover Using oErro
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
@type static function
@author ThinkFast
@since 16/09/2026
@param cOP, caractere, Numero da ordem de producao (SH6->H6_OP)
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681EmpOP(cOP, cEndereco)

	Local cChaveOP := xFilial("SD4") + cOP

	DbSelectArea("SD4")
	SD4->(DbSetOrder(2)) // D4_FILIAL+D4_OP

	If SD4->(DbSeek(cChaveOP))

		While SD4->(!Eof()) .And. SD4->(D4_FILIAL + D4_OP) == cChaveOP

			MT681EmpItem(cEndereco)

			SD4->(DbSkip())

		EndDo

	EndIf

Return Nil

/*/{Protheus.doc} MT681EmpItem
Trata o empenho do componente posicionado na SD4: busca o saldo no endereco de processo (SBF) e,
conforme o controle do produto (SB1), preenche o lote do empenho e/ou gera o empenho por endereco
na SDC.
@type static function
@author ThinkFast
@since 16/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681EmpItem(cEndereco)

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD

	If !SB1->(DbSeek(xFilial("SB1") + SD4->D4_PRODUTO))
		Return Nil
	EndIf

	DbSelectArea("SBF")
	SBF->(DbSetOrder(1)) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE

	If !SBF->(DbSeek(xFilial("SBF") + SD4->D4_LOCAL + cEndereco + SD4->D4_PRODUTO))
		Return Nil
	EndIf

	If SB1->B1_RASTRO == "L"
		RecLock("SD4", .F.)
			SD4->D4_LOTECTL := SBF->BF_LOTECTL
		MsUnLock()
	EndIf

	If SB1->B1_LOCALIZ == "S"
		MT681GrvSDC(cEndereco)
	EndIf

Return Nil

/*/{Protheus.doc} MT681GrvSDC
Gera o empenho por endereco na SDC para o componente posicionado na SD4, caso ainda nao exista
empenho por endereco para o produto/armazem/OP/operacao.
@type static function
@author ThinkFast
@since 16/09/2026
@param cEndereco, caractere, Endereco de processo da ordem de producao (SC2->C2_ITEMCTA)
@return Nil
/*/
Static Function MT681GrvSDC(cEndereco)

	Local cChaveSDC := xFilial("SDC") + SD4->(D4_PRODUTO + D4_LOCAL + D4_OP + D4_TRT)

	DbSelectArea("SDC")
	SDC->(DbSetOrder(2)) // DC_FILIAL+DC_PRODUTO+DC_LOCAL+DC_OP+DC_TRT+DC_LOTECTL+DC_NUMLOTE

	If !SDC->(DbSeek(cChaveSDC))

		RecLock("SDC", .T.)
			SDC->DC_FILIAL  := xFilial("SDC")
			SDC->DC_PRODUTO := SD4->D4_PRODUTO
			SDC->DC_LOCAL   := SD4->D4_LOCAL
			SDC->DC_OP      := SD4->D4_OP
			SDC->DC_TRT     := SD4->D4_TRT
			SDC->DC_LOCALIZ := cEndereco
			SDC->DC_LOTECTL := SD4->D4_LOTECTL
			SDC->DC_NUMLOTE := SD4->D4_NUMLOTE
			SDC->DC_QUANT   := SD4->D4_QUANT
			If SDC->(FieldPos("DC_QTDORIG")) > 0
				SDC->DC_QTDORIG := SD4->D4_QUANT
			EndIf
		MsUnLock()

	EndIf

Return Nil
