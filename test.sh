# alias for config
alias catnip='./bin/catnip -c config/config.toml -a config/distros.toml'
# test help
catnip -h
# test distroid
catnip -d arch
# test margin
catnip -m 1,2,3
# test layout
catnip -l ArtOnTop
# test figletlogos mode
catnip -fe on
# test figletlogos margin
catnip -fe on -fm 1,2,3
