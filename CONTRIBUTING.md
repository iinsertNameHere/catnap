# How to contribute
Just create a new [Issue](https://github.com/iinsertNameHere/catnip/issues) using the Correct Template or Implement an existing one and create a Pull request for it.

# Project structure
```graphql
.
├── config/
│   ├── config.toml  # Main config
│   └── distros.toml # Distro Art Config
├── docs/  # Contains man docs
├── image/ # Contains all images for Readme
├── src/
│   ├── catniplib/
│   │   ├── drawing/    # Files for rendering output
│   │   ├── generation/ # Files for generating output objects
│   │   ├── global/     # Files used globally
│   │   ├── platform/   # Files related to fetching system info
│   │   └── terminal/   # Files related to terminal stuff (Colors, Logging)
│   ├── extern/
│   │   ├── headers/   # Contains extern c++ headers (hpp)
│   │   └── libraries/ # Contains extern libs
│   └── catnip.nim # Entry src file
├── scripts/
│   ├── test-commandline-args.sh # Checks if catnip's cmd args work
│   └── git-commit-id.sh         # Generates the currentcommit.nim file
└── config.nims
```
