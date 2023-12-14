import "FetchFunctions"
import "std/json"
import "Utils"
import "Colors"
import unicode

type Logo = object
    margin*: array[3, int]
    art*: seq[string]

type DistroID = object
    id: string
    like: string

type FetchInfo* = object
    username*: string
    hostname*: string
    distro*: string
    distroid*: DistroID
    uptime*: string
    kernel*: string
    shell*: string
    desktop*: string
    logo*: Logo

proc GetFetchInfo*(distroID: string = "nil"): FetchInfo =
    result.username = "catnip"# FetchFunctions.getUser()
    result.hostname = "archsystem" # FetchFunctions.getHostname()
    result.distro   = "Arch Linux x86_64" # FetchFunctions.getDistro()
    result.uptime   = FetchFunctions.getUptime()
    result.kernel   = FetchFunctions.getKernel()
    result.desktop  = "Hyprland" # FetchFunctions.getDesktop()
    result.shell    = FetchFunctions.getShell()

    let tmpid = FetchFunctions.getDistroID()
    result.distroid.id = tmpid[0]
    result.distroid.like = tmpid[1]

    var distroid = (if distroID != "nil": distroID else: result.distroid.id)

    let config = parseJson(readFile("/home/iinsert/.config/catnip.json"))

    if config["distros"]{distroid} == nil:
        distroid = result.distroid.like
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
    ## Function that Renders a FetchInfo object to the console
    
    ##### Define output buffers #####
    var distro_art: seq[string]
    var stats_block: seq[string]

    ##### Define Margins #####
    let margin_top = fetchinfo.logo.margin[0]
    let margin_left = fetchinfo.logo.margin[1]
    let margin_right = fetchinfo.logo.margin[2]

    ##### Load Config #####
    let config = parseJson(readFile("/home/iinsert/.config/catnip.json"))

    ##### Define Functions #####
    var statlen = 0 # lenght of the longest stat line
    
    func registerStat(stat: JsonNode): JsonNode =
        ## Function that is used to register the stats lenght and compare it to statlen
        let l = stat["icon"].getStr().runeLen + stat["name"].getStr().runeLen + 1
        if l > statlen:
            statlen = l
        return stat

    func addStat(icon: string, name: string, color: string, value: string) =
        ## Function Adds a stat to the stats_block buffer
        var line = icon & " " & name 
        while line.runeLen < statlen:
            line &= " "
        stats_block.add("│ " & color.Colorize() & line & Colors.Default & " │ " & value)

    ##### Build distro_art buffer #####

    # Fill distro_art buffer with fetchinfo.logo.art
    for idx in countup(0, fetchinfo.logo.art.len - 1):
        distro_art.add(" ".repeat(margin_left) & Colors.Colorize(fetchinfo.logo.art[idx]) & Colors.Default & " ".repeat(margin_right))

    # Add margin_top lines ontop of the distro_art
    if margin_top > 0:
        var l = distro_art[0].reallen - 1
        for _ in countup(0, margin_top):
            distro_art = " ".repeat(l) & distro_art

    ##### Build stat_block buffer #####

    # Get and register stats
    let stat_username = registerStat(config["stats"]["username"])
    let stat_hostname = registerStat(config["stats"]["hostname"])
    let stat_uptime   = registerStat(config["stats"]["uptime"])
    let stat_distro   = registerStat(config["stats"]["distro"])
    let stat_kernel   = registerStat(config["stats"]["kernel"])
    let stat_desktop  = registerStat(config["stats"]["desktop"])
    let stat_shell    = registerStat(config["stats"]["shell"])
    let stat_colors   = registerStat(config["stats"]["colors"])

    # Build the stat_block buffer
    stats_block.add("╭" & "─".repeat(statlen + 1) & "╮")
    addStat(stat_username["icon"].getStr(), stat_username["name"].getStr(), stat_username["color"].getStr(), fetchinfo.username)
    addStat(stat_hostname["icon"].getStr(), stat_hostname["name"].getStr(), stat_hostname["color"].getStr(), fetchinfo.hostname)
    addStat(stat_uptime["icon"].getStr(),   stat_uptime["name"].getStr(),   stat_uptime["color"].getStr(),   fetchinfo.uptime)
    addStat(stat_distro["icon"].getStr(),   stat_distro["name"].getStr(),   stat_distro["color"].getStr(),   fetchinfo.distro)
    addStat(stat_kernel["icon"].getStr(),   stat_kernel["name"].getStr(),   stat_kernel["color"].getStr(),   fetchinfo.kernel)
    addStat(stat_desktop["icon"].getStr(),  stat_desktop["name"].getStr(),  stat_desktop["color"].getStr(),  fetchinfo.desktop)
    addStat(stat_shell["icon"].getStr(),    stat_shell["name"].getStr(),    stat_shell["color"].getStr(),    fetchinfo.shell)
    stats_block.add("├" & "─".repeat(statlen + 1) & "┤")
    let symbol = stat_colors["symbol"].getStr()
    addStat(stat_colors["icon"].getStr(),    stat_colors["name"].getStr(),    stat_colors["color"].getStr(), Colors.Colorize(
    "(WE)"&symbol&" (RD)"&symbol&" (YW)"&symbol&" (GN)"&symbol&" (CN)"&symbol&" (BE)"&symbol&" (MA)"&symbol&" (BK)"&symbol&"!DT!"))
    stats_block.add("╰" & "─".repeat(statlen + 1) & "╯")

    ##### Merge buffers and output #####
    
    let lendiv = stats_block.len - distro_art.len
    if lendiv < 0:
        for _ in countup(1, lendiv - lendiv*2):
            stats_block.add(" ")
    elif lendiv > 0:
        for _ in countup(1, lendiv):
            distro_art.add(" ".repeat(distro_art[0].reallen - 1))

    for idx in countup(0, distro_art.len - 1):
        echo distro_art[idx] & stats_block[idx]