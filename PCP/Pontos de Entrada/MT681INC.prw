User Function MT681INC 

Local cLocaliz := ""

Local aAreaSDA    := SDA->(GetArea())
Local aAreaSDB    := SDB->(GetArea())
Local aAreaSD3    := SD3->(GetArea())
Local aAreaSB1    := SB1->(GetArea())

cLocaliz := Alltrim(SC2->C2_ITEMCTA)

DbSelectArea("SB1")
SB1->( dbsetorder(1) ) // DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA                                                                                       
SB1->( dbseek( SD3->D3_FILIAL + SD3->D3_COD )) 



If SB1->B1_LOCALIZ == 'S' .And. SD3->D3_LOCAL $ '97'

	lRet := A100Distri(SD3->D3_COD, "97", SD3->D3_NUMSEQ, SD3->D3_DOC, Nil, Nil, Nil, cLocaliz, SD3->D3_NUMSERI, SD3->D3_QUANT, SD3->D3_LOTECTL, SD3->D3_NUMLOTE, Nil, Nil, Nil, Nil, SD3->D3_QUANT)

    If !lRet
        AVISO("U_M185GRV","Erro ao endereçar automaticamente no armazem de processo!!!!!",{"Retornar"})
    EndIf

EndIf


RestArea(aAreaSB1)
RestArea(aAreaSDA)
RestArea(aAreaSDB)
RestArea(aAreaSD3)

 
 
 
 Return Nil
