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
' Purpose: 用於在 View 和 Service 之間傳遞專案資訊的 DTO
'===============================================================================
' ***** 成員
Public CompanyName As String
Public PeriodStart As Date
Public PeriodEnd As Date
Public PrepStartDate As Date
Public Monday As Boolean
Public Tuesday As Boolean
Public Wednesday As Boolean
Public Thursday As Boolean
Public Friday As Boolean
Public Saturday As Boolean
Public Sunday As Boolean

Public Sub Initialize()
    CompanyName = ""
    PeriodStart = #1/1/1900#
    PeriodEnd = #1/1/1900#
    Monday = True
    Tuesday = True
    Wednesday = True
    Thursday = True
    Friday = True
    Saturday = True
    Sunday = True
End Sub
