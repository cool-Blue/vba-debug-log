Attribute VB_Name = "mDebugReporter"
Option Explicit
Public Enum eLogTo
  noop = -1
  ToImmediate
  toLogger
  toFile
End Enum

Public Enum eTransport
  noop = -1
  Text
  json
End Enum

Public Const gcDebugMode As Boolean = True
Public Const gdebugOutTo As Long = eLogTo.toFile
Public gCallDepth As Long
Public gDebugMargin As Boolean
'Public glogFile As cTextStream
Public gSavState(0 To 255) As Byte
Public debugLog As Object

Public gTransport As eTransport

Public gDispatcher As cWin32

Public Function gToImmediate()
  On Error GoTo notFound
  gToImmediate = Worksheets("run").Range("toImmediate")
  Exit Function
notFound:
  gToImmediate = False
End Function
