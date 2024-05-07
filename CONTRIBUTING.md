# How to contribute
Just create a new [Issue](https://github.com/iinsertNameHere/catnip/issues) using the Correct Template or Implement an existing one and create a Pull request for it.

# Project structure
```shell
.
├── config/
│   ├── config.toml  # Main config
│   └── distros.toml # Distro Art Config
├── docs/  # Contains man docs
├── image/ # Contains all images for Readme
├── src/
│   ├── catniplib/
│   │   ├── drawing/    # Stuff rendering to output
│   │   ├── generation/ # Stuff generating render objects
│   │   ├── global/     # Stuff used globally
│   │   ├── platform/   # Stuff related to fetching system info
│   │   └── terminal/   # Stuff related to terminal stuff (Colors, Logging)
│   ├── extern/
│   │   ├── headers/   # Contains extern c++ headers (hpp)
│   │   └── libraries/ # Contains extern libs
│   └── catnip.nim # Entry src file
└── config.nims
```