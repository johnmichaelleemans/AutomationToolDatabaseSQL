Sub NewMacro()
    For Each cell In Selection
        cell.Formula = "'" & cell.Value
        Next
End Sub