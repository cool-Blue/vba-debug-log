VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clseFormControls"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'Custom Class clseFormControls
Option Explicit
Const controlTypes As String = "CheckBox" & "OptionButton" & "Label" & "ScrollBar" & "ListBox" & "Spinner" & "DropDown"

Private vControl As Variant
Public Name As String
Public controlType As String
Public mShape As Shape

Public Property Let Shape(callBack As String, pSh As Shape)
    With pSh.OLEFormat
        controlType = TypeName(.Object)
        If controlType <> "OLEObject" And InStr(controlTypes, controlType) <> 0 Then
            Set vControl = .Object
            vControl.onAction = callBack
        Else
            vControl = Empty
        End If
        Name = .Object.Name
    End With 'pSh.OLEFormat
    Set mShape = pSh
End Property

