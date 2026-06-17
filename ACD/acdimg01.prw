/*
Padrao Zebra
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³img01     ºAutor  ³Sandro Valex        º Data ³  19/06/01   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de entrada referente a imagem de identificacao do     º±±
±±º          ³produto. Padrao Microsiga                                   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function IMG01 //Identificacao de produto - teste
Local cCodigo,sConteudo,cTipoBar, nX
Local nqtde 	:= If(len(paramixb) >= 1,paramixb[ 1],NIL)
Local cCodOp 	:= If(len(paramixb) >= 2,paramixb[ 2],NIL)
Local cCodID 	:= If(len(paramixb) >= 3,paramixb[ 3],NIL)
Local nCopias	:= If(len(paramixb) >= 4,paramixb[ 4],0)
Local cNFEnt  	:= If(len(paramixb) >= 5,paramixb[ 5],NIL)
Local cSeriee  := If(len(paramixb) >= 6,paramixb[ 6],NIL)
Local cFornec  := If(len(paramixb) >= 7,paramixb[ 7],NIL)
Local cLojafo  := If(len(paramixb) >= 8,paramixb[ 8],NIL)
Local cArmazem := If(len(paramixb) >= 9,paramixb[ 9],NIL)
Local cOP      := If(len(paramixb) >=10,paramixb[10],NIL)
Local cNumSeq  := If(len(paramixb) >=11,paramixb[11],NIL)
Local cLote    := If(len(paramixb) >=12,paramixb[12],NIL)
Local cSLote   := If(len(paramixb) >=13,paramixb[13],NIL)
Local dValid   := If(len(paramixb) >=14,paramixb[14],NIL)
Local cCC  		:= If(len(paramixb) >=15,paramixb[15],NIL)
Local cLocOri  := If(len(paramixb) >=16,paramixb[16],NIL)
Local cOPREQ   := If(len(paramixb) >=17,paramixb[17],NIL)
Local cNumSerie:= If(len(paramixb) >=18,paramixb[18],NIL)
Local cOrigem  := If(len(paramixb) >=19,paramixb[19],NIL)
Local cEndereco:= If(len(paramixb) >=20,paramixb[20],NIL)
Local cPedido  := If(len(paramixb) >=21,paramixb[21],NIL)
Local nResto   := If(len(paramixb) >=22,paramixb[22],0)
Local cItNFE   := If(len(paramixb) >=23,paramixb[23],NIL)
Local cTpFonte 	:= "0"
Local cFonte7 		:= "070,070"
Local logoblu := "" 
Local logoblu1:= "" 

//Local c_LotNobel	:= U_fGetLot()

cLocOri := If(cLocOri==cArmazem,' ',cLocOri)
nQtde   := If(nQtde==NIL,SB1->B1_QE,nQtde)
cCodSep := If(cCodSep==NIL,'',cCodSep)
cOP 	:= If(cOP==NIL,'',cOP)

If nResto > 0 
   nCopias++
EndIf

For nX := 1 to nCopias
	If cCodID#NIL
		CBRetEti(cCodID)
		nqtde 	:= CB0->CB0_QTDE
		cCodSep  := CB0->CB0_USUARIO
		cNFEnt   := CB0->CB0_NFENT
		cSeriee  := CB0->CB0_SERIEE
		cFornec  := CB0->CB0_FORNEC
		cLojafo  := CB0->CB0_LOJAFO
		cArmazem := CB0->CB0_LOCAL
		cOP      := CB0->CB0_OP
		cNumSeq  := CB0->CB0_NUMSEQ
		cLote    := CB0->CB0_LOTE
		cSLote   := CB0->CB0_SLOTE
		cCC      := CB0->CB0_CC
		cLocOri  := CB0->CB0_LOCORI
		cOPReq	:= CB0->CB0_OPREQ
		cNumserie:= CB0->CB0_NUMSER		
		cOrigem  := CB0->CB0_ORIGEM
		cEndereco:= CB0->CB0_LOCALI
		cPedido  := CB0->CB0_PEDCOM
		cItNFE 	 := CB0->CB0_ITNFE
	EndIf
   If nResto > 0 .and. nX==nCopias
      nQtde  := nResto
   EndIf
	If Usacb0("01")
		cCodigo := If(cCodID ==NIL,CBGrvEti('01',{SB1->B1_COD,nQtde,cCodSep,cNFEnt,cSeriee,cFornec,cLojafo,cPedido,cEndereco,cArmazem,cOp,cNumSeq,NIL,NIL,NIL,cLote,cSLote,dValid,cCC,cLocOri,NIL,cOPReq,cNumserie,cOrigem,cItNFE}),cCodID)
	Else
		cCodigo := SB1->B1_CODBAR
		nqtde 	:= SB1->B1_QE
	EndIf
	//cCodigo := Alltrim(SB1->B1_XCODANT)
	cTipoBar := 'MB07'
	/*
	If ! Usacb0("01")
		If Len(cCodigo) == 8
			cTipoBar := 'MB03'
		ElseIf Len(cCodigo) == 13
			cTipoBar := 'MB04'
		EndIf
	EndIf
	*/
	cCodigo := Alltrim(cCodigo)
	MSCBLOADGRF("BLU.GRF")
	MSCBBEGIN(1,6)
	MSCBBOX(30,05,60,05)
	MSCBBOX(02,12.7,60,12.7)
	MSCBBOX(02,21,100,21)
	MSCBBOX(30,01,30,12.7)
	MSCBBOX(60,01,60,21)

	MSCBWRITE("^FO25,0") 
	MSCBWRITE("^GFA,2300,2300,25,"+logoblu+logoblu1+"^FS") 

	MSCBSAY(33,02,"PRODUTO","N","0","025,035",,,,,.t.)
	MSCBSAY(33,06,"CODIGO","N","A","012,008")
	MSCBSAY(33,08, AllTrim(SB1->B1_COD), "N", "0", "042,045")
	MSCBSAYBAR(65,05,cCodigo,"N","MB07",12.00,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)
	MSCBSAY(05,14,"CODIGO BLU","N","A","012,008")
	MSCBSAY(05,17,SB1->B1_XCODANT,"N", "0", "020,030")
	MSCBSAY(05,22,"DESCRICAO","N","A","012,008")
	MSCBSAY(05,25,SB1->B1_DESC,"N", "0", "020,030")
	
	
	MSCBInfoEti("Produto","30X100")

	sConteudo:=MSCBEND()
	If Type('cProgImp')=="C" .and. cProgImp=="ACDV120"
	    GravaCBE(CB0->CB0_CODETI,SB1->B1_COD,Transform(nqtde,"@E 9,999"),cLote,dValid)
	EndIf	    
Next
Return sConteudo

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³img01De   ºAutor  ³Sandro Valex        º Data ³  19/06/01   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de entrada referente a imagem de identificacao da     º±±
±±º          ³Unidade de despacho                                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function Img01CX //dispositivo de identificacao de produto
Local cCodigo,sConteudo,cTipoBar, nX
Local nqtde 	:= If(len(paramixb) >= 1,paramixb[ 1],NIL)
Local cCodSep 	:= If(len(paramixb) >= 2,paramixb[ 2],NIL)
Local cCodID 	:= If(len(paramixb) >= 3,paramixb[ 3],NIL)
Local nCopias	:= If(len(paramixb) >= 4,paramixb[ 4],NIL)
Local cArmazem := If(len(paramixb) >= 5,paramixb[ 5],NIL)
Local cEndereco:= If(len(paramixb) >= 6,paramixb[ 6],NIL)

nQtde   := If(nQtde==NIL,SB1->B1_QE,nQtde)
cCodSep := If(cCodSep==NIL,'',cCodSep)

For nX := 1 to nCopias
	If Usacb0("01")
		cCodigo := If(cCodID ==NIL,CBGrvEti('01',{SB1->B1_COD,nQtde,cCodSep,NIL,NIL,NIL,NIL,NIL,cEndereco,cArmazem,,,,,,,,}),cCodID)
	Else
		cCodigo := SB1->B1_CODBAR
	EndIf
	cCodigo := Alltrim(cCodigo)
	cTipoBar := 'MB07' //128
	If ! Usacb0("01")
		If Len(cCodigo) == 8
			cTipoBar := 'MB03'
		ElseIf Len(cCodigo) == 13
			cTipoBar := 'MB04'
		EndIf
	EndIf
	MSCBLOADGRF("SIGA.GRF")
	MSCBBEGIN(1,6)
	MSCBBOX(30,05,76,05)
	MSCBBOX(02,12.7,76,12.7)
	MSCBBOX(02,21,76,21)
	MSCBBOX(30,01,30,12.7,3)
	MSCBGRAFIC(2,3,"SIGA")
	MSCBSAY(33,02,'CAIXA',"N","0","025,035")
	MSCBSAY(33,06,"CODIGO","N","A","012,008")
	MSCBSAY(33,08, AllTrim(SB1->B1_COD), "N", "0", "032,035")
	MSCBSAY(05,14,"DESCRICAO","N","A","012,008")
	MSCBSAY(05,17,SB1->B1_DESC,"N", "0", "020,030")
	MSCBSAYBAR(23,22,cCodigo,"N",cTipoBar,8.36,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)
	MSCBInfoEti("Produto Granel","30X100")
	sConteudo:=MSCBEND()
Next
Return sConteudo

/*
ÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœÃœ
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
Â±Â±Ã‰ÃÃÃÃÃÃÃÃÃÃÃ‘ÃÃÃÃÃÃÃÃÃÃÃ‹ÃÃÃÃÃÃÃÃ‘ÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃ‹ÃÃÃÃÃÃÃ‘ÃÃÃÃÃÃÃÃÃÃÃÃÃÂ»Â±Â±
Â±Â±ÂºPrograma  Â³img01De   ÂºAutor  Â³Sandro Valex        Âº Data Â³  19/06/01   ÂºÂ±Â±
Â±Â±ÃŒÃÃÃÃÃÃÃÃÃÃÃ˜ÃÃÃÃÃÃÃÃÃÃÃŠÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃŠÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÂ¹Â±Â±
Â±Â±ÂºDesc.     Â³Ponto de entrada referente a imagem de identificacao da     ÂºÂ±Â±
Â±Â±Âº          Â³Unidade de despacho                                         ÂºÂ±Â±
Â±Â±ÃŒÃÃÃÃÃÃÃÃÃÃÃ˜ÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÂ¹Â±Â±
Â±Â±ÂºUso       Â³ AP5                                                        ÂºÂ±Â±
Â±Â±ÃˆÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÃÂ¼Â±Â±
Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±Â±
ÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸÃŸ
*/
User Function Img01DE //dispositivo de identificacao de unidade de despacho produto
Local nCopias 	:= If(len(paramixb) >= 1,paramixb[ 1],NIL)
Local cCodigo 	:= If(len(paramixb) >= 2,Alltrim(paramixb[ 2]),NIL)

MSCBLOADGRF("SIGA.GRF")
MSCBBEGIN(nCopias,6)
	MSCBBOX(30,05,76,05)
	MSCBBOX(02,12.7,76,12.7)
	MSCBBOX(02,21,76,21)
	MSCBBOX(30,01,30,12.7,3)
	MSCBGRAFIC(2,3,"SIGA")
	MSCBSAY(33,02,'UNID. DE DESPACHO',"N","0","025,035")
	MSCBSAY(33,06,"CODIGO","N","A","012,008")
	MSCBSAY(33,08, AllTrim(SB1->B1_COD), "N", "0", "032,035")
	MSCBSAY(05,14,"DESCRICAO","N","A","012,008")
	MSCBSAY(05,17,SB1->B1_DESC,"N", "0", "020,030")
	MSCBSAYBAR(23,22,cCodigo,"N","MB01",8.36,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)  // codigo intercaldo 2 e 5 para EAN14
	MSCBInfoEti("Unid.Despacho","30X100")
sConteudo:=MSCBEND()
Return sConteudo


//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±|Rotina    | IMG01DF      |Auto| Samuel Miranda     | Data|  09/12/2023 |±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±|Descricao | impressao de etiqueta Layout compacto				        |±±
//±±|   TAMANHO  60 X 60                                                    |±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±


User Function Img01DF
Local cCodigo
Local sConteudo

	MSCBBEGIN(1,6)
	MSCBCHKStatus(.F.)
	MSCBBEGIN(1,4) 
	MSCBBOX(20,05,60,05)
	MSCBBOX(02,12.7,60,12.7)
	MSCBBOX(02,21,60,21)
	MSCBBOX(20,01,20,12.7,3)
	//MSCBBOX(70,05,90,12.7)
	MSCBBOX(02,30,60,30)
	MSCBBOX(02,30,60,30)
	//MSCBGRAFIC(2,3,"NOBEL")
	//MSCBSAY(05,02,'QTDE:',"N","0","015,025")
	//MSCBSAYBAR(05,01,Transform(nqtde,"@E 9,999"),"N",cTipoBar,8.36,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)
	//MSCBSAY(05,06,AllTrim(SM0->M0_NOMECOM),"N","0","025,025")
	//MSCBSAY(05,04," ","N",cTpFonte,cFonte7)//Logo
	//MSCBSAY(33,02,'PRODUTO NOBEL',"N","0","025,035")
	MSCBSAY(23,02,AllTrim(SM0->M0_NOME),"N","0","022,22")
	MSCBSAY(23,06,"CODIGO","N","A","012,008")
	MSCBSAY(23,08, AllTrim(SB1->B1_COD), "N", "0", "022,022")
	MSCBSAY(05,14,"DESCRICAO","N","A","012,008")
	MSCBSAY(05,16,SB1->B1_DESC,"N", "0", "022,022")
	MSCBSAYBAR(23,22,Alltrim(cCodigo),"N","MB07",4,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)//"N","MB07",5,					
	MSCBSAY(05,32,"OP","N","A","012,008")
	MSCBSAY(40,32,"DIMENSOES","N","A","012,010")
	//MSCBSAY(40,34, AllTrim(Transform(SB1->B1_XALTURA,"@E 9,999"))+"x"+AllTrim(Transform(SB1->B1_XLARGUR,"@E 9,999"))+"x"+AllTrim(Transform(SB1->B1_XSANFON,"@E 9,999")), "N", "0", "030,033")

	MSCBSAY(40,46,"QUANTIDADE","N","A","012,008")
	If !Empty(SB1->B1_SEGUM)  
		MSCBSAY(40,48,Transform(SB1->B1_CONV,"@E 9,999")+" "+SB1->B1_UM  , "N", "0", "022,022")
	else
		MSCBSAY(40,48,"1"+" "+SB1->B1_UM, "N", "0",  "022,022")
	EndIf
	MSCBSAY(05,55,"ID","N","A","012,008")
	//MSCBSAY(05,57,c_LotNobel,"N", "0", "022,022")
	MSCBInfoEti("Produto","60X60")
	//MSCBInfoEti("Produto","30X100")

	sConteudo:=MSCBEND()
	If Type('cProgImp')=="C" .and. cProgImp=="ACDV120"
	    GravaCBE(CB0->CB0_CODETI,SB1->B1_COD,Transform(nqtde,"@E 9,999"),cLote,dValid)
	EndIf	    

Return sConteudo

