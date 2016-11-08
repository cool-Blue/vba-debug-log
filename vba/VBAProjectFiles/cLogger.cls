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
Private WithEvents mApp As Application
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
  gDispatcher.focusTarget
  testLoopInner
  
  If gDispatcher Is Nothing Then Exit Sub
  If gDispatcher.Hooked Then flush
End Sub
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// remote logger                                                                                       //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Public Function toggleLog() As Boolean
  gDispatcher.post VBA_LOGGING, 0&, 0&
  mLogging = Not mLogging
  toggleLog = mLogging
End Function
Property Get sTransport() As Range
  Set sTransport = Worksheets("run").Range("sTransport")
End Property
Property Get Transport() As Integer
  Transport = Worksheets("run").Range("Transport").Value2
End Property
Sub synctTransport()
Const pName As String = "cLogger.synctTransport"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
    
  flush

Dim t As eTransport: t = Transport
  config VBA_TRANSPORT, t
  gTransport = t
    
  db.Report "gTransport set to " & sTransport.Value2
  
End Sub
Public Function flush()
Const pName As String = "cLogger.flush"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
    
  gDispatcher.EOF
  
  db.ExitMessage = Array("text", "json")(gTransport)
End Function
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

  Call Shell( _
    "C:\Users\Admin\Documents\Visual Studio 2013\Projects\vba-debug-client\vba-debug-client\bin\Release\vba-debug-client.exe", vbNormalNoFocus)
  
  hookRemoteLogger 1000
  
End Sub
Function hookRemoteLogger(Optional maxRetries As Integer = 1000)
Const pName As String = "cLogger.hookRemoteLogger"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
Dim windowStyle As Integer: windowStyle = 1
Dim retries As Integer: retries = 0
Dim xlH As String

  If gDispatcher Is Nothing Then Set gDispatcher = New cWin32
  
  ' poll until the app window is constructed and found
  ' get it's HWnd
  Do
    gDispatcher.hook loggerCaption
    DoEvents
    retries = retries + 1
  Loop While Not gDispatcher.Hooked And retries < maxRetries
  db.Report "waiting for window " & gDispatcher.hwndX & " retries: " & retries
  
  If Hooked Then
  'poll until the window is constructed and receiving messages
    retries = 0
    Do
      synctTransport
      DoEvents
      retries = retries + 1
    Loop While gDispatcher.LastError <> "" And retries < maxRetries
    db.Report "waiting to send messages " & retries
  End If
  
  ' bring the focus back to excel
  DoEvents
  xlH = gDispatcher.focusHost
  DoEvents
  
  db.ExitMessage = "Host: 0x" & xlH & " DLL error state: " & gDispatcher.LastError
  
  hookRemoteLogger = Hooked And retries < maxRetries
End Function
Sub config(msg As Long, wParam As Long, Optional lParam As Long = 0&)
Const pName As String = "cLogger.config"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName, message:="msg: " & msg
  
  gDispatcher _
    .post(msg, wParam, lParam) _
    .focusTarget
  DoEvents
  gDispatcher.focusHost
    
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
Private Sub isTransport(Target As Range)
  If Target = sTransport Then
    synctTransport
    Exit Sub
  End If
End Sub
Private Sub mWs_Change(ByVal Target As Range)
  isTransport Target
End Sub
Private Sub mWs_SelectionChange(ByVal Target As Range)
  On Error GoTo exitEnabled
  Application.EnableEvents = False
  If Not Intersect(Target, Worksheets("run").Range("transports")) Is Nothing Then
    sTransport.Value2 = Target.Value2
    sTransport.Activate
    Sleep 50
    synctTransport
    DoEvents
    Target.Activate
  End If
exitEnabled:
  Application.EnableEvents = True
End Sub
Sub toggleLogging()
  Dim button As Object
  Set button = mWs.Shapes(Namespace & "logging")
  If toggleLog() Then
    button.DrawingObject.Caption = "Paused"
  Else
    button.DrawingObject.Caption = "Logging"
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
  If Not gDispatcher Is Nothing Then
    gDispatcher.post(VBA_CLEAR, 0&, 0&).focusTarget
    DoEvents
    gDispatcher.focusHost
  End If
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
  If Not gDispatcher Is Nothing Then gDispatcher.focusTarget
  testLoop
  gDispatcher.focusHost
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
' If there is a gDebugLog object defined, in scope, then, if it is not initialised,
' initialise it to a new file at \debuglog.txt.  Otherwise set it to nothing to
' dissable logging to file.
Sub initFile()
Static state As Boolean
Dim button As Object

  Set button = mWs.Shapes(Namespace & "logToFile")
  On Error GoTo onErr
  If gDebugLog Is Nothing Then
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set gDebugLog = fso.CreateTextFile(ActiveWorkbook.Path & "\debuglog.txt")
    button.DrawingObject.Caption = "Loging to file"
  Else
    gDebugLog.Close
    Set gDebugLog = Nothing
    button.DrawingObject.Caption = "Log to file"
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
  db.Report "Controls built"
  
End Sub
Private Sub Class_Terminate()
Const pName As String = "cLogger.Class_Terminate"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  
  closeLog
  
  db.Report "cLogger Terminating "
  db.ExitMessage = "gDispatcher state: " & gDispatcher.LastError
End Sub

