#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --architecture FILE    Specify the architecture file (.pl)"
    echo "  -r, --rules FILE           Specify the rules file (.P)"
    echo "  -o, --output DIR           Specify the output directory"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -a scenario1_arch.pl -r scenario1_rules.P -o scenario1"
}

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
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Check for mandatory arguments
if [[ -z "$architecture" || -z "$rules" || -z "$output" ]]; then
    echo "Error: Missing mandatory arguments."
    show_help
    exit 1
fi

# Manage directory
mkdir -p "$output"

# Prepare and run MulVAL
cp "$architecture" "$rules" "$output/"
docker run --rm -v "$(pwd)/$output":/input -w /input wilbercui/mulval graph_gen.sh "$(basename "$architecture")" -v -p -r "$(basename "$rules")" --nometric
