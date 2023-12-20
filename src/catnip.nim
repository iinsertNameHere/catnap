import "catniplib/Fetch"
import "catniplib/drawing/Drawing"
import os
# import times, os, strutils

# let t0 = epochTime()

# Handle commandline args
var distroid = "nil"
if paramCount() > 0:
    distroid = paramStr(1)

# Get system info
let fetchinfo = Fetch.FetchSystemInfo(distroid)

# Render system info
Drawing.Render(fetchinfo)
echo ""

# let time = (epochTime() - t0).formatFloat(format = ffDecimal, precision = 4)
# echo time & "s"