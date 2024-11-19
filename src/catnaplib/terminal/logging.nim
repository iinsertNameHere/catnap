import strformat
import "colors.nim"

proc logError*(msg: string, fatal: bool = true) =
    stderr.writeLine Foreground.Red & &"ERROR: {msg}" & Default
    if fatal: quit(1)