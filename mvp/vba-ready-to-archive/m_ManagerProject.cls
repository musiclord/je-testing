VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ManagerProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ManagerProject
' Purpose:  處理專案服務，依據指定專案資訊獨立出目錄及組態
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ManagerProject"

' === 變數 ===
Private m_Id As String
Private m_Name As String
Private m_Path As String

' === 屬性 ===
Public Property Let Id(ByVal Name As String)
    m_Id = Id
End Property
Public Property Get Id() As String
    Id = m_Id
End Property
Public Property Let Name(ByVal Name As String)
    m_Name = Name
End Property
Public Property Get Name() As String
    Name = m_Name
End Property
Public Property Let Path(ByVal Name As String)
    m_Path = Path
End Property
Public Property Get Path() As String
    Path = m_Path
End Property


Private Function Create(project As String) '創建專案
    ' 1. 檢查目錄 & 指定路徑
    
    ' 2. 創建資料庫 & 組態
    
End Function

Private Function Load(project As String)   '載入專案
    ' 1. 檢查目錄 & 指定路徑
    
    ' 2. 讀取資料庫 & 組態
    
End Function

Private Function Delete(project As String) '刪除專案
    ' 1. 檢查 & 指定根目錄
    
    ' 2. 刪除指定子目錄
    
End Function


