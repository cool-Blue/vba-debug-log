Attribute VB_Name = "main"
Dim gLogger As cLogger
Dim ws As Worksheet
Sub controlEvent()
Const pName As String = "main.controlEvent"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  If gLogger Is Nothing Then
    Set gLogger = New cLogger
  End If
  If Not gLogger.Hooked Then _
    gLogger.hookRemoteLogger
  gLogger.route Application.caller
End Sub
Sub launch()
Const pName As String = "main.launch"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
    
  If gLogger Is Nothing Then
    Set gLogger = New cLogger
    gLogger.launchRemoteLogger
  Else
    If Not gLogger.hookRemoteLogger(1) Then
      gLogger.launchRemoteLogger
    End If
  End If
  Set ws = ActiveSheet
  
End Sub
Sub testFocus()
  gDispatcher.focusHost
End Sub
