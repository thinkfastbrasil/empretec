User Function A650LEMP

Local aLinCol:= aClone(PARAMIXB)  //Conteúdo da linha do aCols posicionado
Local cRetLocal := aLinCol[3]// Verifica se o produto é 'MP' e o Armazém é '87' altera conteúdo para '20'

If (aLinCol[3]=='11')

  cRetLocal := '91'

EndIf

Return cRetLocal
