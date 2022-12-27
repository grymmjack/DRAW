''
' MergeFile 
' 
' Takes a source target basic file and flattens all the includes to be in a
' single file. This lets you see what the compiler is compiling if you have
' multiple file includes. It works across directories, too. 
'
' HOW TO USE:
' -----------
' Change target$ to your source basic file you want to flatten into one file.
' Change outfile$ to the file path of the flattened/merged file.
' Change indent to a number you prefer. This helps debug stuff in code folding.
' 
' @author Steve McNeill (every thing)
' @author Rick Christy <grymmjack@gmail.com> (idea)
' @see https://qb64phoenix.com/forum/showthread.php?tid=1335&pid=12085#pid12085
'

$Debug
$If WIN Then
    Const Slash$ = "\"
$Else
    const Slash$ = "/"
$End If

' CHANGE THIS STUFF
const indent = 8
target$  = "I:\git\DRAW\DRAW.BAS"
outfile$ = "I:\git\DRAW\DRAW_FLATTENED.BAS"

' -----------------------------------------------------------------------------
' MAIN PROGRAM
' -----------------------------------------------------------------------------
If target$ = "" Then
    Print "Give me a QB64 program to unravel => ";
    Input target$
    Print "Give me a name to save the new file under => ";
    Input outfile$
End If

Open outfile$ For Output As #1
MergeFile target$
Dim SHARED stack AS INTEGER
stack% = 0

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
                stack% = stack% +1
                MergeFile file$
            Else
                Print #1, STRING$(stack% * indent, " ") + temp$
            End If
        Loop Until EOF(f)
    End If
    ChDir CurrentDir$
    ' See below comment
    IF LOF(f) = 0 THEN killempty = 1 ELSE killempty = 0
    Close #f
    ' In severe cases of nesting (the catalyst for this MergeFile program LOL)
    ' the program can get confused and output 0 byte files in the same dir it
    ' ran from. This is a kludge to get rid of those after it runs.
    if killempty = 1 THEN KILL whatfile$
    stack% = stack% - 1
End Sub
