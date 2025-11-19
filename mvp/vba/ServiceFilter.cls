VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class:    ServiceFilter
' Purpose:  管理篩選條件作業的服務
'
' Note:     這裡主要負責執行篩選條件，管理篩選條件由 ServiceFilterCriteria 負責
'           因此該服務主要職責應該是負責運行篩選條件的程序，
'===============================================================================
Private m_Db As DbAccess
Private m_Context As ContextManager
Private m_Schema As DbSchema
Private m_CriteriaSet As Dictionary 'key:String, item:ServiceFilterCriteria

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Schema = context.DbSchema
    Set m_Context = context
    Set m_CriteriaSet = New Dictionary
End Sub

'===============================================================================
' Filter Current
'===============================================================================

'-------------------------------------------------------------------------------
' 增加一個條件組合至集合內（key = 使用情境名稱）
'-------------------------------------------------------------------------------
Public Function AddCriteria(ByVal key As String) As Boolean
    On Error GoTo ErrorHandler
    AddCriteria = False
    Dim criteria As New ServiceFilterCriteria
    Call criteria.Initialize(m_Context)
    Call m_CriteriaSet.Add(criteria, key)
    AddCriteria = True
    Exit Function
ErrorHandler:
    AddCriteria = False
End Function

'-------------------------------------------------------------------------------
' 移除指定鍵值的條件組合
'-------------------------------------------------------------------------------
Public Function RemoveCriteria(ByVal key As String) As Boolean
    On Error GoTo ErrorHandler
    RemoveCriteria = False
    ' key 已經由使用者輸入過，因此前端的 ListBox 可以選擇目前儲存的條件組合
    ' 使用者選取後，傳入參數為 key 來指定使用者選擇的條件組合做移除
    Call m_CriteriaSet.Remove(key)
    RemoveCriteria = True
    Exit Function
ErrorHandler:
    RemoveCriteria = False
End Function

'-------------------------------------------------------------------------------
' 增加一個篩選條件至「指定鍵值」的條件組合內
'-------------------------------------------------------------------------------
Public Function AddCriterion(ByVal key As String, ByVal criterion As Dictionary) As Boolean
    On Error GoTo ErrorHandler
    AddCriterion = False
    Dim criteria As ServiceFilterCriteria
    Set criteria = GetCriteria(key)
    Call criteria.AddCriterion(criterion)
    AddCriterion = True
    Exit Function
ErrorHandler:
    AddCriterion = False
End Function

'-------------------------------------------------------------------------------
' 移除指定條件組合鍵值的篩選條件
'-------------------------------------------------------------------------------
Public Function RemoveCriterion(ByVal key As String, ByVal index As Long) As Boolean
    On Error GoTo ErrorHandler
    RemoveCriterion = False
    Dim criteria As ServiceFilterCriteria
    Set criteria = GetCriteria(key)
    Call criteria.RemoveCriterion(index)
    RemoveCriterion = True
    Exit Function
ErrorHandler:
    RemoveCriterion = False
End Function

'-------------------------------------------------------------------------------
' 取出指定鍵值的條件組合（內部使用）
'-------------------------------------------------------------------------------
Private Function GetCriteria(ByVal key As String) As ServiceFilterCriteria
    On Error Resume Next '若已存在 key 則忽略
    Set GetCriteria = m_CriteriaSet(key)
    On Error GoTo 0
End Function

'===============================================================================
' For Filter Legacy
'===============================================================================
' 設置條件組合，傳入參數為該條件組合的鍵值及對應的字典
'-------------------------------------------------------------------------------
Public Sub MapLegacyState(ByVal key As String, ByVal criteria As Dictionary)
    If criteria("chkPostedOnWeekend") Then Call AddWeekendCriterion(key:="PostedOnWeekend", field:=m_Schema.JE.PostDate)
    m_CriteriaSet.Add key, criteria
End Sub

'-------------------------------------------------------------------------------
' 新增日期區間條件
'-------------------------------------------------------------------------------
Public Function AddDateRangeCriterion(ByVal key As String, ByVal field As String, ByVal startDate As Date, ByVal endDate As Date) As Boolean
    Dim dict As New Dictionary
    dict("Type") = "Date"
    dict("Field") = field
    dict("Operator") = "BETWEEN"
    dict("Value") = Array(startDate, endDate)
    dict("Logic") = "AND"
    dict("Description") = field & " 介於 " & Format(startDate, "yyyy/mm/dd") & " 和 " & Format(endDate, "yyyy/mm/dd")
    
    AddDateRangeCriterion = AddCriterion(key, dict)
End Function

'-------------------------------------------------------------------------------
' 新增數值區間條件
'-------------------------------------------------------------------------------
Public Function AddNumericRangeCriterion(ByVal key As String, ByVal field As String, ByVal minVal As Double, ByVal maxVal As Double) As Boolean
    Dim dict As New Dictionary
    dict("Type") = "Numeric"
    dict("Field") = field
    dict("Operator") = "BETWEEN"
    dict("Value") = Array(minVal, maxVal)
    dict("Logic") = "AND"
    dict("Description") = field & " 介於 " & minVal & " 和 " & maxVal
    
    AddNumericRangeCriterion = AddCriterion(key, dict)
End Function

'-------------------------------------------------------------------------------
' 新增關鍵字條件
'-------------------------------------------------------------------------------
Public Function AddKeywordCriterion(ByVal key As String, ByVal field As String, ByVal keyword As String) As Boolean
    Dim dict As New Dictionary
    dict("Type") = "Keyword" ' 或 Text
    dict("Field") = field
    dict("Operator") = "LIKE"
    dict("Value") = keyword
    dict("Logic") = "AND"
    dict("Description") = field & " 包含 '" & keyword & "'"
    
    AddKeywordCriterion = AddCriterion(key, dict)
End Function

'-------------------------------------------------------------------------------
' 新增週末條件 (需要 DateDimension 支援，這裡示範概念)
'-------------------------------------------------------------------------------
Public Function AddWeekendCriterion(ByVal key As String, ByVal field As String) As Boolean
    ' 實務上這裡應該呼叫 ServiceDateDimension 取得週末日期陣列
    ' 這裡先用假資料示範結構
    ' Dim weekendDates As Variant
    ' weekendDates = m_DateDim.GetWeekendDates(...)
    
    ' 假設我們有一個方法取得日期陣列
    ' Dim dict As New Dictionary
    ' dict("Type") = "Date"
    ' dict("Field") = field
    ' dict("Operator") = "IN"
    ' dict("Value") = weekendDates
    ' ...
    ' AddWeekendCriterion = AddCriterion(key, dict)
    
    ' 暫時回傳 True 以通過編譯
    AddWeekendCriterion = True
End Function
