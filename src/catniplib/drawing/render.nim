from "../common/defs" import FetchInfo, CONFIGPATH, Stats, Stat
import "../common/config"
import "../common/toml"
import "colors"
import "utils"
import "infoStats"

proc Render*(fetchinfo: FetchInfo) =
    ## Function that Renders a FetchInfo object to the console

    ##### Define Margins #####
    let
        margin_top = fetchinfo.logo.margin[0]
        margin_left = fetchinfo.logo.margin[1]
        margin_right = fetchinfo.logo.margin[2]

    ##### Load Config #####
    let config = LoadConfig(CONFIGPATH)
    let layout = config.misc["layout"].getStr()

    ##### Build distro_art buffer #####
    var distro_art: seq[string]

    # Fill distro_art buffer with fetchinfo.logo.art
    for idx in countup(0, fetchinfo.logo.art.len - 1):
        distro_art.add(" ".repeat(margin_left) & Colorize(fetchinfo.logo.art[idx]) & colors.Default & " ".repeat(margin_right))

    # Add margin_top lines ontop of the distro_art
    if margin_top > 0:
        var l = distro_art[0].reallen - 1
        for _ in countup(1, margin_top):
            distro_art = " ".repeat(l) & distro_art

    ##### Build stat_block buffer #####
    var stats: Stats = newStats()
    stats.setUsername(config.stats["username"])
    stats.setHostname(config.stats["hostname"])
    stats.setUptime(config.stats["uptime"])
    stats.setDistro(config.stats["distro"])
    stats.setKernel(config.stats["kernel"])
    stats.setDesktop(config.stats["desktop"])
    stats.setShell(config.stats["shell"])
    stats.setColors(config.stats["colors"])

    # Build the stat_block buffer
    var stats_block = build(stats, fetchinfo)

    ##### Merge buffers and output #####
    case layout:
        of "Inline":
            let lendiv = stats_block.len - distro_art.len
            if lendiv < 0:
                for _ in countup(1, lendiv - lendiv*2):
                    stats_block.add(" ")
            elif lendiv > 0:
                for _ in countup(1, lendiv):
                    distro_art.add(" ".repeat(distro_art[0].reallen - 1))

            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx] & stats_block[idx]
        of "ArtOnTop":
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
        of "StatsOnTop":
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]