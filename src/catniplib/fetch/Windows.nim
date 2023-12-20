import os
from "../common/Definitions" import DistroId

proc getDistro*(): string =
    result = "Windows"

proc getDistroID*(): DistroId =
    result.id = "windows"
    result.like = "nt"

proc GetTickCount64(): cint {.importc, varargs, header: "sysinfoapi.h".}
proc getUptime*(): string =

    let uptime = int(GetTickCount64().float / 1000.float)
    let utu = uptime.uint
    let uth = utu div 3600 mod 24
    let utm = utu mod 3600 div 60
    let utd = utu div 3600 div 24 
    if utd == 0:
      result = $(uth) & "h " & $(utm) & "m"
    elif uth == 0 and utd == 0:
      result = $(utm) & "m"
    else:
      result = $(utd) & "d " & $(uth) & "h " & $(utm) & "m"

proc getHostname*(): string =
    result = getEnv("COMPUTERNAME")

proc getUser*(): string =
    result = getEnv("USERNAME")

proc getKernel*(): string =
    result = "nt"

proc getShell*(): string =
    result = "powershell"

proc getDesktop*(): string =
    result = "Windows"