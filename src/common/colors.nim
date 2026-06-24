from "types" import Color, ColorSet
import strutils
import nre

proc initForeground(): ColorSet =
    result.Black   = "\e[30m"
    result.Red     = "\e[31m"
    result.Green   = "\e[32m"
    result.Yellow  = "\e[33m"
    result.Blue    = "\e[34m"
    result.Magenta = "\e[35m"
    result.Cyan    = "\e[36m"
    result.White   = "\e[37m"

proc initForegroundBright(): ColorSet =
    result.Black   = "\e[30;1m"
    result.Red     = "\e[31;1m"
    result.Green   = "\e[32;1m"
    result.Yellow  = "\e[33;1m"
    result.Blue    = "\e[34;1m"
    result.Magenta = "\e[35;1m"
    result.Cyan    = "\e[36;1m"
    result.White   = "\e[37;1m"

proc initBackground(): ColorSet =
    result.Black   = "\e[40m"
    result.Red     = "\e[41m"
    result.Green   = "\e[42m"
    result.Yellow  = "\e[43m"
    result.Blue    = "\e[44m"
    result.Magenta = "\e[45m"
    result.Cyan    = "\e[46m"
    result.White   = "\e[47m"

proc initBackgroundBright(): ColorSet =
    result.Black   = "\e[40;1m"
    result.Red     = "\e[41;1m"
    result.Green   = "\e[42;1m"
    result.Yellow  = "\e[43;1m"
    result.Blue    = "\e[44;1m"
    result.Magenta = "\e[45;1m"
    result.Cyan    = "\e[46;1m"
    result.White   = "\e[47;1m"

const
    Foreground*:       ColorSet = static: initForeground()
    ForegroundBright*: ColorSet = static: initForegroundBright()
    Background*:       ColorSet = static: initBackground()
    BackgroundBright*: ColorSet = static: initBackgroundBright()

const Default*: Color = static: "\e[0m"

proc Uncolorize*(s: string): string =
    result = s.replace(nre.re"\e(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])", "")

proc Reset*() =
    stdout.write(Default)
    stdout.flushFile()
