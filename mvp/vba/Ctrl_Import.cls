VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Import"
'===============================================================================
' Module:   Ctrl_Import
' Purpose:  匯入功能控制器，協調檔案匯入流程和錯誤處理
' Layer:    Controller
' Domain:   Import Processing
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ImportService As Svc_Import
'--事件表單
Private WithEvents viewImport As View_Import
Attribute viewImport.VB_VarHelpID = -1


'--TEMPORARY DEFAULT PRESET
Private Sub UseDefault()
    '預設 GL 欄位
    viewImport.GL_HandlingMethod.Text = "借方與貸方金額"
    viewImport.GL_AccountName.Text = "會計科目"
    viewImport.GL_AccountNumber.Text = "傳票號碼"
    viewImport.GL_EntryAmount.Text = "傳票金額"
    viewImport.GL_DocumentNumber.Text = "傳票號碼"
    viewImport.GL_DebitAmount.Text = "本幣借方金額"
    viewImport.GL_CreditAmount.Text = "本幣貸方金額"
    viewImport.GL_EntryDescription.Text = "摘要"
    viewImport.GL_IsDebit.Text = "借貸"
    viewImport.GL_PostDate.Text = "日期"
    '預設 TB 欄位
    viewImport.TB_HandlingMethod.Text = "借方與貸方金額"
    viewImport.TB_AccountName.Text = "項目名稱"
    viewImport.TB_AccountNumber.Text = "會計項目"
    viewImport.TB_ChangeAmount.Text = "借-貸(本幣)"
    viewImport.TB_DebitAmount.Text = "原幣借方金額"
    viewImport.TB_CreditAmount.Text = "原幣貸方金額"
    '預設期間
    viewImport.Date_Start.Text = "2024/01/01"
    viewImport.Date_End.Text = "2024/12/31"
End Sub

'--Ctrl_Import
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_ImportService = New Svc_Import
    Set viewImport = New View_Import
    '初始化
    m_ImportService.Initialize m_ctx
    UseDefault
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = "Execute"
    On Error GoTo Errorhandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewImport.Show vbModeless
    '檢查處理狀態
    result.Add "import_gl", True
    result.Add "import tb", True
    result.Add "import_holiday", True
    
    Set Execute = result
    Exit Function
    
Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--View_Import
Private Sub viewImport_DoExit()
    Const METHOD_NAME As String = "viewImport_DoExit"
    viewImport.Hide
End Sub

Private Sub viewImport_AddLineItem()
    Const METHOD_NAME As String = "viewImport_AddLineItem"
    
    If Not m_ImportService.AddLineItem() Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 新增項次失敗。"
    End If
End Sub

Private Sub viewImport_ImportGL()
    Const METHOD_NAME As String = "viewImport_ImportGL"
    
    '選取CSV路徑
    Dim filePath As String
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportGL(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入GL"
    Else
        '匯入成功，更新欄位控制項
        Dim fields As Variant
        fields = m_ctx.dalPbc.GetTableSchema(m_ctx.gl.name)
        If IsArray(fields) Then
            viewImport.UpdatePageGL fields
        End If
    End If
End Sub

Private Sub viewImport_ImportTB()
    Const METHOD_NAME As String = "viewImport_ImportTB"
    
    Dim filePath As String
    '選取CSV路徑
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportTB(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入TB"
    Else
        '匯入成功，更新欄位控制項
        Dim fields As Variant
        fields = m_ctx.dalPbc.GetTableSchema(m_ctx.gl.name)
        If IsArray(fields) Then
            viewImport.UpdatePageTB fields
        End If
    End If
End Sub

Private Sub viewImport_ApplyGL()
    Const METHOD_NAME As String = "viewImport_ApplyGL"
    
    Dim mapping As Dictionary
    Set mapping = viewImport.GetGLMapping()
    If Not m_ImportService.ApplyGLMapping(mapping) Then
        MsgBox "GL 欄位映射失敗", vbCritical, "GL欄位"
    Else
        '欄位映射成功
    End If
End Sub

Private Sub viewImport_ApplyTB()
    Const METHOD_NAME As String = "viewImport_ApplyTB"
    '標準化欄位名稱至 Ent_FieldsTB
    
    Dim mapping As Dictionary
    Set mapping = viewImport.GetTBMapping()
    If Not m_ImportService.ApplyTBMapping(mapping) Then
        MsgBox "TB 欄位映射失敗", vbCritical, "TB欄位"
    Else
        '欄位映射成功
    End If
End Sub
