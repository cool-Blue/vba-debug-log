VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cDebugReporter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
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

Private Const mDTCOL As Long = 150
Private Const TABSTOP As String = " "

Private mLevel As Long
Private mFirstReport As Boolean
Private startTime As Double, lapTime As Double
Private mCaller As String
Private mContext As String
Public ExitMessage As String

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
Public Function timeStamp(Optional d As Double = 0) As String
Dim errorMessage As String
    If Err.number <> 0 Then
        errorMessage = "ERROR: " & Err.number & ": " & Err.Description
        Err.Clear
    End If
    
    If d = 0 Then
      timeStamp = sysTime
    Else
      timeStamp = Format(Hour(d), "00") & ":" & Format(Minute(d), "00") & ":" & Format(Second(d), "00") & ":"
    End If
    
End Function
Public Sub Report(Optional d As Double = 0, Optional caller As String, Optional Context As String, _
                            Optional Message As String, Optional newLine As eNewLine = Auto)

    If gcDebugMode Then
    
    Dim myContext As String
    Dim logText As String
    Dim dt As String
    
    Dim errorMessage As String
        If Err.number <> 0 Then
            errorMessage = "ERROR: " & Err.number & ": " & Err.Description
            Err.Clear
        End If
        
        ' persist the caller name
        If Len(caller) <> 0 Then mCaller = caller
        
        ' automatically creat context for START report
        ' otherwise use passed in context if any
        If Len(Context) = 0 Then
            If mFirstReport And Len(caller) > 0 Then
                myContext = "START"
            End If
        Else
            mContext = Context
            myContext = mContext
        End If
        
        ' log elapsed time since previous report unless END report
        ' for END report, log total procedure time
        If Context = "END" Then
          dt = FormatNumber(MicroTimer - startTime, 6)
          gDebugMargin = True
        Else
          dt = IIf(mFirstReport Or Len(mCaller) = 0, "", FormatNumber(MicroTimer - lapTime, 6))
        End If
        
        ' manage spacing between procedures
        If newLine = Auto Then newLine = IIf(mFirstReport And gCallDepth = 1 _
                                              Or mFirstReport And Not gDebugMargin, Before, _
                                              IIf(Context = "END", after, No))
        If mFirstReport Then gDebugMargin = False
        
        logText = timeStamp(d) & String(gCallDepth, TABSTOP)
        
        'tag START and END reports with mCaller
        caller = IIf(mFirstReport And Len(mCaller) > 0 Or Context = "END", mCaller, _
                                        String(Len(mCaller), " "))
        
    If Len(caller) <> 0 Then
      logText = logText & caller
      
      If Len(myContext) <> 0 Then logText = logText & ":" & TABSTOP & myContext
      If Len(Message) <> 0 Then logText = logText & IIf(Len(myContext) = 0, ":" & TABSTOP, TABSTOP) & Message
      
    Else
    
      If Len(myContext) <> 0 Then logText = logText & TABSTOP & myContext
      If Len(Message) <> 0 Then logText = logText & TABSTOP & Message
      
    End If
        
    If Len(dt) <> 0 Then
      If Len(errorMessage) <> 0 Then
        errorMessage = sysTime & String(gCallDepth, "*") & errorMessage
        errorMessage = errorMessage & setCol(errorMessage, dt, mDTCOL)
        logText = logText & vbNewLine & errorMessage
      Else
        logText = logText & setCol(logText, dt, mDTCOL)
      End If
    Else
      If Len(errorMessage) <> 0 Then
        errorMessage = sysTime & String(gCallDepth, "*") & errorMessage
        logText = logText & vbNewLine & errorMessage
      End If
    End If
            
        Select Case newLine
        Case Before
            logText = Chr(10) & logText
        Case after
            logText = logText & Chr(10)
        Case both
            logText = Chr(10) & logText & Chr(10)
        Case Else
        End Select
                
        ' reset the lap timer
        lapTime = MicroTimer

        mFirstReport = False
        
        ' direct output
        If debugSaveToFile Then
          On Error GoTo writeErr
          If (newLine = Before Or newLine = both) Then debugLog.WriteLine
          debugLog.WriteLine logText
          If (newLine = after Or newLine = both) Then debugLog.WriteLine
        Else
          Debug.Print logText
        End If
    End If
    
    Exit Sub
    
' print to immediate window if the write to file fails
writeErr:
    Debug.Print logText
End Sub
Property Let Context(RHS As String)
    mContext = RHS
End Property
Private Sub Class_Initialize()
    gCallDepth = gCallDepth + 1
    mFirstReport = True
    startTime = MicroTimer
    lapTime = startTime
End Sub
Private Sub Class_Terminate()
    mContext = "END"
    Report Context:="END", Message:=ExitMessage
    startTime = MicroTimer
    gCallDepth = gCallDepth - 1
End Sub



