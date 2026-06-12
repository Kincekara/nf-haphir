#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <input_file> <output_file>" >&2
    exit 1
fi

input_file="$1"
output_file="$2"

awk -F'\t' '
BEGIN {print "<table>"}
NR==1 {
    print "  <tr>"
    for (i = 1; i <= NF; i++) {
        print "    <th>" $i "</th>"
    }
    print "  </tr>"
    next
}
{
    print "  <tr>"
    for(i=1; i<=NF; i++) print "    <td>" $i "</td>"
    print "  </tr>"
}
END {print "</table>"}' "$input_file" > "$output_file"

exit 0