#!/bin/sh
echo "const CURRENTCOMMIT* = static: \"$(git rev-parse HEAD)"\"\ > src/catnaplib/global/currentcommit.nim
