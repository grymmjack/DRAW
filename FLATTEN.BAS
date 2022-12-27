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
MergeFile target$

Sub MergeFile (whatfile$)
    f = FreeFile
    CurrentDir$ = _CWD$
    i = _InStrRev(whatfile$, Slash$)
    newdir$ = Left$(whatfile$, i)
    If i > 0 Then
        ChDir newdir$
        whatfile$ = Mid$(whatfile$, i + 1)
    End If
    Print whatfile$
    Open whatfile$ For Binary As #f
    If LOF(f) Then
        Do
            Line Input #f, temp$
            If Left$(UCase$(_Trim$(temp$)), 11) = "'$INCLUDE:'" Then
                temp$ = _Trim$(temp$)
                file$ = Mid$(temp$, 12)
                file$ = Left$(file$, Len(file$) - 1)
                MergeFile file$
            Else
                Print #1, temp$
            End If
        Loop Until EOF(f)
    End If
    ChDir CurrentDir$
    IF LOF(f) = 0 THEN killempty = 1 ELSE killempty = 0
    Close #f
    if killempty = 1 THEN KILL whatfile$
End Sub