import parsetoml
import tables

type
    Logo* = object
        margin*: array[3, int]
        art*: seq[string]
        isAlias*: bool

    Config* = object
        configFile*: string
        distrosFile*: string
        stats*: TomlValueRef
        distroart*: OrderedTable[string, Logo]
        misc*: TomlValueRef
