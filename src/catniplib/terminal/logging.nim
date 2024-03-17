import strformat

proc logError*(msg: string, fatal: bool = true) =
    echo &"ERROR: {msg}"
    if fatal: quit(1)