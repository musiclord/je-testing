Attribute VB_Name = "Util"
Option Explicit
Private m_App As New ApplicationMain

Public Sub Launch()
    m_App.Initialize
    m_App.Run
End Sub
