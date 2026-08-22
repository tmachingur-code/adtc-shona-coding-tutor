#!/bin/bash
# Downloads the Gemma-2-2b-it GGUF model weights for the ADTC 2026 submission.
# Public, unauthenticated download - no credentials required.
# Idempotent + resumable: continues a partial download if interrupted,

MODEL_DIR="model"
MODEL_FILE="gemma-2-2b-it-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"

mkdir -p "$MODEL_DIR"
DEST="$MODEL_DIR/$MODEL_FILE"


trap 'echo; echo "Download interrupted. Partial file kept at $DEST for resuming. Re-run the script to continue."; exit 130' INT TERM

echo "Downloading $MODEL_FILE (resumable)..."

wget -c \
     --tries=0 \
     --retry-connrefused \
     --waitretry=5 \
     --timeout=30 \
     -O "$DEST" \
     "$MODEL_URL"
WGET_STATUS=$?

if [ $WGET_STATUS -ne 0 ]; then
    echo "Download failed or was interrupted (wget exit code $WGET_STATUS)."
    echo "Partial file kept at $DEST - re-run the script to resume."
    exit $WGET_STATUS
fi


REMOTE_SIZE=$(wget --spider --server-response -O /dev/null "$MODEL_URL" 2>&1 \
    | grep -i "Content-Length" | tail -1 | awk '{print $2}' | tr -d '\r')
LOCAL_SIZE=$(stat -c%s "$DEST" 2>/dev/null || stat -f%z "$DEST")

if [ -n "$REMOTE_SIZE" ] && [ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]; then
    echo "File size mismatch: got $LOCAL_SIZE bytes, expected $REMOTE_SIZE bytes."
    echo "Download is incomplete. Re-run the script to resume."
    exit 1
fi

echo "Download complete: $DEST"