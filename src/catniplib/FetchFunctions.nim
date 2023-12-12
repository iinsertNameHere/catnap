import "std/strutils"
import "std/os"
import "std/parsecfg"
import "std/posix_utils"

proc getDistro*(): string =
  result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine

proc getDistroID*(): array[2, string] =
  result[0] = "/etc/os-release".loadConfig.getSectionValue("", "ID")
  result[1] = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE")

proc getUptime*(): string =
  let uptime = "/proc/uptime".open.readLine.split(".")[0]
  let utu = uptime.parseUInt
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
  let hostname = "/etc/hostname"
  let hostnameOpenrc = "/etc/conf.d/hostname"
  if hostname.fileExists():
    result = hostname.open.readLine
  elif hostnameOpenrc.fileExists():
    result = hostnameOpenrc.loadConfig.getSectionValue("", "hostname")
  else:
    result = ""

func getUser*(): string =
  result = os.getEnv("USER")

proc getKernel*(): string =
  result = "/proc/version".open.readLine.split(" ")[2]

proc getShell*(): string =
  result = os.getEnv("SHELL").split("/")[^1]

proc getDesktop*(): string =
  result = os.getEnv("XDG_CURRENT_DESKTOP")