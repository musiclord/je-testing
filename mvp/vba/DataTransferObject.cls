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
' ***** 成員
Public CompanyName As String
Public PeriodStart As Date
Public PeriodEnd As Date
Public PrepStartDate As Date
Public NonBusinessDay As Collection
Public Monday As Boolean
Public Tuesday As Boolean
Public Wednesday As Boolean
Public Thursday As Boolean
Public Friday As Boolean
Public Saturday As Boolean
Public Sunday As Boolean

Public Sub Initialize()
    CompanyName = ""
    PeriodStart = DateSerial(Year(Date), 1, 1)
    PeriodEnd = DateSerial(Year(Date), 12, 31)
    PrepStartDate = Date
    Set NonBusinessDay = New Collection
    Monday = True
    Tuesday = True
    Wednesday = True
    Thursday = True
    Friday = True
    Saturday = False
    Sunday = False
End Sub
