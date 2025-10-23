VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DataTransferObject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: DataTransferObject
' Purpose: 用於在 View 和 Service 之間傳遞參數
'          並解藕 View 和 Entity 之間的直接依賴
'
' Usage Pattern:
'   [ViewImport] → (建立臨時 DTO) → [RaiseEvent Submitted(dto)]
'        ↓
'   [ApplicationMain] → (驗證 dto) → (dto.CopyTo context.ProjectDto)
'        ↓
'   [ContextManager] → (context.SyncDtoToEntity) → [EntityInfo]
'===============================================================================
'-- 成員
Public DateWeekend As Collection
Public DateHoliday As Collection
Public DateMakeUpDay As Collection
Public CompanyName As String
Public PeriodStart As Date
Public PeriodEnd As Date
Public PrepStartDate As Date

Public Sub Initialize()
    Set DateWeekend = New Collection
    Set DateHoliday = New Collection
    Set DateMakeUpDay = New Collection
    CompanyName = ""
    PeriodStart = DateSerial(Year(Date), 1, 1)
    PeriodEnd = DateSerial(Year(Date), 12, 31)
    PrepStartDate = Date
End Sub
