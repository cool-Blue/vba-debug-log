Attribute VB_Name = "main"
Dim gLogger As cLogger

Dim ws As Worksheet
Sub controlEvent()
  If gLogger Is Nothing Then
    launch
  Else
    If Not gLogger.Hooked Then _
      gLogger.hookRemoteLogger.setTransport
  End If
  gLogger.route Application.caller
End Sub
Sub launch()
Const pName As String = "main.launch"
Dim db As New cDebugReporter
    db.Report caller:=pName
  If gLogger Is Nothing Then
    Set gLogger = New cLogger
  Else
    gLogger.launchRemoteLogger
  End If
  Set ws = ActiveSheet
End Sub
