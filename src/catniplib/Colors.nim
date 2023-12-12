import re
import strutils

type ColorSet* = object
    Black*:   string
    Red*:     string
    Green*:   string
    Yellow*:  string
    Blue*:    string
    Magenta*: string
    Cyan*:    string
    White*:   string

proc colorset_initFront(): ColorSet = # (..)
    result.Black   = "\e[30m"   # BK
    result.Red     = "\e[31m"   # RD
    result.Green   = "\e[32m"   # GN
    result.Yellow  = "\e[33m"   # YW
    result.Blue    = "\e[34m"   # BE
    result.Magenta = "\e[35m"   # MA
    result.Cyan    = "\e[36m"   # CN
    result.White   = "\e[37m"   # WE


proc colorset_initFrontBright(): ColorSet = # {..}
    result.Black   = "\e[30;1m" # BK
    result.Red     = "\e[31;1m" # RD
    result.Green   = "\e[32;1m" # GN
    result.Yellow  = "\e[33;1m" # YW
    result.Blue    = "\e[34;1m" # BE
    result.Magenta = "\e[35;1m" # MA
    result.Cyan    = "\e[36;1m" # CN
    result.White   = "\e[37;1m" # WE

proc colorset_initBack(): ColorSet = # [..]
    result.Black   = "\e[40m"   # BK
    result.Red     = "\e[41m"   # RD
    result.Green   = "\e[42m"   # GN
    result.Yellow  = "\e[43m"   # YW
    result.Blue    = "\e[44m"   # BE
    result.Magenta = "\e[45m"   # MA
    result.Cyan    = "\e[46m"   # CN
    result.White   = "\e[47m"   # WE

proc colorset_initBackBright(): ColorSet = # <..>
    result.Black   = "\e[40;1m" # BK
    result.Red     = "\e[41;1m" # RD
    result.Green   = "\e[42;1m" # GN
    result.Yellow  = "\e[43;1m" # YW
    result.Blue    = "\e[44;1m" # BE
    result.Magenta = "\e[45;1m" # MA
    result.Cyan    = "\e[46;1m" # CN
    result.White   = "\e[47;1m" # WE

const Front*:       ColorSet = colorset_initFront()
const FrontBright*: ColorSet = colorset_initFrontBright()
const Back*:        ColorSet = colorset_initBack()
const BackBright*:  ColorSet = colorset_initBackBright()

const Default*: string = "\e[0m" # !DT!

let ANSI: Regex = re"\e(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

proc Colorize*(s: string): string =
    result = s
        .replace("(BK)", Front.Black)
        .replace("(RD)", Front.Red)
        .replace("(GN)", Front.Green)
        .replace("(YW)", Front.Yellow)
        .replace("(BE)", Front.Blue)
        .replace("(MA)", Front.Magenta)
        .replace("(CN)", Front.Cyan)
        .replace("(WE)", Front.White)
    
    result = result
        .replace("{BK}", FrontBright.Black)
        .replace("{RD}", FrontBright.Red)
        .replace("{GN}", FrontBright.Green)
        .replace("{YW}", FrontBright.Yellow)
        .replace("{BE}", FrontBright.Blue)
        .replace("{MA}", FrontBright.Magenta)
        .replace("{CN}", FrontBright.Cyan)
        .replace("{WE}", FrontBright.White)

    result = result
        .replace("[BK]", Back.Black)
        .replace("[RD]", Back.Red)
        .replace("[GN]", Back.Green)
        .replace("[YW]", Back.Yellow)
        .replace("[BE]", Back.Blue)
        .replace("[MA]", Back.Magenta)
        .replace("[CN]", Back.Cyan)
        .replace("[WE]", Back.White)

    result = result
        .replace("<BK>", BackBright.Black)
        .replace("<RD>", BackBright.Red)
        .replace("<GN>", BackBright.Green)
        .replace("<YW>", BackBright.Yellow)
        .replace("<BE>", BackBright.Blue)
        .replace("<MA>", BackBright.Magenta)
        .replace("<CN>", BackBright.Cyan)
        .replace("<WE>", BackBright.White)

    result = result.replace("!DT!", Default)
    

proc Uncolorize*(s: string): string =
    result = re.replace(s, ANSI)

proc Reset*() =
    stdout.write(Default)