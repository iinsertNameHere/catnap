#!/bin/sh
echo "const CURRENTCOMMIT* = \"$(git rev-parse HEAD)"\"\ > src/catniplib/global/currentcommit.nim
