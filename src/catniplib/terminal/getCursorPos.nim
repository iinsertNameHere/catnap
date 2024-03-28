import terminal
import strutils

proc getCursorPos*(): tuple[x: int, y: int] = 
    ## Returns the current cursor pos
    
    if not isatty(stdout):
        return (0, 0)

    stdout.write("\e[6n")

    var x, y: string

    var c = getch()
    while c != ';':
        if c != '\e' and c != '[':
            y &= c
        c = getch()

    c = getch()
    while c != 'R': 
        x &= c
        c = getch()

    return (parseInt(x), parseInt(y))