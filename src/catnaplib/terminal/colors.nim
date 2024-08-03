from "../global/definitions" import Color, ColorSet
import strutils
import re

proc initForeground(): ColorSet = # (..)
    result.Black   = "\e[30m"   # BK
    result.Red     = "\e[31m"   # RD
    result.Green   = "\e[32m"   # GN
    result.Yellow  = "\e[33m"   # YW
    result.Blue    = "\e[34m"   # BE
    result.Magenta = "\e[35m"   # MA
    result.Cyan    = "\e[36m"   # CN
    result.White   = "\e[37m"   # WE

proc initForegroundBright(): ColorSet = # {..}
    result.Black   = "\e[30;1m" # BK
    result.Red     = "\e[31;1m" # RD
    result.Green   = "\e[32;1m" # GN
    result.Yellow  = "\e[33;1m" # YW
    result.Blue    = "\e[34;1m" # BE
    result.Magenta = "\e[35;1m" # MA
    result.Cyan    = "\e[36;1m" # CN
    result.White   = "\e[37;1m" # WE

proc initBackground(): ColorSet = # [..]
    result.Black   = "\e[40m"   # BK
    result.Red     = "\e[41m"   # RD
    result.Green   = "\e[42m"   # GN
    result.Yellow  = "\e[43m"   # YW
    result.Blue    = "\e[44m"   # BE
    result.Magenta = "\e[45m"   # MA
    result.Cyan    = "\e[46m"   # CN
    result.White   = "\e[47m"   # WE

proc initBackgroundBright(): ColorSet = # <..>
    result.Black   = "\e[40;1m" # BK
    result.Red     = "\e[41;1m" # RD
    result.Green   = "\e[42;1m" # GN
    result.Yellow  = "\e[43;1m" # YW
    result.Blue    = "\e[44;1m" # BE
    result.Magenta = "\e[45;1m" # MA
    result.Cyan    = "\e[46;1m" # CN
    result.White   = "\e[47;1m" # WE

# Global ColorSets:
const
    Foreground*:        ColorSet = static: initForeground()
    ForegroundBright*:  ColorSet = static: initForegroundBright()
    Background*:       ColorSet = static: initBackground()
    BackgroundBright*: ColorSet = static: initBackgroundBright()

# Reset Value
const Default*: Color = static: "\e[0m" # !DT!

proc Colorize*(s: string): string =
    # Function to replace color codes with the correct ansi color code.

    result = s # Parse normal Foreground
        .replace("(BK)", Foreground.Black)
        .replace("(RD)", Foreground.Red)
        .replace("(GN)", Foreground.Green)
        .replace("(YW)", Foreground.Yellow)
        .replace("(BE)", Foreground.Blue)
        .replace("(MA)", Foreground.Magenta)
        .replace("(CN)", Foreground.Cyan)
        .replace("(WE)", Foreground.White)

    result = result # Parse bright Foreground
        .replace("{BK}", ForegroundBright.Black)
        .replace("{RD}", ForegroundBright.Red)
        .replace("{GN}", ForegroundBright.Green)
        .replace("{YW}", ForegroundBright.Yellow)
        .replace("{BE}", ForegroundBright.Blue)
        .replace("{MA}", ForegroundBright.Magenta)
        .replace("{CN}", ForegroundBright.Cyan)
        .replace("{WE}", ForegroundBright.White)

    result = result # Parse normal Background
        .replace("[BK]", Background.Black)
        .replace("[RD]", Background.Red)
        .replace("[GN]", Background.Green)
        .replace("[YW]", Background.Yellow)
        .replace("[BE]", Background.Blue)
        .replace("[MA]", Background.Magenta)
        .replace("[CN]", Background.Cyan)
        .replace("[WE]", Background.White)

    result = result # Parse bright Background
        .replace("<BK>", BackgroundBright.Black)
        .replace("<RD>", BackgroundBright.Red)
        .replace("<GN>", BackgroundBright.Green)
        .replace("<YW>", BackgroundBright.Yellow)
        .replace("<BE>", BackgroundBright.Blue)
        .replace("<MA>", BackgroundBright.Magenta)
        .replace("<CN>", BackgroundBright.Cyan)
        .replace("<WE>", BackgroundBright.White)

    result = result.replace("!DT!", Default) # Parse Default

proc Uncolorize*(s: string): string =
    ## Removes ansi color codes from string
    result = re.replace(s, re"\e(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])", "")

proc Reset*() =
    stdout.write(Default)
    stdout.flushFile()
