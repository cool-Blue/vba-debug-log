Attribute VB_Name = "modTimers"
Option Explicit
Option Compare Text
Option Base 1
'---------------------------------------------------------------------------------------
'
' WinApi declarations
'
'
' sleep
'
Public Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As LongPtr) 'For 64 Bit Systems

'
' microtimer
'
Private Declare Function getFrequency Lib "kernel32" Alias _
                                      "QueryPerformanceFrequency" (cyFrequency As Currency) As Long
Private Declare Function getTickCount Lib "kernel32" Alias _
                                      "QueryPerformanceCounter" (cyTickCount As Currency) As Long
'
' millitimer
'
Public Declare Function timeGetTime Lib "winmm.dll" () As Long
' ****************************************************************
'
Function MicroTimer() As Double
'
' COPYRIGHT © DECISION MODELS LIMITED 2000. All rights reserved
'
' returns  a Double containing seconds
' uses Windows API calls to the high resolution timer
'
    Dim cyTicks1 As Currency
    Static cyFrequency As Currency
    '
    '
    MicroTimer = 0
    '
    ' get frequency
    '
    If cyFrequency = 0 Then getFrequency cyFrequency
    '
    ' get ticks
    '
    getTickCount cyTicks1
    '
    ' calc seconds
    '
    If cyFrequency Then MicroTimer = cyTicks1 / cyFrequency
    '
End Function
'-----------------------------------------------------------------
'
Function MilliTimer() As Long
'
' COPYRIGHT © DECISION MODELS LIMITED 2000. All rights reserved
'
' wrapper function
' returns  a Long containing Milliseconds
' uses Windows API calls to timegettime
'
    MilliTimer = timeGetTime()
    '
End Function
