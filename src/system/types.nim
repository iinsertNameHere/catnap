import tables

type
    Margin = array[3, int]

    Logo* = object
        margin*: Margin
        art*: seq[string]
        isAlias*: bool

    DistroId* = object
        id*: string
        like*: string

    FetchInfo* = object
        list*: Table[string, proc(): string]
        disk_statnames*: seq[string]
        distroId*: DistroId
        logo*: Logo
