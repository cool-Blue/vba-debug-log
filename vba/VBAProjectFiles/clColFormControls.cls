VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clColFormControls"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private mCallBack As String
Private mNamespace As String
Private mClient As Object
Public mcolFormEvents As Collection

Function Connect(callBack As String, Optional osh As Worksheet)
' Loop through Form Controls on a Worksheet, wrap them in a Custom Class and Add them to a Collection.
Dim mSh As Worksheet
Dim mShape As Shape
Dim mMSG As String
'Wrapper...
Dim mControl As clseFormControls

If osh Is Nothing Then Set mSh = ActiveSheet Else Set mSh = osh

'   Manage the Collection
    If mcolFormEvents Is Nothing Then
        Set mcolFormEvents = New Collection
    End If
'   Access the Controls via their Shape Wrappers, wrap them with events and add to the Collection
    For Each mShape In mSh.Shapes
      If InStr(mShape.Name, mNamespace) = 1 Then
        Set mControl = New clseFormControls
        mControl.Shape(callBack) = mShape
        If mControl.controlType <> "OLEObject" Then
        '   If already a member, dont add
            On Error Resume Next
            mcolFormEvents.Add mControl, mControl.Name
            On Error GoTo 0
        End If
      End If
    Next
    mCallBack = callBack
    
    Set Connect = Me
End Function
Public Function Namespace(Optional ns As Variant) As Variant
Const pName As String = "clColFormControls.Namespace"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
  If IsMissing(ns) Then
    Namespace = mNamespace
  Else
    mNamespace = ns
    Set Namespace = Me
  End If
End Function
Property Get callBack() As String
    callBack = mCallBack
End Property
Property Let Client(c As Object)
  Set mClient = c
End Property
Sub onAction(source)
  Debug.Print source
  CallByName mClient, source, VbMethod
End Sub
Private Sub Class_Initialize()
Const pName As String = "clColFormControls.Class_Initialize"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
'   Manage the Collection
    Set mcolFormEvents = New Collection
    mCallBack = ""
End Sub


Private Sub Class_Terminate()
Const pName As String = "clColFormControls.Class_Terminate"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
'   Manage the Collection
    Set mcolFormEvents = Nothing

End Sub
