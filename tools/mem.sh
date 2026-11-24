#!/usr/bin/env bash
# System-wide memory in use (wired + active + compressor-occupied pages), in bytes, plus swap used.
# Process footprints miss mmapped weights and Metal wired buffers on Apple Silicon, so measure the whole machine.
vm_stat | awk -v swap="$(sysctl -n vm.swapusage | awk '{gsub("M","",$6); print $6*1048576}')" '
  /page size of/ {ps=$8} /Pages wired down/ {w=$4} /Pages active/ {a=$3} /occupied by compressor/ {c=$5}
  END {gsub("\\.","",w); gsub("\\.","",a); gsub("\\.","",c); printf "%d\n", (w+a+c)*ps + swap}'
