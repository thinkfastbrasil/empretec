/*
Padrao Zebra
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³IMG02     ºAutor  ³Sandro Valex        º Data ³  19/06/01   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de entrada referente a imagem de identificacao da     º±±
±±º          ³endereco                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP5                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function IMG02 // imagem de etiqueta de ENDERECO
Local cCodigo
Local cCodID := paramixb[1]
Local cTpFonte 	:= "0"
Local cFonte7 		:= "070,070"
Local logoblu := "" 
Local logoblu1:= "" 


If cCodID # NIL
	cCodigo := cCodID
ElseIf Empty(SBE->BE_IDETIQ)
	If Usacb0('02')
		cCodigo := CBGrvEti('02',{SBE->BE_LOCALIZ,SBE->BE_LOCAL})
		RecLock("SBE",.F.)
		SBE->BE_IDETIQ := cCodigo
		MsUnlock()
	Else
		cCodigo :=SBE->(BE_LOCAL+BE_LOCALIZ)
	EndIf
Else
	If Usacb0('02')
		cCodigo := SBE->BE_IDETIQ
	Else
		cCodigo :=SBE->(BE_LOCAL+BE_LOCALIZ)
	EndIf
Endif

cCodigo := Alltrim(cCodigo)
MSCBLOADGRF("BLU.GRF")
MSCBBEGIN(1,6)
MSCBBOX(30,05,60,05)
MSCBBOX(02,12.7,60,12.7)
MSCBBOX(02,21,100,21)
MSCBBOX(30,01,30,12.7)
MSCBBOX(60,01,60,21)
//MSCBGRAFIC(2,3,"BLU")
//MSCBSAY(05,05,"BLU"		   		,"N",cTpFonte,cFonte7)//Logo

MSCBWRITE("^FO25,0") 
MSCBWRITE("^GFA,2300,2300,25,"+logoblu+logoblu1+"^FS") 


MSCBSAY(33,02,'ENDERECO',"N","0","025,035",,,,,.t.)
MSCBSAY(33,06,"CODIGO","N","A","012,008")
MSCBSAY(33,08, AllTrim(SBE->BE_LOCALIZ), "N", "0", "042,045")
MSCBSAYBAR(65,05,cCodigo,"N","MB07",12.00,.F.,.T.,.F.,,2,1,.F.,.F.,"1",.T.)
MSCBSAY(05,14,"DESCRICAO","N","A","012,008")
MSCBSAY(05,17,SBE->BE_DESCRIC,"N", "0", "020,030")
MSCBInfoEti("Endereco","30X100")
MSCBEND()
Return .F.
