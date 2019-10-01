Sub newDatabaseObjects(env As String)
    Dim ws As Worksheet
    Dim wsNew As Worksheet
    Set wsNew = ThisWorkbook.Sheets.Add(After:= _
        ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
    wsNew.Name = "copyDatabaseSheet"
    For Each ws In ActiveWorkbook.Worksheets
        If ws.Name <> "copyDatabaseSheet" Then
            ws.Select
            FinalRow = Cells(Rows.Count, 1).End(xlUp).Row
            For x = 2 To FinalRow
                Cells(x, 2) = LCase(Cells(x, 2))
                Cells(x, 1).Resize(1, 3).Copy
                Sheets("copyDatabaseSheet").Select
                NextRow = Cells(Rows.Count, 3).End(xlUp).Row + 1
                Cells(NextRow, 3).Select
                ActiveSheet.Paste
                Cells(NextRow, 1) = env
                Cells(NextRow, 2) = ws.Name
                ws.Select
            Next x
        End If
    Next ws
End Sub

    
Sub makeDatabaseObjects()
    Dim myValue As Variant
    myValue = InputBox("ENTER ENV")
    newDatabaseObjects(myValue)
End Sub
