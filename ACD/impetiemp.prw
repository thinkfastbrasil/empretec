Static sModeloZebra  :="|S500-6|Z105S-6|Z160S-6|S300|S400|S500-8|Z105S-8|Z160S-8|Z140XI|S600|Z90XI|Z170XI|"
//Static sModeloAllegro:="|ALLEGRO|PRODIGY|DMX|DESTINY|"
//Static sModeloEltron :="|ARGOX|ELTRON|"

#include "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"  
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³IMPETIBLU ³ Autor ³                   ³ Data³ ³            ±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄ Ä Ä Ä Ä Ä Ä Ä Ä Ä Á Ä Ä Ä Ä Ä Á Ä Ä Ä Ä ÄÙ±±
±±³Descri‡„o ³ Impressao de etiquetas de produto avulsa					  ³±±
±±³          ³ conforme os parametros informados pelo usuario             ³±±
±±³          ³ conforme os parametros informados pelo usuario             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Observacao³ Este programa deve ser utilizado somente na implantacao    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ BLU  		                                 			  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function IMPETIEMP()
Private  _aProxEti := {}

If IsTelNet()
	IMPETIBE()
Else
	Processa({||IMPETIEM()})
EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³IMPETINP ³ Autor ³                        ³ Data ³ 22/08/23 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³Execucao da  Funcao Chamada pelo programa IMPETIBLU	      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function IMPETIEM
Local   cCodigo
//Local   lUnit
//Local   lImport
//Local   cLote
//Local   dDtValid
//Local   dEsteril
Local   nQtde, nCopias
//Local   i
//Local   nX, nY
Local   cPerg := If(IsTelNet(),'VTPERGUNTE','PERGUNTE')
Local   cTipoCodBar
Local 	cCodOp := ""

Local cQry := "" //Por Samuel Miranda 06/05/2026


///ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01     // Produto de                                   ³
//³ mv_par02     // Produto ate                                  ³
//³ mv_par03     // Armazem de                                   ³
//³ mv_par04     // Endereco de                                  ³
//³ mv_par05     // Armazem Ate                                  ³
//³ mv_par06     // Endereco Ate                                 ³
//³ mv_par07     // N.Copias para reimpressao de etiquetas       ³
//³ mv_par08     // Local de Impressao                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
// OBS.: O parametro de n.copias somente pode ser lido pelo Administrador do sistema cujo poderah fazer
//       a reimpressao de etiquetas respeitando a quantidade parametrizada em MV_PAR10
//

AjustaSX1()
IF ! &(cPerg)("ETIQEM",.T.)
	Return
EndIF
If IsTelNet()
	VtMsg('Imprimindo')
EndIF

If ! CB5SetImp(MV_PAR08,IsTelNet())
	IF ! IsTelNet()
		Alert('Codigo do tipo de impressao invalido')
	Else
		VTAlert('Codigo do tipo de impressao invalido')
	EndIf
	Return .f.
EndIF
If IsTelNet()
	VtMsg('Imprimindo')
EndIf

If Trim(CB5->CB5_MODELO)+'|' $ sModeloZebra
	cTipoCodBar	:= 'C'
Endif

SB1->(dbsetOrder(1))

If !SB1->(dbSeek(xFilial("SB1")+MV_PAR01))
	IF ! IsTelNet()
		Alert('Produto nao existe!')
	Else
		VTAlert('Produto nao existe!')
	EndIf
	Return .f.
Endif

cQry :="SELECT" 
cQry += "SB1.B1_COD AS CODDPRO, "+CHR(13)+CHR(10)
cQry += "SB1.B1_CODBAR AS CODBARRA "+CHR(13)+CHR(10)
cQry += "FROM "+CHR(13)+CHR(10)
cQry += RetSqlName("SB1")+" SB1 "+CHR(13)+CHR(10)
cQry += "WHERE "+CHR(13)+CHR(10)
cQry += "SB1.B1_COD BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR01+"' AND SB1.D_E_L_E_T_='' "+CHR(13)+CHR(10)

dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQry ), "NSB1", .T., .T. )
dbSelectArea("NSB1")
dbGotop()

While !NSB1->(Eof())

	SB1->(dbSeek(xFilial()+NSB1->CODDPRO ))
	cCodigo  :=  SB1->B1_CODBAR //NSB1->CODBARRA 

	nCopias := MV_PAR07
	nQtde   := 1
	cCodOp	:= MV_PAR09

	//Image das etiquetas de produtos:
	ExecBlock("IMG01",,,{nQtde,,,nCopias,"","","","","",cCodOp,"","","","",""}) 
	//Image da folha de rosto para impressao das etiquetas impares:
	//ExecBlock("IMG00",,,{ProcName()})
EndDo

MSCBCLOSEPRINTER()
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ AjustaSX1    ³Autor ³Henrique Gomes Oikawa ³Data³ 17/06/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Cria o grupo de perguntas no SX1 caso o mesmo nao exista   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function AjustaSX1()
Local cAlias := Alias()
Local aRegistros:={}
Local i,j:=0

aadd(aRegistros,{"ETIQEM","01","Produto de          ","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","SB1","","","",""})
aadd(aRegistros,{"ETIQEM","02","Produto ate         ","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","SB1","","","",""})
aadd(aRegistros,{"ETIQEM","07","Copias             ?",'','','mv_ch7','N',04,0,1,'G','','mv_par07','','','','','','','','','','','','','','','','','   ','',''})
aadd(aRegistros,{"ETIQEM","08","Local de Impressao ?",'','','mv_ch8','C',06,0,0,'G','','mv_par08','','','','','','','','','','','','','','','','','CB5','','',''})

DbSelectArea("SX1")
For i:=1 to Len(aRegistros)
	If !dbSeek(Padr(aRegistros[i,1],10)+aRegistros[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			FieldPut(j,aRegistros[i,j])
		Next j
		MsUnlock()
	EndIf
Next i
dbSelectArea(cAlias)
Return
