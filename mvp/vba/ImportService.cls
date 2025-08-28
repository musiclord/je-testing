VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ImportService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:ImportService
'負責匯入資料，使用 Access 精靈匯入
Private db As DbAccess
Private gl As EntityGl
Private tb As EntityTb
Private m_Ace As New Access.Application

Public Sub Initialize(context As ContextManager)
    Set db = context.DbInput
    Set gl = context.gl
    Set tb = context.tb
End Sub

Public Sub OpenWizard(ByVal dataType As String)
    m_Ace.OpenCurrentDatabase db.path
    m_Ace.Visible = False
    Select Case dataType
        Case "excel"
            m_Ace.DoCmd.RunCommand acCmdImportAttachExcel
        Case "csv"
            m_Ace.DoCmd.RunCommand acCmdImportAttachText
        Case Else
            MsgBox "不支援的資料類型！", vbExclamation, "匯入程序"
    End Select
    '匯入結束後要檢查欄位型別是否正確
    '...
    
End Sub

Public Function ApplyGl(ByVal dict As Dictionary) As Boolean
    ApplyGl = False
    Dim key As Variant
    For Each key In dict.Keys
        gl.SetField key, dict(key)
    Next key
    gl.PrintFields
    ApplyGl = True
End Function

Public Function ApplyTb(ByVal dict As Dictionary) As Boolean
    ApplyTb = False
    Dim key As Variant
    For Each key In dict.Keys
        tb.SetField key, dict(key)
    Next key
    tb.PrintFields
    ApplyTb = True
End Function

Public Function ProcessGlAmount(ByVal method As Long) As Boolean
    ProcessGlAmount = False
    Dim sql As String
    Dim affected As Long
    Select Case method
        Case 1
            '直接使用原始金額欄位
            affected = db.ExecuteNonQuery( _
                "UPDATE " & gl.Name & " " & _
                "SET " & _
                "" _
            )
        Case 2
            '借方金額 - 貸方金額
        Case 3
            '依據借貸別標誌決定金額正負號
        Case Else
            Debug.Print "不支援的金額處理方式"
    End Select
    ProcessGlAmount = True
End Function

Public Function ProcessTbAmount(ByVal method As Long) As Boolean
    ProcessTbAmount = False
    Dim sql As String
    Dim affected As Long
    Select Case method
        Case 1
            '直接使用變動金額
        Case 2
            '期末 - 期初 = 變動金額
        Case 3
            '借方 - 貸方 = 變動金額
        Case 4
            '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
        Case Else
            Debug.Print "不支援的金額處理方式"
    End Select
    ProcessTbAmount = True
End Function
