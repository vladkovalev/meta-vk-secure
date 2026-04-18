#!/bin/bash
# SRK Fuse Programming Helper for LS1046A
# WARNING: FUSE PROGRAMMING IS IRREVERSIBLE!
# Usage: program-srk-fuses.sh <srk-fuse-file> [--dry-run|--program]
set -euo pipefail

SRK_FUSE_FILE="${1:?Usage: program-srk-fuses.sh <srk-fuse-file> [--dry-run|--program]}"
MODE="${2:---dry-run}"

[ -f "$SRK_FUSE_FILE" ] || { echo "ERROR: $SRK_FUSE_FILE not found"; exit 1; }

echo "=== LS1046A SRK Fuse Programming ==="
echo "File: $SRK_FUSE_FILE"
echo "Mode: $MODE"
echo ""

echo "SRK Fuse Values:"
for i in $(seq 0 7); do
    OFFSET=$((i * 4))
    WORD=$(od -A n -t x4 -j $OFFSET -N 4 "$SRK_FUSE_FILE" 2>/dev/null | tr -d ' ')
    [ -n "$WORD" ] && echo "  SFP_SRKHR${i} = 0x${WORD}"
done
echo ""

case "$MODE" in
    --dry-run)
        echo "DRY RUN -- commands for U-Boot console:"
        echo ""
        for i in $(seq 0 7); do
            OFFSET=$((i * 4))
            WORD=$(od -A n -t x4 -j $OFFSET -N 4 "$SRK_FUSE_FILE" 2>/dev/null | tr -d ' ')
            [ -n "$WORD" ] && echo "  fuse prog -y 6 $i 0x${WORD}"
        done
        echo ""
        echo "  # Enable secure boot (POINT OF NO RETURN):"
        echo "  fuse prog -y 1 0 0x00000002"
        ;;
    --program)
        echo "Fuses must be programmed from U-Boot console or JTAG."
        echo "Copy commands from --dry-run output."
        ;;
    *)
        echo "ERROR: Use --dry-run or --program"; exit 1 ;;
esac
