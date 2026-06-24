import config


# const src = """
#  // catnap DSL test config
#
#  // import "theme.cat"
#
#  // Variables
#  $border_line     = "╭─╮╰─╯"
#  $separator       = '─'
#  $accent          = #cba6f7
#  $rgb_accent      = (255 100 200)
#  $alert           = !31
#  $count           = 42
#  $enabled         = true
#
#  // Border and layout config
#  $border_template = $border_line
#  $layout          = "Inline"
#
#  // Margins: [top left]
#  $stats_margins = [2 0]
#
#  // Full stats list
#  $stats = [
#      {@username icon='󰀄' label="user"}
#      {@hostname icon='󰒋' label="hostname"}
#      {@separator icon=$separator}
#      {@uptime icon='󰔟' label="uptime" enabled=false}
#      {@distro icon='󰣇' label="distro" color=#cba6f7}
#      {@kernel icon='󰌽' label="kernel" cache=false}
#      {@desktop icon='󰇄' label="desktop" color=(128 0 255)}
#      {@terminal icon='󰆍' label="term" enabled=true}
#      {@separator icon=$separator color=$accent}
#      {@colors icon='󰏘' label="colors" alert=!31}
#  ]
# """

const src = """
import "test1.cat"

$test1 = $test
$test = $hi
"""

let cfg = loadConfig(src)
dumpConfig(cfg)
