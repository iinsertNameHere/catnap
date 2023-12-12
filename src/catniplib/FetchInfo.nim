import "FetchFunctions"
import "std/json"
import "std/strutils"
import "Utils"
import "Colors"
import "std/terminal"

type Logo* = object
    margin*: array[3, int]
    art*: seq[string]

type FetchInfo* = object
    username*: string
    hostname*: string
    distro*: string
    uptime*: string
    kernel*: string
    shell*: string
    desktop*: string
    logo*: Logo

let config = parseJson(readFile("/home/iinsert/.config/catnip.json"))

proc GetFetchInfo*(distroID: string = "nil"): FetchInfo =
    result.username = FetchFunctions.getUser()
    result.hostname = FetchFunctions.getHostname()
    result.distro   = FetchFunctions.getDistro()
    result.uptime   = FetchFunctions.getUptime()
    result.kernel   = FetchFunctions.getKernel()
    result.shell    = FetchFunctions.getShell()
    result.desktop  = FetchFunctions.getDesktop()

    var distroid = (if distroID != "nil": distroID else: result.distro.toLowerAscii())

    if config["distros"]{distroid} == nil:
        distroid = "default"

    let jalias = config["distros"][distroid]{"alias"} 
    if jalias != nil:
        distroid = jalias.getStr()
        if config["distros"]{distroid} == nil:
            distroid = "default"

    let jmargin = config["distros"][distroid]["margin"]
    result.logo.margin = [jmargin[0].getInt(), jmargin[1].getInt(), jmargin[2].getInt()]
    for line in config["distros"][distroid]["art"]:
        result.logo.art.add(line.getStr())

proc Render*(fetchinfo: FetchInfo) =
    var art = fetchinfo.logo.art
    let margin_top = fetchinfo.logo.margin[0]
    let margin_left = fetchinfo.logo.margin[1]
    let margin_right = fetchinfo.logo.margin[2]

    var line = 1

    for _ in countup(0, margin_top):
        art = " ".repeat(art[0].len) & art

    var bl0ck: seq[string]

    var statslen = 0
    proc registerStat(stat: string): string =
        if statslen < stat.reallen:
            statslen = stat.reallen - 1
        return stat

    let stat_username = registerStat Colors.Colorize(config["stats"]["username"].getStr())
    let stat_hostname = registerStat Colors.Colorize(config["stats"]["hostname"].getStr())
    let stat_uptime   = registerStat Colors.Colorize(config["stats"]["uptime"].getStr())
    let stat_distro   = registerStat Colors.Colorize(config["stats"]["distro"].getStr())
    let stat_kernel   = registerStat Colors.Colorize(config["stats"]["kernel"].getStr())
    let stat_desktop  = registerStat Colors.Colorize(config["stats"]["desktop"].getStr())
    let stat_shell    = registerStat Colors.Colorize(config["stats"]["shell"].getStr())
    let stat_colors     = registerStat Colors.Colorize(config["stats"]["colors"].getStr())

    proc addStat(icon: string, name: string, value: string) =
        var fname = name.replace("#", icon)
        bl0ck.add("│ " & fname & " ".repeat((statslen - name.len) - 1) & Colors.Default & " │ " & value)
    
    bl0ck.add("╭" & "─".repeat(statslen + 3) & "╮")
    addStat(" ", stat_username, fetchinfo.username)
    addStat(" ", stat_hostname, fetchinfo.hostname)
    addStat(" ", stat_uptime, fetchinfo.uptime)
    addStat(" ", stat_distro, fetchinfo.distro)
    addStat(" ", stat_kernel, fetchinfo.kernel)
    addStat("󰧨 ", stat_desktop, fetchinfo.desktop)
    addStat(" ", stat_shell, fetchinfo.shell)
    bl0ck.add("├" & "─".repeat(statslen + 3) & "┤")

    let color_icon = config["stats"]["color_icon"].getStr()
    addStat(" ", stat_colors, Colors.Colorize(
        "(WE)" & color_icon & " (RD)" & color_icon &
        " (YW)" & color_icon & " (GN)" & color_icon & 
        " (CN)" & color_icon & " (BE)" & color_icon &
        " (MA)" & color_icon & " (BK)" & color_icon &
        "!DT!"
    ))

    bl0ck.add("╰" & "─".repeat(statslen + 3) & "╯")

    for artline in art:
        echo Colors.Colorize(" ".repeat(margin_left) & artline & " ".repeat(margin_left))
        Colors.Reset()
    
    cursorUp art.len
    cursorForward art[0].len + margin_left + margin_right - 1

    for blockline in bl0ck:
        echo blockline
        cursorForward art[0].len + margin_left + margin_right - 1
        line += 1
    
    while line < art.len - 1:
        echo ""
        cursorForward art[0].len + margin_left + margin_right
        line += 1