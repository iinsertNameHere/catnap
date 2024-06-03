#!/bin/sh
echo "const CURRENTCOMMIT* = \"$(git rev-parse HEAD)"\"\ > src/catnaplib/global/currentcommit.nim
