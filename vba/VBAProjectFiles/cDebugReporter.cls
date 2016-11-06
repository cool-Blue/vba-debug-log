VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cDebugReporter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'Option Explicit
'//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'/ Maintains a global call stack
'/ Requires
'/ Public const gcDebugMode as boolean = ???
'/ Public gCallDepth as Long
'/
'/ Usage
'/   Instantiate in a sub and report it's name to fire a START report
'/   Dim db As New cDebugReporter
'/   db.Report caller:=myName
'/   Use the report method to log progress
'/   db.Report Message:="KPIRadar: Arg1: " & Arg1 & " " & "Arg2: " & Arg2
'/   After the sub exits (and the db instance is GC'ed) an END report will fire
'/
'/ References
'/
'/ VBA vbe7.dll Visual Basic For Applications TypeLib 4.2
'/ Excel excel.exe Microsoft Excel 15.0 Object Library TypeLib 1.8
'/ stdole stdole2.tlb OLE Automation TypeLib 2.0
'/ Office mso.dll Microsoft Office 15.0 Object Library TypeLib 2.7
'/ MSForms fm20.dll Microsoft Forms 2.0 Object Library TypeLib 2.0
'/ Scripting scrrun.dll Microsoft Scripting Runtime TypeLib 1.0
'/
'/ Revision History
'/ 29/09/2014
'/   Generalised to work without Excel Application calls
'/   Now works in Powerpoint
'/   Eliminated all outboard dependencies: now independent
'/   Error messages put on a seperate line
'//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Public Enum eNewLine
  No
  Before
  after
  both
  Auto
End Enum

Enum logEdge
  callProc
  logReport
  ExitProc
End Enum

Private Const jsonMessage As String = "{ ""newLine"": ""@newLine"", ""callDepth"": ""@callDepth"", ""edge"": ""@edge"", ""caller"":  ""@caller"", ""timestamp"":  ""@timestamp"", ""context"":  ""@context"", ""message"":  ""@message"", ""error"":  ""@error"", ""dt"":  ""@dt"" }"
Dim msgDict As Object

Private Const mDTCOL As Long = 90
Private Const TABSTOP As String = " "

Private mLogTo As eLogTo
Private mTransport As eTransport
Private mToImmediate As Boolean
Private mLevel As Long
Private mFirstReport As Boolean
Private startTime As Double, lapTime As Double
Private mCaller As String
Private mContext As String
Public ExitMessage As String

Private mCalldepth As Integer
Private mLocalEnabled As Boolean

Private Declare PtrSafe Sub GetLocalTime Lib "kernel32" (lpSystemTime As SYSTEMTIME)

Private Type SYSTEMTIME
    wYear As Integer
    wMonth As Integer
    wDayOfWeek As Integer
    wDay As Integer
    wHour As Integer
    wMinute As Integer
    wSecond As Integer
    wMilliseconds As Integer
End Type

Public Function max(va, vb) As Variant
  If va > vb Then max = va Else max = vb
End Function
Public Function sysTime() As String
    'KPD-Team 1998
    'URL: http://www.allapi.net/
    'E-Mail: KPDTeam@Allapi.net
    Dim MyTime As SYSTEMTIME
    'Set the graphical mode to persistent
    'Get the local time
    GetLocalTime MyTime
    'Print it to the form
'    On Error GoTo exitEarly
    On Error Resume Next
    sysTime = Format(MyTime.wHour, "00") & ":" & Format(MyTime.wMinute, "00") & ":" & _
                Format(MyTime.wSecond, "00") & ":" & Format(MyTime.wMilliseconds, "000")
exitEarly:
End Function
Function setCol(S1 As String, S2 As String, s2Col As Long, Optional divider As String = ":") As String
    
    If s2Col < 0 Then
        setCol = " " & divider & S2
    Else
        setCol = String(max(s2Col - Len(S1) - Len(divider), 0), " ") & divider & S2
    End If
    
End Function
Public Function timestamp(Optional d As Double = 0) As String
Dim errorMessage As String
    If Err.Number <> 0 Then
        errorMessage = "ERROR: " & Err.Number & ": " & Err.Description
        Err.clear
    End If
    
    If d = 0 Then
      timestamp = sysTime
    Else
      timestamp = Format(Hour(d), "00") & ":" & Format(Minute(d), "00") & ":" _
                  & Format(Second(d), "00") & ":"
    End If
    
End Function
Public Sub Report(Optional message As String, Optional d As Double = 0, _
                  Optional caller As String, Optional context As String, _
                  Optional newLine As eNewLine = Auto)
Attribute Report.VB_UserMemId = 0
'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
'Default value: Edit in Notepad to see this.
'Attribute Report.VB_UserMemId = 0

  If gcDebugMode And mLocalEnabled Then
    
    Dim myContext As String
    Dim logtext As String
    Dim dt As String
    Dim edge As Boolean
    Dim output As String
    Dim printed As Boolean
    
    msgDict("message") = message
    
    Dim errorMessage As String
    If Err.Number <> 0 Then
        errorMessage = "ERROR: " & Err.Number & ": " & Err.Description
        Err.clear
    End If
    
    ' persist the caller name
    If Len(caller) <> 0 Then mCaller = caller
    
    msgDict("caller") = mCaller
    msgDict("edge") = logEdge.logReport
    
    ' automatically creat context for START report
    ' otherwise use passed in context if any
    If Len(context) = 0 Then
        If mFirstReport And Len(caller) > 0 Then
            myContext = "START"
            msgDict("edge") = logEdge.callProc
        End If
    Else
        mContext = context
        myContext = mContext
    End If
    
    msgDict("context") = myContext
    
    ' log elapsed time since previous report unless END report
    ' for END report, log total procedure time
    If context = "END" Then
      dt = FormatNumber(MicroTimer - startTime, 6)
      gDebugMargin = True
      msgDict("edge") = logEdge.ExitProc
    Else
      dt = IIf(mFirstReport Or Len(mCaller) = 0, "", FormatNumber(MicroTimer - lapTime, 6))
    End If
    msgDict("dt") = dt
    
    ' manage spacing between procedures
    If newLine = Auto Then newLine = IIf(mFirstReport And callDepth = 1 _
                                          Or mFirstReport And Not gDebugMargin, Before, _
                                          IIf(context = "END", after, No))
    If mFirstReport Then gDebugMargin = False
    
    msgDict("newLine") = newLine
    
    msgDict("timestamp") = timestamp(d)
    logtext = msgDict("timestamp") & String(callDepth(), TABSTOP)
    
    'tag START and END reports with mCaller
    
    caller = IIf(mFirstReport And Len(mCaller) > 0 Or context = "END", mCaller, _
                                    String(Len(mCaller), " "))
                                        
    edge = mFirstReport And Len(mCaller) > 0 Or context = "END"
        
    If Len(caller) <> 0 Then
      logtext = logtext & caller
      
      If Len(myContext) <> 0 Then logtext = logtext & ":" & TABSTOP & myContext
      If Len(message) <> 0 Then logtext = logtext & IIf(Len(myContext) = 0, ":" & TABSTOP, TABSTOP) & message
      
    Else
    
      If Len(myContext) <> 0 Then logtext = logtext & TABSTOP & myContext
      If Len(message) <> 0 Then logtext = logtext & TABSTOP & message
    
    End If
        
    If Len(dt) <> 0 Then
      If Len(errorMessage) <> 0 Then
        errorMessage = sysTime & String(callDepth, "*") & errorMessage
        errorMessage = errorMessage & setCol(errorMessage, dt, mDTCOL)
        logtext = logtext & vbNewLine & errorMessage
      Else
        logtext = logtext & setCol(logtext, dt, mDTCOL)
      End If
    Else
      If Len(errorMessage) <> 0 Then
        errorMessage = sysTime & String(callDepth, "*") & errorMessage
        logtext = logtext & vbNewLine & errorMessage
      End If
    End If
    
    msgDict("message") = message
    msgDict("error") = errorMessage
    msgDict("callDepth") = callDepth

            
    Select Case newLine
    Case Before
        logtext = Chr(10) & logtext
    Case after
        logtext = logtext & Chr(10)
    Case both
        logtext = Chr(10) & logtext & Chr(10)
    Case Else
    End Select
            
    ' reset the lap timer
    lapTime = MicroTimer

    mFirstReport = False
    
    If mToImmediate Then
      Debug.Print logtext
      Exit Sub
    End If
    
    ' direct output
    Select Case Transport
    Case Text
      output = logtext
    Case json
      output = toJson(msgDict)
    Case Else
    End Select
    
    If Not gDispatcher Is Nothing Then
      If gDispatcher.Hooked Then
        gDispatcher.log output
      Else
        logFallback printed, logtext
      End If
    Else
      logFallback printed, logtext
    End If
            
    On Error GoTo writeError
      writeToFile output, newLine
    On Error GoTo 0
      
  End If
  
  Exit Sub
  
writeError:
  logFallback printed, logtext
  On Error Resume Next
  Resume Next
End Sub
Sub logFallback(ByRef printed As Boolean, logtext As String)
  If Not printed And gToImmediate Then Debug.Print logtext
  printed = True
End Sub
Sub writeToFile(logtext As String, newLine As eNewLine)

  If Not TypeName(debugLog) = "Empty" Then
    If Not debugLog Is Nothing Then
      If (newLine = Before Or newLine = both) Then debugLog.writeLine
      debugLog.writeLine logtext
      If (newLine = after Or newLine = both) Then debugLog.writeLine
    Else
      Err.Raise "logstream not initialised"
    End If
  End If
  Exit Sub
    
End Sub
Private Function toJson(msgDict As Dictionary) As String
  Dim ret As String, p
  ret = jsonMessage

  For Each p In msgDict
    ret = Replace(ret, "@" & p, msgDict(p))
  Next p
  
  toJson = ret
  
End Function
Property Let ToImmediate(RHS As Boolean)
  mToImmediate = RHS
End Property
Property Get ToImmediate() As Boolean
  ToImmediate = mToImmediate Or gToImmediate()
End Property
Property Let Transport(t As eTransport)
  mTransport = t
End Property
Property Get Transport() As eTransport
  If mTransport = eTransport.noop Then
    Transport = gTransport
  Else
    Transport = mTransport
  End If
End Property
Property Let context(RHS As String)
    mContext = RHS
End Property
Public Sub persist(Optional enabled As Boolean = True)
  mCalldepth = gCallDepth
  gCallDepth = gCallDepth - 1
  localEnabled enabled
End Sub
Public Sub localEnabled(enabled As Boolean)
  mLocalEnabled = enabled
End Sub
Private Function callDepth()
  If mCalldepth < 0 Then callDepth = gCallDepth Else callDepth = mCalldepth
End Function
Private Sub Class_Initialize()

  If Not gcDebugMode Then Exit Sub
  
  mLocalEnabled = True
  
  Set msgDict = CreateObject("scripting.dictionary")
  
  mTransport = eTransport.noop
  mLogTo = eLogTo.noop
  
  mCalldepth = -1
  gCallDepth = gCallDepth + 1
  mFirstReport = True
  startTime = MicroTimer
  lapTime = startTime
  
End Sub
Private Sub Class_Terminate()
  If Not gcDebugMode Then Exit Sub
  
  mContext = "END"
  Report context:="END", message:=ExitMessage
  startTime = MicroTimer
  If mCalldepth < 0 Then gCallDepth = gCallDepth - 1
End Sub



