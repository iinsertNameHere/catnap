import times
import os
import strformat
import strutils

const datetimeFormat = "YYYY-MM-dd HH:mm:ss"
let INFINITEDURATION* = initDuration(
    nanoseconds = 4294967295,
    microseconds = 4294967295,
    milliseconds = 4294967295,
    seconds = 4294967295,
    minutes = 4294967295,
    hours = 4294967295,
    days = 4294967295,
    weeks = 4294967295)

proc writeCache*(filename: string, content: string, dur: Duration) =
    if fileExists(filename): removeFile(filename)

    var expiration: string
    if dur == INFINITEDURATION:
        expiration = "NEVER"
    else:
        expiration = $(now() + dur).format(datetimeFormat)

    var filecontent = &"[CONTENT]\n{content}\n[EXPIRATION]\n{expiration}"
    writeFile(filename, filecontent)

proc readCache*(filename: string, default: string = ""): string =
    if not fileExists(filename): return default

    var filecontent = readFile(filename).strip()
    let lines = filecontent.split('\n')

    var content: seq[string]
    var expiration: DateTime = now()
    var partindex = 0
    for line in lines:
        if line == "[CONTENT]" and partindex == 0:
            partindex += 1
            continue
        elif line == "[EXPIRATION]" and partindex == 1:
            partindex += 1
            continue

        if partindex == 1:
            content.add(line)
        elif partindex == 2:
            if line == "NEVER": expiration = (now() + 1.hours)
            else: expiration = parse(line, datetimeFormat)
            break
    
    if now() >= expiration: return default
    return content.join("\n")