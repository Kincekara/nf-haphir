#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <input_file> <output_file> <prefix>" >&2
    exit 1
fi

input_file="$1"
output_file="$2"
prefix="$3"

awk -v prefix="$prefix" '
    /^>/ {
        count++
        # Remove leading ">" and split header into fields
        sub(/^>/, "", $0)
        split($0, a, " ")
        # Replace only the first field with prefixN
        a[1] = prefix count
        # Reconstruct header
        printf ">%s", a[1]
        for (i=2; i<=length(a); i++) printf " %s", a[i]
        printf "\n"
        next
    }
    {print}
    ' "$input_file" > "$output_file"
exit 0