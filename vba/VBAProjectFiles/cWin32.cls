VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cWin32"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'---------------------------------------------------------------------------------------
' Module    : cWin32
' Author    : Admin
' Date      : 13-Oct-16
' Purpose   :
'---------------------------------------------------------------------------------------
Const myName As String = "cWin32"
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
Private Const VBA_PRINT As Long = &H401
Private Const VBA_EOF As Long = &H402
Private Const VBA_LOGGING As Long = &H403
Private Const VBA_CLEAR As Long = &H404
Private Const SW_RESTORE As Integer = 9
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
                          ByVal HWnd As LongPtr, _
                          ByVal wCmd As LongPtr) As LongPtr
Private Declare PtrSafe Function FindWindow Lib "User32" Alias "FindWindowA" ( _
                          ByVal lpClassName As String, _
                          ByVal lpWindowName As String) As LongPtr
Private Declare PtrSafe Function FindWindowEx Lib "User32" Alias "FindWindowExA" ( _
                          ByVal hWnd1 As LongPtr, _
                          ByVal hWnd2 As LongPtr, _
                          ByVal lpsz1 As String, _
                          ByVal lpsz2 As String) As LongPtr
Private Declare Function PostMessage Lib "User32" Alias "PostMessageA" ( _
                          ByVal HWnd As LongPtr, _
                          ByVal wMsg As LongPtr, _
                          ByVal WParam As Any, _
                          ByVal LParam As Any) As LongPtr
Private Declare PtrSafe Function SendMessage Lib "User32" Alias "SendMessageA" ( _
                          ByVal HWnd As LongPtr, _
                          ByVal wMsg As LongPtr, _
                          ByVal WParam As LongPtr, _
                          ByVal LParam As LongPtr) As LongPtr
Private Declare PtrSafe Function ActivateWindow Lib "User32" Alias "SetForegroundWindow" ( _
                          ByVal HWnd As LongPtr) As Boolean

Private Declare PtrSafe Function GetWindowTextLength Lib "User32" Alias "GetWindowTextLengthA" (ByVal HWnd As LongPtr) As LongPtr
Private Declare PtrSafe Function getWindowText Lib "User32" Alias "GetWindowTextA" ( _
                          ByVal HWnd As LongPtr, ByVal lpString As String, _
                          ByVal cch As LongPtr) As LongPtr

Private Declare Function ShowWindow Lib "User32" ( _
                          ByVal HWnd As LongPtr, _
                          ByVal nCmdShow As Integer) As Boolean

'Copies a block of memory from one location to another.
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
                            hpvDest As Any, _
                            hpvSource As Any, _
                            ByVal cbCopy As Long)
   
Private mhWndOwner As LongPtr
Private mhWndTarget As LongPtr
Private mContent As String
Private mLogging As Boolean

Public Function title(t As String)
  mhWndTarget = getHwnd(t)
  Debug.Print mhWndTarget

  Set title = Me
End Function
Property Get HWnd() As LongPtr
  HWnd = mhWndTarget
End Property
Property Get hwndX() As String
  hwndX = "0x" & Hex(mhWndTarget)
End Property
Private Function getHwnd(title As String) As LongPtr
  getHwnd = FindWindow(vbNullString, title)
End Function
Public Function post(msg As LongPtr, p1 As LongPtr, p2 As LongPtr)
Const pName As String = "cWin32.post"
  If mhWndTarget <> 0 Then
    PostMessage mhWndTarget, msg, p1, p2
  End If
  Set post = Me
End Function
Public Function send(msg As LongPtr, p1 As LongPtr, p2 As LongPtr)
Const pName As String = "cWin32.send"
  If mhWndTarget <> 0 Then
    mContent = content
    SendMessage mhWndTarget, msg, p1, p2
  End If
  Set send = Me
End Function
Public Function activateLog()
  ShowWindow mhWndTarget, SW_RESTORE
  Set activateLog = Me
End Function
Public Function log(content As String)
Const pName As String = "cWin32.log"
Dim cds As COPYDATASTRUCT
Dim buf(1 To 255) As Byte

  Call CopyMemory(buf(1), ByVal content, Len(content))
  cds.dwData = 3
  cds.cbData = Len(content) + 0
  cds.lpData = VarPtr(buf(1))
  
  send WM_COPYDATA, mhWndOwner, VarPtr(cds)
  Set log = Me
End Function
Public Function toggleLog()
  post VBA_LOGGING, 0&, 0&
  mLogging = Not mLogging
  toggleLog = mLogging
End Function
Public Function closeWindow()
  post WM_CLOSE, 0&, 0&
End Function
Public Function clear()
  post VBA_CLEAR, 0&, 0&
  Set clear = Me
End Function
Public Function activateHost()
  PostMessage mhWndOwner, WM_SETFOCUS, 0&, 0&
  Set activateHost = Me
End Function
Public Function EOF()
  post VBA_EOF, 0&, 0&
End Function
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

'/////////////////////////////////////////////////////////////////////////////////////////////////////
'// Private functions                                                                               //
'/////////////////////////////////////////////////////////////////////////////////////////////////////
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
  mLogging = True
'  h = FindWindow("wndclass_desked_gsk", vbNullString)
'  h = FindWindowEx(h, 0&, "XLDESK", vbNullString)
'  h = FindWindowEx(h, 0&, "EXCEL7", vbNullString)
  mhWndOwner = FindWindow("XLMAIN", vbNullString)
  If mhWndOwner = 0 Then Err.Raise vbObjectError + 1, myName, "Cannot find main excel window"
End Sub
