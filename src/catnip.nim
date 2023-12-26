import "catniplib/fetch"
import "catniplib/drawing/render"
import os

# Debug code for execution time
when not defined release: 
    import times, strutils, strformat
    let t0 = epochTime()

# Handle commandline args
var distroid = "nil"
if paramCount() > 0:
    distroid = paramStr(1)

# Get system info
let fetchinfo = fetchSystemInfo(distroid)

# Render system info
Render(fetchinfo)
echo ""

# Debug code for execution time
when not defined release: 
    let time = (epochTime() - t0).formatFloat(format = ffDecimal, precision = 3)
    echo &"Execution finished in {time}s"