import tables
from "../common/types" import Color

type
    Stat* = object
      icon*: string
      name*: string
      color*:  Color

    Stats* = object
      maxlen*: uint
      list*: Table[string, Stat]
      color_symbol*: string
