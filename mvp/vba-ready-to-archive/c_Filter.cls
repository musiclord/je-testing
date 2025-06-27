VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Filter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Filter
' Purpose:  篩選條件程序的控制器
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "c_Filter"

' === 介面事件 ===
Private WithEvents viewFilter As v_Filter
Attribute viewFilter.VB_VarHelpID = -1
Private WithEvents viewFilterSummarize As v_FilterSummarize
Attribute viewFilterSummarize.VB_VarHelpID = -1

