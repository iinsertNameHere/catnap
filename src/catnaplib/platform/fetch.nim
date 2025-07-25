import osproc
import strformat
import strutils
import sugar

from "../global/definitions" import FetchInfo, Config, toTmpPath
import "../terminal/logging"
import parsetoml
import "probe"

proc fetchSystemInfo*(config: Config, distroId: string = "nil"): FetchInfo =
    result.distroId = probe.getDistroId()
    result.list["username"] = proc(): string = return probe.getUser()
    result.list["hostname"] = proc(): string = return probe.getHostname()
    result.list["distro"]   = proc(): string = return probe.getDistro()
    result.list["uptime"]   = proc(): string = return probe.getUptime()
    result.list["kernel"]   = proc(): string = return probe.getKernel()
    result.list["desktop"]  = proc(): string = return probe.getDesktop()
    result.list["terminal"] = proc(): string = return probe.getTerminal()
    result.list["shell"]    = proc(): string = return probe.getShell()
    result.list["memory"]   = proc(): string = return probe.getMemory()
    result.list["battery"]  = proc(): string = return probe.getBattery()
    result.list["cpu"]      = proc(): string = return probe.getCpu()
    result.list["gpu"]      = proc(): string = return probe.getGpu()
    result.list["packages"] = proc(): string = return probe.getPackages()
    result.list["weather"]  = proc(): string = return probe.getWeather(config)
    if defined(linux):
        # Add a disk stat for all mounts
        let mounts: seq[string] = probe.getMounts()

        if mounts.len > 1:
            var index = 0
            for mount in mounts:
                let name = "disk_" & $index

                # Capture mount var to prevent value changes
                var cap: proc(): string
                capture mount:
                    # Create fetch proc
                    cap = proc(): string = return probe.getDisk(mount)

                result.list[name] = cap
                result.disk_statnames.add(name)
                index += 1
        else:
            result.list["disk_0"] = proc(): string = return probe.getDisk(mounts[0])
            result.disk_statnames.add("disk_0")
    else:
        #TODO: add macos support
        result.list["disk_0"] = proc(): string = ""
        result.disk_statnames.add("disk_0")

    var distroId = (if distroId != "nil": distroId else: result.distroId.id)

    if not config.distroart.contains(distroId):
        distroId = result.distroId.like
        if not config.distroart.contains(distroId):
            distroId = "default"

    result.logo = config.distroart[distroId]
