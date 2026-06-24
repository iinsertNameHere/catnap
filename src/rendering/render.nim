import strformat

import "../common/logging"
from "../config/types" import Config
from "../system/types" import FetchInfo
import "../common/colors"
import "../generation/utils"

proc Render*(config: Config, fetchinfo: FetchInfo) =
    let
        margin_top   = fetchinfo.logo.margin[0]
        margin_left  = fetchinfo.logo.margin[1]
        margin_right = fetchinfo.logo.margin[2]

    let layout = config.misc.layout

    var distro_art: seq[string]
    for idx in countup(0, fetchinfo.logo.art.len - 1):
        distro_art.add(" ".fill(margin_left) & fetchinfo.logo.art[idx] & colors.Default & " ".fill(margin_right))

    if margin_top > 0 and distro_art.len > 0:
        let l = distro_art[0].reallen - 1
        for _ in countup(1, margin_top):
            distro_art = " ".fill(l) & distro_art

    var stats_block = buildStatBlock(config.stats, config, fetchinfo, config.misc.stats_margin_top)

    case layout:
        of "inline":
            if distro_art.len == 0:
                for line in stats_block:
                    echo line
            else:
                let lendiv = stats_block.len - distro_art.len
                if lendiv < 0:
                    for _ in countup(1, lendiv - lendiv*2):
                        stats_block.add(" ")
                elif lendiv > 0:
                    for _ in countup(1, lendiv):
                        distro_art.add(" ".fill(distro_art[0].reallen - 1))
                for idx in countup(0, distro_art.len - 1):
                    echo distro_art[idx] & stats_block[idx]

        of "art_on_top":
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]

        of "stats_on_top":
            for idx in countup(0, stats_block.len - 1):
                echo stats_block[idx]
            for idx in countup(0, distro_art.len - 1):
                echo distro_art[idx]

        else:
            logError(&"{config.configFile}:layout - Invalid value")
            quit(1)
