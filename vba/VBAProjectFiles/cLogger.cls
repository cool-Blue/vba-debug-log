VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cLogger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Global gDispatcher As cWin32
Dim WithEvents mWs As Worksheet
Attribute mWs.VB_VarHelpID = -1
Dim Controls As clColFormControls

Const VBA_TRANSPORT As Long = &H405
Const VBA_LOGGING As Long = &H403
Const VBA_CLEAR As Long = &H404
Const loggerCaption As String = "VBA Debug Log"
Const message As String = "Test Message Content Test Message"
Const Namespace = ">HOOK_"
Private mLogging As Boolean
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// testing                                                                                        //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Sub testLoopInner()
Const pName As String = "Module1.testLoopInner"
Dim db As New cDebugReporter
    db.Report caller:=pName, context:=Worksheets("run").Range("sLogType").Value2
Dim i As Integer
Dim repeats As Integer
  
  repeats = Worksheets("run").Range("repeats")
  For i = 0 To repeats
    db.Report message
    DoEvents
  Next i
  
  db.ExitMessage = Worksheets("run").Range("sLogType").Value2
  
End Sub
Sub testLoop()
Const pName As String = "cLogger.testLoop"
Dim db As New cDebugReporter
    db.Report caller:=pName
  If gDispatcher Is Nothing Then
    Set gDispatcher = New cWin32
    gDispatcher.hook loggerCaption
  End If
  gDispatcher.activateTarget
  testLoopInner
  
  If gDispatcher.Hooked Then gDispatcher.EOF
End Sub
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// remote logger                                                                                       //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Public Function toggleLog() As Boolean
  gDispatcher.post VBA_LOGGING, 0&, 0&
  mLogging = Not mLogging
  toggleLog = mLogging
End Function
Sub setTransport()
Const pName As String = "cLogger.setTransport"
Dim db As New cDebugReporter
    db.Report caller:=pName
Dim t As eTransport: t = Worksheets("run").Range("Transport").Value2
  config VBA_TRANSPORT, t, gDispatcher.hWndOwner
  gTransport = t
End Sub
Sub closeLog()
Const pName As String = "cLogger.closeLog"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
Dim Logger As New cWin32
  
  Logger.hook(loggerCaption) _
    .closeWindow
  
  Set Logger = Nothing
  Set gDispatcher = Nothing

End Sub
Public Sub launchRemoteLogger()
Const pName As String = "cLogger.launchRemoteLogger"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
Dim logH As LongPtr
Dim xlH As LongPtr

  logH = Shell( _
    "C:\Users\Admin\Documents\Visual Studio 2013\Projects\vba-debug-client\vba-debug-client\bin\Release\vba-debug-client.exe", vbNormalNoFocus)
  
  hookRemoteLogger
  DoEvents
  
  xlH = gDispatcher.focusHost
  
  DoEvents
  
  db.ExitMessage = "Host: 0x" & xlH & " DLL error state: " & gDispatcher.LastError
    
End Sub
Function hookRemoteLogger()
Const pName As String = "cLogger.hookRemoteLogger"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
Dim wsh As Object
Set wsh = VBA.CreateObject("WScript.Shell")
Dim waitOnReturn As Boolean: waitOnReturn = True
Dim windowStyle As Integer: windowStyle = 1
Dim retries As Integer: retries = 0

  If gDispatcher Is Nothing Then Set gDispatcher = New cWin32
  
  ' poll until the app window is constructed and found
  ' get it's HWnd
  Do
    gDispatcher.hook loggerCaption
    DoEvents
    retries = retries + 1
  Loop While Not gDispatcher.Hooked And retries < 1000
  db.Report "waiting for window " & gDispatcher.hwndX & " retries: " & retries
  
  'poll until the window is constructed and receiving messages
  Do
    setTransport
    DoEvents
    retries = retries + 1
  Loop While gDispatcher.LastError <> "" And retries < 1000
  db.Report "waiting to send messages " & retries
  
  Set hookRemoteLogger = Me
End Function
Sub config(msg As Long, wParam As Long, Optional lParam As Long = 0&)
Const pName As String = "cLogger.config"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName, message:="msg: " & msg

  gDispatcher _
    .post(msg, wParam, lParam) _
    .activateTarget
    
  AppActivate ThisWorkbook.Application.Caption
    
End Sub
Function Hooked() As Boolean
  If Not gDispatcher Is Nothing Then
    Hooked = gDispatcher.Hooked
  Else
    Hooked = False
  End If
End Function
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// UI                                                                                         //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Private Function isTransport(target As Range) As Boolean
  isTransport = target = Worksheets("run").Range("stransport")
  If isTransport Then setTransport
End Function
Private Sub mWs_Change(ByVal target As Range)
  isTransport target
End Sub
Sub toggleLogging()
  Dim button As Object
  Set button = mWs.Shapes(Namespace & "logging")
  If toggleLog() Then
    button.DrawingObject.Caption = "Logging"
  Else
    button.DrawingObject.Caption = "Paused"
  End If
End Sub
' action callbacks for msForma controls onAction macro
Sub logToFile()
Const pName As String = "cLogger.logToFile"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  initFile
End Sub
Sub logging()
Const pName As String = "cLogger.logging"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  toggleLogging
End Sub
Sub clear()
Const pName As String = "cLogger.clear"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  gDispatcher.post(VBA_CLEAR, 0&, 0&).activateTarget
End Sub
Sub shutDown()
Const pName As String = "cLogger.shutDown"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
 closeLog
End Sub
Sub runLoop()
Const pName As String = "cLogger.runLoop"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  If TypeName(gDispatcher) = "Empty" Then hookRemoteLogger
  testLoop
End Sub
Public Sub route(controlName As String)
Const pName As String = "cLogger.route"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName, message:=controlName
  CallByName Me, Replace(controlName, Namespace, ""), VbMethod
End Sub
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// File Logging                                                                                         //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
' Manages lifecycle of an output file for the db logger.
' Ascociated with a button called logToFile
' If there is a debugLog object defined, in scope, then, if it is not initialised,
' initialise it to a new file at \debuglog.txt.  Otherwise set it to nothing to
' dissable logging to file.
Sub initFile()
Static state As Boolean
Dim button As Object
  Set button = mWs.Shapes(Namespace & "logToFile")
  On Error GoTo onErr
  If Not TypeName(debugLog) = "Empty" Then
    If debugLog Is Nothing Then
      Dim fso As Object
      Set fso = CreateObject("Scripting.FileSystemObject")
      Set debugLog = fso.CreateTextFile(ActiveWorkbook.Path & "\debuglog.txt")
      button.DrawingObject.Caption = "Loging to file"
    Else
      debugLog.Close
      Set debugLog = Nothing
      button.DrawingObject.Caption = "Log to file"
    End If
  End If
  Exit Sub
onErr:
  'debugSaveToFile = False
End Sub
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// Class lifecycle                                                                                         //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Private Sub Class_Initialize()
Const pName As String = "cLogger.Class_Initialize"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  Set mWs = ActiveSheet
  Set Controls = New clColFormControls
  Controls.Namespace(Namespace).Connect "controlEvent"
  launchRemoteLogger
  
End Sub
Private Sub Class_Terminate()
Const pName As String = "cLogger.Class_Terminate"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  db.Report "cLogger Terminating "
  db.ExitMessage = "gDispatcher state: " & gDispatcher.LastError
End Sub

