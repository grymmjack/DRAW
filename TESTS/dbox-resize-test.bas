$Resize:On

Screen _NewImage(640, 480, 32)
Do
    If _Resize Then
        Screen _NewImage(_ResizeWidth, _ResizeHeight, 32)
    End If


    Line (10, 10)-(_Width - 10, _Height - 10), , B

Loop