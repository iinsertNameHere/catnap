import parsetoml
import tables
from "../system/types" import Logo

type
    Config* = object
        configFile*: string
        distrosFile*: string
        stats*: TomlValueRef
        distroart*: OrderedTable[string, Logo]
        misc*: TomlValueRef
