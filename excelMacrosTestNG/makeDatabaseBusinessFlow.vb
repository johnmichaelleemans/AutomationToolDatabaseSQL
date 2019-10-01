Sub businessFlow(env As String)
    Dim ws As Worksheet
    Dim mWB As Workbook
    Set mWB = ActiveWorkbook
    Dim wsNew As Worksheet
    Set wsNew = ThisWorkbook.Sheets.Add(After:= _
        ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
    wsNew.Name = "copyBusinessFlow"
    
    Set ws = mWB.Sheets("Business_Flow")
    ws.Select
    FinalRow = Cells(Rows.Count, 1).End(xlUp).Row
    For x = 2 To FinalRow
        Dim nameTest As String
        nameTest = Cells(x, 1)
        Cells(x, 1).Copy
        FinalCol = Cells(x, Columns.Count).End(xlToLeft).Column
        For y = 2 To FinalCol
            Cells(x, y).Copy
            Sheets("copyBusinessFlow").Select
            NextRow = Cells(Rows.Count, 1).End(xlUp).Row + 1
            Cells(NextRow, 1) = nameTest
            Cells(NextRow, 2) = env
            Cells(NextRow, 3).Select
            ActiveSheet.Paste
            Cells(NextRow, 4) = (y - 1)
            ws.Select
        Next y
    Next x
    
End Sub

Sub makeBusinessFlow()
    Dim myValue As Variant
    myValue = InputBox("ENTER ENV")
    businessFlow (myValue)
End Sub

