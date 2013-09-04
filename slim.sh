#!/bin/sh
if [ $# != 1 ]; then
  echo "Arguments: $0 </full/path/to/rom.zip>"
  exit 1
fi
mkdir -p $HOME/slimtmp
SLIMTMP=$HOME/slimtmp
rm -rf $SLIMTMP/*

# BLAH


