VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cWin32"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'---------------------------------------------------------------------------------------
' Module    : cWin32
' Author    : Admin
' Date      : 13-Oct-16
' Purpose   :
' todo
'   declare chainable functions as explicit type
'---------------------------------------------------------------------------------------
Const myName As String = "cWin32"
Const LogMode = False

#If Win64 Then
  Const PTR_LENGTH As Long = 8
#Else
  Const PTR_LENGTH As Long = 4
#End If

Private Type COPYDATASTRUCT
  dwData As LongPtr
  cbData As LongPtr
  lpData As LongPtr
End Type

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' used by FormatMessage
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Const FORMAT_MESSAGE_ALLOCATE_BUFFER = &H100
Private Const FORMAT_MESSAGE_ARGUMENT_ARRAY = &H2000
Private Const FORMAT_MESSAGE_FROM_HMODULE = &H800
Private Const FORMAT_MESSAGE_FROM_STRING = &H400
Private Const FORMAT_MESSAGE_FROM_SYSTEM = &H1000
Private Const FORMAT_MESSAGE_IGNORE_INSERTS = &H200
Private Const FORMAT_MESSAGE_MAX_WIDTH_MASK = &HFF
Private Const FORMAT_MESSAGE_TEXT_LEN = &HA0

Private Const WM_PAINT As Long = &HF
Private Const WM_CLOSE As Long = &H10
Private Const WM_QUIT As Long = &H12
Private Const WM_DESTROY As Long = &H2
Private Const WM_COPYDATA As Long = &H4A
Private Const WM_SETFOCUS As Long = &H7
Private Const WM_SYSCOMMAND As Long = &H112
Private Const WM_IME_SETCONTEXT As Long = 641
Private Const WM_IME_NOTIFY As Long = 642
Private Const SC_RESTORE As Integer = &HF120
Private Const SC_DEFAULT As Integer = &HF160
Private Const SC_MAXIMIZE As Integer = &HF030

Private Const VBA_REQ_FOREGROUND As Long = &H401

Private Const SW_RESTORE As Integer = 9
Private Const SW_SHOWDEFAULT As Integer = 10
Private Const SW_SHOW As Integer = 5
Private Const SW_SHOWNORMAL As Integer = 1

Private Declare Function FormatMessage Lib "kernel32.dll" Alias "FormatMessageA" ( _
                          ByVal dwFlags As Long, _
                          ByRef lpSource As Any, _
                          ByVal dwMessageId As Long, _
                          ByVal dwLanguageId As Long, _
                          ByVal lpBuffer As String, _
                          ByVal nSize As Long, _
                          ByRef Arguments As Long) As Long

Private Declare PtrSafe Function GetWindow Lib "User32" ( _
                          ByVal hWnd As LongPtr, _
                          ByVal wCmd As LongPtr) As LongPtr
Private Declare PtrSafe Function FindWindow Lib "User32" Alias "FindWindowA" ( _
                          ByVal lpClassName As String, _
                          ByVal lpWindowName As String) As LongPtr
Private Declare PtrSafe Function FindWindowEx Lib "User32" Alias "FindWindowExA" ( _
                          ByVal hWnd1 As LongPtr, _
                          ByVal hWnd2 As LongPtr, _
                          ByVal lpsz1 As String, _
                          ByVal lpsz2 As String) As LongPtr
Private Declare PtrSafe Function GetWindowTextLength Lib "User32" Alias "GetWindowTextLengthA" (ByVal hWnd As LongPtr) As LongPtr
Private Declare PtrSafe Function getWindowText Lib "User32" Alias "GetWindowTextA" ( _
                          ByVal hWnd As LongPtr, ByVal lpString As String, _
                          ByVal cch As LongPtr) As LongPtr


Private Declare Function PostMessage Lib "User32" Alias "PostMessageA" ( _
                          ByVal hWnd As LongPtr, _
                          ByVal wMsg As LongPtr, _
                          ByVal wParam As Any, _
                          ByVal lParam As Any) As LongPtr
Private Declare PtrSafe Function SendMessage Lib "User32" Alias "SendMessageA" ( _
                          ByVal hWnd As LongPtr, _
                          ByVal wMsg As LongPtr, _
                          ByVal wParam As LongPtr, _
                          ByVal lParam As LongPtr) As LongPtr

Private Declare PtrSafe Function SetForegroundWindow Lib "User32" ( _
                          ByVal hWnd As LongPtr) As Boolean
Private Declare PtrSafe Function SetFocus Lib "User32" ( _
                          Optional ByVal hWnd As LongPtr) As LongPtr
Private Declare PtrSafe Function SetActiveWindow Lib "User32" ( _
                          Optional ByVal hWnd As LongPtr) As LongPtr

'Copies a block of memory from one location to another.
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
                          hpvDest As Any, _
                          hpvSource As Any, _
                          ByVal cbCopy As Long)
   
Public mUseLogger As Boolean

Private mhWndOwner As LongPtr
Private mhWndTarget As LongPtr
Private mContent As String
Private db As cDebugReporter
Private mLogging As Boolean
Private mlastError As String
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// window handling                                                                               //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Property Get hWnd() As LongPtr
  hWnd = mhWndTarget
End Property
Property Get hwndX() As String
  hwndX = "0x" & Hex(mhWndTarget)
End Property
Property Get hWndOwner() As LongPtr
  mhWndOwner = FindWindow("XLMAIN", vbNullString)
  If mhWndOwner = 0 Then Err.Raise vbObjectError + 1, myName, "Cannot find main excel window"
  hWndOwner = mhWndOwner
End Property
Property Get Hooked() As Boolean
  Hooked = mhWndTarget <> 0
End Property
Public Function hook(t As String)
Const pName As String = "cWin32.hook"
  mhWndTarget = getHwnd(t)
  Set hook = Me
End Function
Public Function focusTarget()
Const pName As String = "cWin32.focusTarget"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
'  post WM_SYSCOMMAND, SC_DEFAULT, 0&
  SetForegroundWindow hWnd
  
  db.ExitMessage = LastError
  
Set focusTarget = Me
End Function
Public Function closeWindow()
  post WM_CLOSE, 0&, 0&
  mhWndTarget = 0
End Function
Public Function focusHost() As String
Const pName As String = "cWin32.focusHost"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.Report caller:=pName
'  SetFocus mhWndOwner
  post VBA_REQ_FOREGROUND, hWndOwner, 0&
  focusHost = Hex(hWndOwner)
  DoEvents
  db.ExitMessage = "0x" & Hex(mhWndOwner) & vbTab & Hex(Application.hWnd)
End Function
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// public utilities                                                                               //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Public Function memCopy(dest As Byte, ByVal content As String)
Const pName As String = "cWin32.memCopy"
  Call CopyMemory(dest, ByVal content, Len(content))
End Function
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// Messages                                                                                        //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
Public Function post(msg As LongPtr, p1 As LongPtr, p2 As LongPtr)
Const pName As String = "cWin32.post"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.localEnabled (LogMode)
    db.Report caller:=pName, message:="msg: " & msg
    
  PostMessage mhWndTarget, msg, p1, p2
  dllErr msg, p1, p2
  Set post = Me
  db.ExitMessage = mlastError
  
End Function
Public Function send(msg As LongPtr, p1 As LongPtr, p2 As LongPtr)
Const pName As String = "cWin32.send"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.localEnabled (LogMode)
    db.Report caller:=pName, message:="msg: " & msg
    
  SendMessage mhWndTarget, msg, p1, p2
  dllErr msg, p1, p2
  Set send = Me
  db.ExitMessage = mlastError
  
End Function

'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// Logging                                                                                         //
'/////////////////////////////////////////////////////////////////////////////////////////////////////

Public Function log(content As String)
Const pName As String = "cWin32.log"
Dim db As New cDebugReporter
    db.ToImmediate = True
    db.localEnabled (LogMode)
    db.Report caller:=pName, context:=content
Dim cds As COPYDATASTRUCT
Dim cdsBuf(1 To 255) As Byte

  Call CopyMemory(cdsBuf(1), ByVal content, Len(content))
  cds.dwData = 0
  cds.cbData = Len(content) + 1 ' add 1 to include a null to terminate the string
  cds.lpData = VarPtr(cdsBuf(1))
  
  send WM_COPYDATA, mhWndOwner, VarPtr(cds)
  Set log = Me
  
End Function
Public Property Get LastError() As String
  LastError = mlastError
End Property
Public Function EOF()
  send WM_COPYDATA, mhWndOwner, VarPtr(Null)
End Function
Public Function throwIfError()
  If mlastError <> "" Then
    Err.Raise vbObjectError + 100, "cWin32", mlastError
  End If
End Function
'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// Private functions                                                                               //
'/////////////////////////////////////////////////////////////////////////////////////////////////////

Private Function getHwnd(title As String) As LongPtr
  getHwnd = FindWindow(vbNullString, title)
End Function
Private Sub dllErr(Optional msg As Long, Optional wParam As LongPtr, Optional lParam As Long)
Const pName As String = "cWin32.dllErr"
Dim errCode As Long
  errCode = Err.LastDllError
  If errCode <> 0 Then
    mlastError = hwndX & " : msg: " & Hex(msg) & " wParam: " & Hex(wParam) & " lParam: " & Hex(lParam) & _
                  " : " & GetSystemErrorMessageText(errCode)
    Err.Raise vbObjectError + 100, "cWin32", mlastError
  Else
    mlastError = ""
  End If
End Sub
Private Function GetSystemErrorMessageText(ErrorNumber As Long) As String
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' GetSystemErrorMessageText
'
' This function gets the system error message text that corresponds to the error code returned by the
' GetLastError API function or the Err.LastDllError property. It may be used ONLY for these error codes.
' These are NOT the error numbers returned by Err.Number (for these errors, use Err.Description to get
' the description of the message).
' The error number MUST be the value returned by GetLastError or Err.LastDLLError.
'
' In general, you should use Err.LastDllError rather than GetLastError because under some circumstances the value of
' GetLastError will be reset to 0 before the value is returned to VB. Err.LastDllError will always reliably return
' the last error number raised in a DLL.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    Dim ErrorText As String
    Dim TextLen As Long
    Dim FormatMessageResult As Long
    Dim LangID As Long
    
    LangID = 0&
    ErrorText = String$(FORMAT_MESSAGE_TEXT_LEN, " ")
    TextLen = Len(ErrorText)
    On Error Resume Next
    FormatMessageResult = 0&
    
    FormatMessageResult = FormatMessage( _
                    dwFlags:=FORMAT_MESSAGE_FROM_SYSTEM Or FORMAT_MESSAGE_IGNORE_INSERTS, _
                    lpSource:=0&, _
                    dwMessageId:=ErrorNumber, _
                    dwLanguageId:=0&, _
                    lpBuffer:=ErrorText, _
                    nSize:=TextLen, _
                    Arguments:=0&)
       
       
    On Error GoTo 0
    If FormatMessageResult > 0 Then
        ErrorText = TrimToNull(ErrorText)
        ErrorText = Replace(ErrorText, vbCrLf, "")
        GetSystemErrorMessageText = ErrorText
    Else
        ' Format message didn't return any text. there is no text description for the specified error.
        GetSystemErrorMessageText = "NO ERROR DESCRIPTION AVAILABLE"
    End If
    
End Function
Private Function getCaption(W As Variant) As String
  If W <> vbNullString Then
    getCaption = IIf(TypeOf W Is Object , W.Caption, _
                  IIf(TypeName(W) = "String", W, vbNullString))
  Else
    getCaption = vbNullString
  End If
End Function

Private Function TrimToNull(Text As String) As String
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' TrimToNull
' Returns the portion of Text that is to the left of
' the first vbNullChar character.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    Dim Pos As Integer
    Pos = InStr(1, Text, vbNullChar)
    If Pos Then
        TrimToNull = Left(Text, Pos - 1)
    Else
        TrimToNull = Text
    End If
End Function

Private Sub Class_Initialize()
Const pName As String = "cWin32.Class_Initialize"
    Set db = New cDebugReporter
    db.persist
    db.ToImmediate = True
    db.Transport = Text
    db.Report caller:=myName
    
    mLogging = True
  
'  h = FindWindow("wndclass_desked_gsk", vbNullString)
'  h = FindWindowEx(h, 0&, "XLDESK", vbNullString)
'  h = FindWindowEx(h, 0&, "EXCEL7", vbNullString)
  mhWndOwner = FindWindow("XLMAIN", vbNullString)
  If mhWndOwner = 0 Then Err.Raise vbObjectError + 1, myName, "Cannot find main excel window"
End Sub

Private Sub Class_Terminate()
  db.ExitMessage = myName & " terminating " & hwndX
End Sub
