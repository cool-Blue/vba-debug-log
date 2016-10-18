Attribute VB_Name = "Module1"
Public Enum ELogger
  NewAction
  CastAction
  NewLog
  InstanceLog
  CastLog
  InvokeAsync
  NoOpp
End Enum
Const VBA_PRINT As Long = &H401
Private Const WM_SETFOCUS As Long = &H7
Const loggerCaption As String = "VBA Debug Log"
Public Const Message As String = "Test Message Content Test Message"
Sub test()
Const pName As String = "Module1.test"
Dim db As New cDebugReporter
    db.Report caller:=pName
Dim logger As New cWin32
  
  logger.log (Message)
  
End Sub
Sub closeLog()
Dim logger As New cWin32
  
  logger.title(loggerCaption) _
    .closeWindow

End Sub
Sub testLoopInner()
Const pName As String = "Module1.testLoop"
Dim db As New cDebugReporter
    db.Report caller:=pName, Context:=Worksheets("run").Range("sLogType").Value2
Dim i As Integer
Dim repeats As Integer
  
  glogger.title(loggerCaption) _
    .send(VBA_PRINT, Worksheets("run").Range("LogType").Value2, 0&) _
    .activateLog
  
  repeats = Worksheets("run").Range("repeats")
  For i = 0 To repeats
    db.Report Message
    DoEvents
  Next i
  
  db.ExitMessage = Worksheets("run").Range("sLogType").Value2
  
End Sub
Sub testLoop()
  testLoopInner
  glogger.EOF
End Sub
Sub startup()
Dim wsh As Object
Set wsh = VBA.CreateObject("WScript.Shell")
Dim waitOnReturn As Boolean: waitOnReturn = True
Dim windowStyle As Integer: windowStyle = 1
Dim retries As Integer: retries = 0

  Shell _
    "C:\Users\Admin\Documents\Visual Studio 2013\Projects\vba-debug-client\vba-debug-client\bin\Release\vba-debug-client.exe"
     
  Set glogger = New cWin32
  
  Do
    glogger.title loggerCaption
    DoEvents
    retries = retries + 1
  Loop While glogger.HWnd = 0 And retries < 1000
  
  Application.OnTime Now + TimeValue("00:00:01"), "initLog"
  'DoEvents
  'initLog

End Sub
Sub initLog()
  
  DoEvents
  glogger _
    .post(VBA_PRINT, Worksheets("run").Range("LogType").Value2, 0&) _
    .activateLog
    AppActivate ThisWorkbook.Application.Caption
    
End Sub
Sub toggleLogging()
  Dim button As Object
  Set button = ActiveSheet.Shapes("logging")
  If glogger.toggleLog() Then
    button.DrawingObject.Caption = "Logging"
  Else
    button.DrawingObject.Caption = "Paused"
  End If
End Sub
Sub clear()
  glogger.clear.activateLog
End Sub

