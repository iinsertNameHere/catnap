import unicode
import "Colors"

proc repeat*(s: string, i: int): string =
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    result = Colors.Uncolorize(s).runeLen