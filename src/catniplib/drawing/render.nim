import strformat

import "../terminal/logging"
from "../common/definitions" import FetchInfo, Stats, Stat, Config
import "../common/parsetoml"
import "../terminal/colors"
import "../generation/utils"
import "../generation/stats"

proc getStat(stats: TomlValueRef, key: string): TomlValueRef =
    ## Returns the value of stats[key] if it exists, else returns nil
    if stats.contains(key):
        return stats[key]
    return nil

proc Render*(config: Config, fetchinfo: FetchInfo) =
    ## Function that Renders a FetchInfo object to the console

    ##### Define Margins #####
    let
        margin_top = fetchinfo.logo.margin[0]
        margin_left = fetchinfo.logo.margin[1]
        margin_right = fetchinfo.logo.margin[2]

    ##### Load Config #####
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
    stats.setStat(username, config.stats.getStat("username"))
    stats.setStat(hostname, config.stats.getStat("hostname"))
    stats.setStat(uptime, config.stats.getStat("uptime"))
    stats.setStat(distro, config.stats.getStat("distro"))
    stats.setStat(kernel, config.stats.getStat("kernel"))
    stats.setStat(desktop, config.stats.getStat("desktop"))
    stats.setStat(terminal, config.stats.getStat("terminal"))
    stats.setStat(shell, config.stats.getStat("shell"))
    stats.setStat(memory, config.stats.getStat("memory"))
    stats.setStat(colors, config.stats.getStat("colors"))

    # Build the stat_block buffer
    var stats_block = buildStatBlock(stats, fetchinfo)

    ##### Merge buffers and output #####
    case layout:
        of "Inline": # Handle Inline Layout
            let lendiv = stats_block.len - distro_art.len
            if lendiv < 0:
                for _ in countup(1, lendiv - lendiv*2):
                    stats_block.add(" ")
            elif lendiv > 0:
                for _ in countup(1, lendiv):
                    distro_art.add(" ".repeat(distro_art[0].reallen - 1))

            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx] & stats_block[idx]
        of "ArtOnTop": # Handle ArtOnTop Layout
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
        of "StatsOnTop": # Handle StatsOnTop Layout
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
        else: # Invalid Layout
            logError(&"{config.file}:misc:layout - Invalid value")
            quit(1)
