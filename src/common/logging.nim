import strformat
import "../rendering/colors"

proc logError*(msg: string, fatal: bool = true) =
    stderr.writeLine Foreground.Red & &"ERROR: {msg}" & Default
    if fatal: quit(1)
