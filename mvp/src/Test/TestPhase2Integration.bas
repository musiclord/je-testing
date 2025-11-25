Attribute VB_Name = "TestPhase2Integration"
Option Explicit

'===============================================================================
' Module: TestPhase2Integration
' Purpose: Comprehensive testing for Phase 2 Services
'
' Usage:
'   1. Prepare test database with sample data
'   2. Run Test_Complete_Workflow in Immediate Window
'   3. Review output and verify results
'===============================================================================

'Test configuration
Private Const TEST_PROJECT_PATH As String = "C:\Temp\JET_Test\test_project.json"
Private Const TEST_INPUT_DB As String = "C:\Temp\JET_Test\input.accdb"
Private Const TEST_VALID_DB As String = "C:\Temp\JET_Test\valid.accdb"

'===============================================================================
' Master Test Runner
'===============================================================================

Public Sub Test_Complete_Workflow()
    '--------------------------------------------------------------------------- 
    ' Runs complete Phase 2 integration test
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    Debug.Print String(80, "=")
    Debug.Print "PHASE 2 INTEGRATION TEST"
    Debug.Print "Start Time: " & Now
    Debug.Print String(80, "=")
    Debug.Print ""
    
    ' Initialize
    Debug.Print "[1/7] Initializing Context..."
    Dim ctx As ContextManager
    Set ctx = Test_InitializeContext()
    If ctx Is Nothing Then GoTo TestFailed
    Debug.Print "    ✓ Context initialized"
    
    ' Database connections
    Debug.Print "[2/7] Connecting to databases..."
    Dim dbSource As DbAccess
    Dim dbTarget As DbAccess
    Set dbSource = Test_ConnectDatabase(ctx, TEST_INPUT_DB, "Source")
    Set dbTarget = Test_ConnectDatabase(ctx, TEST_VALID_DB, "Target")
    If dbSource Is Nothing Or dbTarget Is Nothing Then GoTo TestFailed
    Debug.Print "    ✓ Databases connected"
    
    ' Import Service
    Debug.Print "[3/7] Testing ServiceImport..."
    If Not Test_ServiceImport(ctx, dbSource) Then GoTo TestFailed
    Debug.Print "    ✓ Import service OK"
    
    ' Validation Service
    Debug.Print "[4/7] Testing ServiceValidation..."
    If Not Test_ServiceValidation(ctx, dbSource, dbTarget) Then GoTo TestFailed
    Debug.Print "    ✓ Validation service OK"
    
    ' Filter Service
    Debug.Print "[5/7] Testing ServiceFilter..."
    If Not Test_ServiceFilter(ctx, dbTarget) Then GoTo TestFailed
    Debug.Print "    ✓ Filter service OK"
    
    ' DateDimension Service
    Debug.Print "[6/7] Testing ServiceDateDimension..."
    If Not Test_ServiceDateDimension(ctx, dbTarget) Then GoTo TestFailed
    Debug.Print "    ✓ DateDimension service OK"
    
    ' Export Service
    Debug.Print "[7/7] Testing ServiceExport..."
    If Not Test_ServiceExport(ctx, dbTarget) Then GoTo TestFailed
    Debug.Print "    ✓ Export service OK"
    
    ' Cleanup
    dbSource.Disconnect
    dbTarget.Disconnect
    
    Debug.Print ""
    Debug.Print String(80, "=")
    Debug.Print "✓✓✓ ALL TESTS PASSED ✓✓✓"
    Debug.Print "End Time: " & Now
    Debug.Print String(80, "=")
    Exit Sub
    
TestFailed:
    Debug.Print ""
    Debug.Print String(80, "=")
    Debug.Print "✗✗✗ TESTS FAILED ✗✗✗"
    Debug.Print String(80, "=")
    Exit Sub
    
ErrorHandler:
    Debug.Print "✗ ERROR: " & Err.Description & " (" & Err.Number & ")"
    Resume TestFailed
End Sub

'===============================================================================
' Individual Service Tests
'===============================================================================

Private Function Test_InitializeContext() As ContextManager
    On Error GoTo ErrorHandler
    
    Dim ctx As New ContextManager
    ctx.Initialize TEST_PROJECT_PATH
    
    ' Verify context properties
    Debug.Assert ctx.HasActiveProject = True
    Debug.Assert Not ctx.Logger Is Nothing
    Debug.Assert Not ctx.DbSchema Is Nothing
    
    Set Test_InitializeContext = ctx
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ Context initialization failed: " & Err.Description
    Set Test_InitializeContext = Nothing
End Function

Private Function Test_ConnectDatabase(ByVal ctx As ContextManager, _
                                      ByVal dbPath As String, _
                                      ByVal dbName As String) As DbAccess
    On Error GoTo ErrorHandler
    
    Dim db As New DbAccess
    db.Initialize dbPath, ctx.Logger
    db.Connect
    
    Debug.Assert db.IsConnected = True
    
    Set Test_ConnectDatabase = db
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ " & dbName & " connection failed: " & Err.Description
    Set Test_ConnectDatabase = Nothing
End Function

Private Function Test_ServiceImport(ByVal ctx As ContextManager, _
                                    ByVal dbSource As DbAccess) As Boolean
    On Error GoTo ErrorHandler
    
    Test_ServiceImport = False
    
    Dim svc As New ServiceImport
    svc.Initialize ctx
    
    ' Test: Check if service initialized properly
    Debug.Assert Not svc Is Nothing
    
    ' Note: OpenWizard requires user interaction, so we skip it in automated tests
    Debug.Print "    ⚠ OpenWizard skipped (requires user interaction)"
    
    Test_ServiceImport = True
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ ServiceImport test failed: " & Err.Description
    Test_ServiceImport = False
End Function

Private Function Test_ServiceValidation(ByVal ctx As ContextManager, _
                                        ByVal dbSource As DbAccess, _
                                        ByVal dbTarget As DbAccess) As Boolean
    On Error GoTo ErrorHandler
    
    Test_ServiceValidation = False
    
    Dim svc As New ServiceValidation
    svc.Initialize ctx, dbSource, dbTarget
    
    ' Test: CheckCompleteness
    If Not svc.CheckCompleteness() Then
        Debug.Print "    ✗ CheckCompleteness failed"
        Exit Function
    End If
    
    ' Verify: Tables created
    Debug.Assert dbTarget.TableExists("JE_IN_PERIOD") = True
    Debug.Assert dbTarget.TableExists("COMPLETENESS_DETAIL") = True
    
    ' Test: CheckDocumentBalance
    If Not svc.CheckDocumentBalance() Then
        Debug.Print "    ✗ CheckDocumentBalance failed"
        Exit Function
    End If
    
    ' Verify: Balance tables created
    Debug.Assert dbTarget.TableExists("DOCUMENT_BALANCE_DETAIL") = True
    
    Test_ServiceValidation = True
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ ServiceValidation test failed: " & Err.Description
    Test_ServiceValidation = False
End Function

Private Function Test_ServiceFilter(ByVal ctx As ContextManager, _
                                    ByVal dbTarget As DbAccess) As Boolean
    On Error GoTo ErrorHandler
    
    Test_ServiceFilter = False
    
    Dim svc As New ServiceFilter
    svc.Initialize ctx, dbTarget
    
    ' Test: Run all routines
    svc.RunAllRoutines
    
    ' Verify: Tag columns exist
    Debug.Assert dbTarget.FieldExists("JE_IN_PERIOD", "Tag_R1") = True
    Debug.Assert dbTarget.FieldExists("JE_IN_PERIOD", "Tag_R2") = True
    Debug.Assert dbTarget.FieldExists("JE_IN_PERIOD", "Tag_A2") = True
    
    ' Test: Custom criteria
    svc.ApplyA2_CriteriaKeywords "TEST,SAMPLE"
    
    Test_ServiceFilter = True
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ ServiceFilter test failed: " & Err.Description
    Test_ServiceFilter = False
End Function

Private Function Test_ServiceDateDimension(ByVal ctx As ContextManager, _
                                          ByVal dbTarget As DbAccess) As Boolean
    On Error GoTo ErrorHandler
    
    Test_ServiceDateDimension = False
    
    ' Note: ServiceDateDimension operates on ctx.DbAccess, not dbTarget
    Dim svc As New ServiceDateDimension
    svc.Initialize ctx
    
    ' Test: Create date dimension
    If Not svc.CreateDateDimensionTable() Then
        Debug.Print "    ✗ CreateDateDimensionTable failed"
        Exit Function
    End If
    
    ' Verify: Table created
    Debug.Assert ctx.DbAccess.TableExists(ctx.DbSchema.DateDimension.Name) = True
    
    ' Test: Merge weekends
    If Not svc.MergeWeekends(Array(1, 7)) Then
        Debug.Print "    ✗ MergeWeekends failed"
        Exit Function
    End If
    
    Test_ServiceDateDimension = True
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ ServiceDateDimension test failed: " & Err.Description
    Test_ServiceDateDimension = False
End Function

Private Function Test_ServiceExport(ByVal ctx As ContextManager, _
                                    ByVal dbTarget As DbAccess) As Boolean
    On Error GoTo ErrorHandler
    
    Test_ServiceExport = False
    
    Dim svc As New ServiceExport
    svc.Initialize ctx
    
    ' Create a test worksheet
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets.Add
    ws.Name = "TestExport_" & Format(Now, "hhmmss")
    
    ' Test: Export table to sheet
    If Not svc.ExportTableToSheet("JE_IN_PERIOD", ws) Then
        Debug.Print "    ✗ ExportTableToSheet failed"
        Application.DisplayAlerts = False
        ws.Delete
        Application.DisplayAlerts = True
        Exit Function
    End If
    
    ' Verify: Data exported
    Debug.Assert ws.UsedRange.Rows.Count > 1  ' At least header + 1 row
    
    ' Cleanup
    Application.DisplayAlerts = False
    ws.Delete
    Application.DisplayAlerts = True
    
    Test_ServiceExport = True
    Exit Function
    
ErrorHandler:
    Debug.Print "    ✗ ServiceExport test failed: " & Err.Description
    Test_ServiceExport = False
End Function

'===============================================================================
' Utility Functions
'===============================================================================

Private Sub Test_PrintSeparator()
    Debug.Print String(80, "-")
End Sub

Private Sub Test_PrintHeader(ByVal headerText As String)
    Debug.Print ""
    Debug.Print String(80, "=")
    Debug.Print headerText
    Debug.Print String(80, "=")
    Debug.Print ""
End Sub
