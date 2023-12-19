import "std/strutils"
import "std/os"
import "std/parsecfg"
import "std/posix_utils"
from "../common/Definitions" import DistroId

proc getDistro*(): string =
    ## Returns the name of the running linux distro
    result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine

proc getDistroId*(): DistroId =
    ## Returns the DistroId of the running linux distro
    result.id = "/etc/os-release".loadConfig.getSectionValue("", "ID")
    result.like = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE")

proc getUptime*(): string =
    ## Returns the system uptime as a string (DAYS, HOURS, MINUTES)
    let uptime = "/proc/uptime".open.readLine.split(".")[0] # uptime in sec
    let utu = uptime.parseUInt
    let uth = utu div 3600 mod 24 # hours
    let utm = utu mod 3600 div 60 # minutes
    let utd = utu div 3600 div 24 # days
    if utd == 0:
      result = $(uth) & "h " & $(utm) & "m" # return hours and mins
    elif uth == 0 and utd == 0:
      result = $(utm) & "m" # return only mins
    else:
      result = $(utd) & "d " & $(uth) & "h " & $(utm) & "m" # return days, hours and mins

proc getHostname*(): string =
    ## Returns the system hostname
    result = uname().nodename

proc getUser*(): string =
    ## Returns the current username
    result = os.getEnv("USER")

proc getKernel*(): string =
    ## Returns the active kernel version
    result = "/proc/version".open.readLine.split(" ")[2]

proc getShell*(): string =
    ## Returns the system shell
    result = os.getEnv("SHELL").split("/")[^1]

proc getDesktop*(): string =
    ## Returns the running desktop env
    result = os.getEnv("XDG_CURRENT_DESKTOP")