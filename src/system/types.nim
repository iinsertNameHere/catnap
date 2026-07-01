import tables
from "../config/types" import Art

type
    OsInfo* = object
        id*: string
        id_like*: string
        name*: string

    FetchInfo* = object
        list*: Table[string, proc(): string]
        disk_statnames*: seq[string]
        os_info*: OsInfo
        art*: Art
