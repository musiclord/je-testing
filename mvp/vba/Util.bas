Attribute VB_Name = "Util"
Option Explicit
Private m_App As New ApplicationMain

Public Sub Launch()
    m_App.Initialize
    m_App.Run
End Sub

'-- 查詢輔助語法
Public Function Nz(ByVal fieldName As String, Optional ByVal defaultValue As String = "0") As String
    ' 將欄位名稱轉換成 IIF(ISNULL(...),defaultValue,...) SQL 語法
    fieldName = Trim$(fieldName)
    ' 如果 fieldName 包含空格或特殊字元，用方括號包圍
    fieldName = "[" & fieldName & "]"
    Nz = "IIF(ISNULL(" & fieldName & ")," & defaultValue & "," & fieldName & ")"
End Function
