VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:ServiceValidation
Private db As DbAccess
Private je As EntityJe
Private tb As EntityTb

Public Sub Initialize(ByRef context As ContextManager)
    Set db = context.DbValid
    Set je = context.je
    Set tb = context.tb
End Sub

Public Function Completeness() As Boolean
    '這裡應該明確詳細的描述完整性測試
    '...
    Dim sql As String
    Dim dtStart As String   'CDate
    Dim dtEnd As String     'CDate
    Dim JE_In_Period As String
    Dim JE_Account_Sum As String
    Dim Completeness_Calculate As String
    
    '篩選期間內資料
    JE_In_Period = "JE_In_Period"
    sql = "SELECT * " & _
          "FROM " & je.Name & _
          "WHERE " & je.PostDate & _
          "BETWEEN " & dtStart & " AND " & dtEnd & ";"
    
    '依 JE 傳票編號彙總金額
    JE_Account_Sum = "JE_Account_Sum"
    sql = "SELECT " & _
          "  [科目編號_JE], " & _
          "  SUM([傳票金額_JE]) AS [傳票金額_JE_SUM] " & _
          "INTO " & JE_Account_Sum & " " & _
          "FROM " & JE_In_Period & " " & _
          "GROUP BY [科目編號_JE];"
    
    '以科目編號為鍵值，將 JE 彙總結果與 TB 做 LEFT JOIN
    Completeness_Calculate = "Completeness_Calculate"
    sql = "SELECT " & _
          "  P.*, " & _
          "  S.*, " & _
          "FROM " & JE_Account_Sum & " AS P " & _
          "LEFT JOIN " & tb.Name & " AS S " & _
          "ON " & _
          "  P.[科目編號_JE] = S.[科目編號_TB] " & _
          "UNION ALL " & _
          "SELECT " & _
          "  P2.*, " & _
          "  S2.*, " & _
          "FROM " & tb.Name & " AS S2 " & _
          "LEFT JOIN " & JE_Account_Sum & " AS P2 " & _
          "ON " & _
          "  P2.[科目編號_JE] = S2.[科目編號_TB] " & _
          "WHERE " & _
          "  P2.[科目編號_JE] IS NULL;"
    
    '[變動金額_TB] - [傳票金額_JE_SUM]
    '@If( [科目編號_JE] <> 0,  [科目編號_JE] , [科目編號_TB] )
    
    '#Completeness_calculate [ACCOUNT_NUM_ALL]: IFF([會計科目編號_JE], [會計科目編號_JE], [會計科目編號_TB])
    
    
    '#Completeness_calculate (遷移欄位資料)
    
    
End Function
    
Public Function DocumentBalance() As Boolean
    '#GL -> #GL_In_Period
    'WHERE [DATE] BETWEEN [START] AND [END]
    
    '#GL_In_Period -> #GL_In_Period_Doc_Sum
    'SUM([傳票金額_JE]) GROUP BY [傳票號碼_JE]
    
    '#GL_In_Period_Doc_Sum -> #GL_In_Period_Doc_Sum_Diff
    '[變動金額_TB] - [傳票金額_JE_SUM]
    
    '#GL_In_Period_Doc_Sum_Diff -> #GL_Doc_Not_Balance
    
    
    
End Function

Public Function INF() As Boolean
    
End Function


