import strformat
import parsetoml
import math

import "../terminal/logging"
from "../global/definitions" import FetchInfo, Stats, Stat, Config, STATNAMES
import "../terminal/colors"
import "../generation/utils"
import "../generation/stats"

proc getStat(stats: TomlValueRef, key: string): TomlValueRef =
    # Returns the value of stats[key] if it exists, else returns nil
    if stats.contains(key):
        return stats[key]
    return nil

proc Render*(config: Config, fetchinfo: FetchInfo) =
    # Function that Renders a FetchInfo object to the console

    # Define Margins
    let
        margin_top = fetchinfo.logo.margin[0]
        margin_left = fetchinfo.logo.margin[1]
        margin_right = fetchinfo.logo.margin[2]

    # Load Config
    let layout = config.misc["layout"].getStr()

    # Build distro_art buffer
    var distro_art: seq[string]

    # Fill distro_art buffer with fetchinfo.logo.art
    for idx in countup(0, fetchinfo.logo.art.len - 1):
        distro_art.add(" ".repeat(margin_left) & Colorize(fetchinfo.logo.art[idx]) & colors.Default & " ".repeat(margin_right))

    # Add margin_top lines ontop of the distro_art
    if margin_top > 0:
        var l = distro_art[0].reallen - 1
        for _ in countup(1, margin_top):
            distro_art = " ".repeat(l) & distro_art

    # Build stat_block buffer
    var stats: Stats = newStats()

    for stat_name in STATNAMES & fetchinfo.disk_statnames:
        stats.setStat(stat_name, config.stats.getStat(stat_name))

    # Get ordered statnames list
    var keys: seq[string]
    for k in config.stats.getTable().keys:
        keys.add(k)

    var delta: seq[string]
    for stat in STATNAMES:
        if stat notin keys:
            delta.add(stat)

    let ORDERED_STATNAMES = keys & delta

    var stats_margin_top = 0
    if config.misc.contains("stats_margin_top"):
        stats_margin_top = config.misc["stats_margin_top"].getInt()

    # Build the stat_block buffer
    var stats_block = buildStatBlock(ORDERED_STATNAMES, stats, config, fetchinfo, stats_margin_top)

    # Merge buffers and output
    case layout:
        of "Inline": # Handle Inline Layout
            # ASCII mode
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
            # ASCII mode
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]

        of "StatsOnTop": # Handle StatsOnTop Layout
            # ASCII mode
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
                    
        else: # Invalid Layout
            logError(&"{config.configFile}:misc:layout - Invalid value")
            quit(1)
