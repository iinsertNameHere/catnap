import tables
from "../config/types" import Logo

type
    DistroId* = object
        id*: string
        like*: string

    FetchInfo* = object
        list*: Table[string, proc(): string]
        disk_statnames*: seq[string]
        distroId*: DistroId
        logo*: Logo
