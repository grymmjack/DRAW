$If WIN Then
    Const Slash$ = "\"
$Else
        const Slash$ = "/"
$End If

target$ = "I:\git\DRAW\DRAW.BAS"
outfile$ = "I:\git\DRAW\DRAW_FLATTENED.BAS"

If target$ = "" Then
    Print "Give me a QB64 program to unravel => ";
    Input target$
    Print "Give me a name to save the new file under => ";
    Input outfile$
End If

Open outfile$ For Output As #1
OpenFile target$

Sub OpenFile (whatfile$)
    f = FreeFile
    CurrentDir$ = _CWD$
    i = _InStrRev(whatfile$, Slash$)
    newdir$ = Left$(whatfile$, i)
    If i > 0 Then
        ChDir newdir$
        whatfile$ = Mid$(whatfile$, i + 1)
    End If
    Open whatfile$ For Binary As #f
    Do
        Line Input #f, temp$
        If Left$(UCase$(_Trim$(temp$)), 11) = "'$INCLUDE:'" Then
            temp$ = _Trim$(temp$)
            file$ = Mid$(temp$, 12)
            file$ = Left$(file$, Len(file$) - 1)
            OpenFile file$
        Else
            Print #1, temp$
        End If
    Loop Until EOF(f)
    ChDir CurrentDir$
    Close #f
End Sub