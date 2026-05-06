#!/bin/bash

# Default values
architecture=""
rules=""
output=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a|--architecture) architecture="$2"; shift ;;
        -r|--rules) rules="$2"; shift ;;
        -o|--output) output="$2"; shift ;;
    esac
    shift
done

# Manage directory
mkdir -p "$output"

# Prepare and run MulVAL
cp "$architecture" "$rules" "$output/"
docker run --rm -v "$(pwd)/$output":/input -w /input wilbercui/mulval graph_gen.sh "$(basename "$architecture")" -v -p -r "$(basename "$rules")" --nometric
