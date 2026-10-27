#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <qv_file> <completeness_file> <mode[hybrid,hifi])>" >&2
    exit 1
fi

qv=$(awk -F'\t' '{print $4}' "$1")
comp=$(awk -F'\t' '{print $5}' "$2")
mode=$3

if [[ "$mode" == "hybrid" ]]; then
    if awk -v comp="$comp" -v qv="$qv" \
        'BEGIN {
            if (comp > 99.0 && (qv == "inf" || qv > 40.0)) exit 0
            exit 1
        }'
    then
        echo "PASS" > EVAL.txt
    else
        echo "WARN[C:$comp,QV:$qv]" > EVAL.txt
    fi
fi

if [[ "$mode" == "hifi" ]]; then
    if awk -v comp="$comp" -v qv="$qv" \
        'BEGIN {
            if (comp > 98.5 && (qv == "inf" || qv > 35.0)) exit 0
            exit 1
        }'
    then
        echo "PASS" > EVAL.txt
else
        echo "WARN[C:$comp,QV:$qv]" > EVAL.txt
    fi
fi