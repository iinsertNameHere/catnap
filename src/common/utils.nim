from "definitions" import CACHEPATH, TEMPPATH

proc toCachePath*(p: string): string =
    # Converts a path [p] into a cahce path
    return joinPath(CACHEPATH, p)

proc toTmpPath*(p: string): string =
    # Converts a path [p] into a temp path
    return joinPath(TEMPPATH, p)
