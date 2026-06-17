#Include "Protheus.ch"
#Define USADO Chr(0)+Chr(0)+Chr(1)
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MA261CPO ³ Autor ³ 	    ³ Data ³02/12/2018					  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³	Incluir campos na rotina de transferencia				        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ OBL      		   ³ 								                 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function MA261CPO()
 
    Local aTam   := {}
    Local cCampo := "D3_XUSER" // Campo customizado na SX3
 
    If SX3->(DbSeek(cCampo))
 
        aTam := TamSX3(cCampo)
 
        AAdd(aHeader, { ;
            RetTitle(cCampo), ;         // 1  - Titulo do Campo do Usuário
            cCampo, ;                   // 2  - Nome do campo do Usuário
            PesqPict("SD3", cCampo), ;  // 3  - PesqPict - Picture do campo do Usuário
            aTam[1], ;                  // 4  - Tamanho
            aTam[2], ;                  // 5  - Decimal
            "", ;                       // 6  - Validação/Função
            USADO, ;                    // 7  - Usado
            aTam[3], ;                  // 8  - Tipo (C, N, D)
            "SD3", ;                    // 9  - Alias
            "" ;                        // 10 - Contexto
        })
 
    EndIf
 
Return Nil


