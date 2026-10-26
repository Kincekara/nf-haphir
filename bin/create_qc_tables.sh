#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <qv_file> <completeness_file>" >&2
    exit 1
fi

qv_file="$1"
comp_file="$2"

awk -F'\t' '
    BEGIN { 
        print "  <tr>" 
    }
    {
        for (i = 1; i <= NF; i++) {
            print "    <td>" $i "</td>"
        }
    }
    END { 
        print "  </tr>" 
    }' "$qv_file" > qv_table

awk -F'\t' '
    BEGIN { 
        print "  <tr>" 
    }
    {
        for (i = 1; i <= NF; i++) {
            print "    <td>" $i "</td>"
        }
    }
    END { 
        print "  </tr>" 
    }' "$comp_file" > comp_table