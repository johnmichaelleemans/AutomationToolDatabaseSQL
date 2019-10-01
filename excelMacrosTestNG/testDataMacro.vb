'Tools > References > Microsoft VBScript Regular Expressions 5.5
Sub testDataMacro()
    Dim ws As Worksheet
    Dim mWB As Workbook
    Set mWB = ActiveWorkbook
    Dim wsNew As Worksheet
    Set wsNew = ThisWorkbook.Sheets.Add(After:= _
        ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count))
    wsNew.Name = "databaseData"
    For Each ws In ActiveWorkbook.Worksheets
        Dim wsName As String
        wsName = ws.Name
        If ((wsName <> "Business_Flow") And (wsName <> "databaseData")) Then
            ws.Select
            Dim regEx As New RegExp
            Dim patternForEnv As String
            patternForEnv = "(.*)(?=_Data_*\d*)"
            regEx.Global = True
            regEx.MultiLine = True
            regEx.IgnoreCase = False
            regEx.Pattern = patternForEnv
            Dim matches As MatchCollection
            Set matches = regEx.Execute(wsName)
            Dim outputENV As String
            If matches.Count > 0 Then
                outputENV = matches(0).Value
            Else
                outputENV = ""
            End If
            
            Dim regExDataSet As New RegExp
            Dim patternForDataSet As String
            patternForDataSet = "\d+"
            regEx.Global = True
            regEx.MultiLine = True
            regEx.IgnoreCase = False
            regEx.Pattern = patternForDataSet
            Dim matchesData As MatchCollection
            Set matchesData = regEx.Execute(wsName)
            Dim outputDataSet As String
            If matchesData.Count > 0 Then
                outputDataSet = matchesData(0).Value
                outputDataSet = outputDataSet + 1
            Else
                outputDataSet = "1"
            End If
            
            'find iteration column and subiteration column
            Dim IterationCol As Integer
            Dim SubIterCol As Integer
            Dim RotationCol As Integer
            Dim TcidCol As Integer
            FinalHeaderCol = Cells(1, Columns.Count).End(xlToLeft).Column
            For Header = 1 To FinalHeaderCol
                If (Cells(1, Header) = "Iteration") Then
                    IterationCol = Header
                ElseIf (Cells(1, Header) = "SubIteration") Then
                    SubIterCol = Header
                ElseIf (Cells(1, Header) = "Rotation") Then
                    RotationCol = Header
                ElseIf (Cells(1, Header) = "Tcid") Then
                    TcidCol = Header
                End If
            Next Header
            FinalRow = Cells(Rows.Count, 1).End(xlUp).Row
            For x = 2 To FinalRow
                Dim nameTest As String
                nameTest = Cells(x, 1)
                Iteration = Cells(x, IterationCol)
                FinalCol = Cells(x, Columns.Count).End(xlToLeft).Column
                For y = 2 To FinalCol
                    If (y <> IterationCol And y <> SubIterCol And y<>RotationCol And y<>TcidCol) Then
                        Dim columnName As String
                        Dim columnValue As String
                        columnName = Cells(1, y)
                        columnValue = Cells(x, y)
                        Cells(x, y).Copy
                        If (columnValue <> "" And columnName <> "") Then
                            'ID , Attribute, Value , ENV, DataSet-1, Change, Iteration, BD_ID
                            Sheets("databaseData").Select
                            NextRow = Cells(Rows.Count, 1).End(xlUp).Row + 1
                            Cells(NextRow, 1) = nameTest
                            Cells(NextRow, 2) = columnName
                            Cells(NextRow, 3).Select
                            ActiveSheet.Paste
                            Cells(NextRow, 4) = outputENV
                            Cells(NextRow, 5) = "DataSet-" + outputDataSet
                            'Cells(NextRow, 6) = changePriority
                            Cells(NextRow, 7) = Iteration
                            Cells(NextRow, 8) = 1
                            ws.Select
                        End If
                    End If
                Next y
            Next x
        End If
    Next ws
End Sub



