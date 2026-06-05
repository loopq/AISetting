#!/usr/bin/env bash
# Figma 资源批量导出 → Android res/ 目录
#
# Usage:
#   FIGMA_TOKEN=figd_xxx .claude/scripts/figma-export.sh <assets.json>
#
# Setup: see .claude/figma-asset-export-guide.md
#
# bitmap 管线：Figma /v1/images?format=png → pngquant 减色 → cwebp lossless → drawable-xxhdpi/
# vector (SVG → Vector Drawable) TODO，本版本未支持。

set -euo pipefail

err() { echo "[figma-export] ERROR: $*" >&2; exit 1; }
log() { echo "[figma-export] $*"; }

# ---------- 入参 / 环境校验 ----------
[ "${FIGMA_TOKEN:-}" ] || err "FIGMA_TOKEN env var required. See .claude/figma-asset-export-guide.md"
[ "$#" -ge 1 ] || err "Usage: $0 <assets.json>"

ASSETS_JSON="$1"
[ -f "$ASSETS_JSON" ] || err "File not found: $ASSETS_JSON"

command -v jq       >/dev/null || err "jq not installed (brew install jq)"
command -v pngquant >/dev/null || err "pngquant not installed (brew install pngquant)"
command -v cwebp    >/dev/null || err "cwebp not installed (brew install webp)"
command -v curl     >/dev/null || err "curl not installed"

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || err "not in a git repo"
RES_DIR="$PROJECT_ROOT/app/src/main/res"
[ -d "$RES_DIR" ] || err "res dir not found: $RES_DIR"

FILE_KEY=$(jq -r '.file_key // empty' "$ASSETS_JSON")
[ -n "$FILE_KEY" ] || err "file_key missing in $ASSETS_JSON"

ASSETS_COUNT=$(jq '.assets | length' "$ASSETS_JSON")
[ "$ASSETS_COUNT" -gt 0 ] || err "no assets in $ASSETS_JSON"

log "file_key:    $FILE_KEY"
log "assets:      $ASSETS_COUNT"
log "res_dir:     $RES_DIR"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

OK_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for i in $(seq 0 $((ASSETS_COUNT - 1))); do
  ASSET=$(jq ".assets[$i]" "$ASSETS_JSON")
  NAME=$(echo "$ASSET"    | jq -r '.name')
  NODE_ID=$(echo "$ASSET" | jq -r '.node_id')
  TYPE=$(echo "$ASSET"    | jq -r '.type')
  EXT=$(echo "$ASSET"     | jq -r '.ext')
  SCALE=$(echo "$ASSET"   | jq -r '.scale // 1')
  DEST=$(echo "$ASSET"    | jq -r '.dest')
  HAS_QUALITY=$(echo "$ASSET" | jq -r 'has("quality")')

  log ""
  log "[$((i+1))/$ASSETS_COUNT] $NAME (node=$NODE_ID, type=$TYPE, scale=$SCALE)"

  if [ "$HAS_QUALITY" = "true" ]; then
    log "  WARN: 'quality' field is deprecated (lossless cwebp pipeline ignores it). Remove from assets.json."
  fi

  case "$TYPE" in
    bitmap) FORMAT=png ;;
    vector)
      log "  SKIP: vector type not yet supported in v1 (TODO: SVG → Vector Drawable)"
      SKIP_COUNT=$((SKIP_COUNT+1))
      continue
      ;;
    *)
      log "  SKIP: unknown type '$TYPE'"
      SKIP_COUNT=$((SKIP_COUNT+1))
      continue
      ;;
  esac

  # 1) Figma API 获取下载 URL
  API_URL="https://api.figma.com/v1/images/${FILE_KEY}?ids=${NODE_ID}&format=${FORMAT}&scale=${SCALE}"
  RESP=$(curl -s -w "\n%{http_code}" -H "X-Figma-Token: $FIGMA_TOKEN" "$API_URL")
  HTTP_CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')

  if [ "$HTTP_CODE" != "200" ]; then
    log "  ERROR: Figma API HTTP $HTTP_CODE: $BODY"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  API_ERR=$(echo "$BODY" | jq -r '.err // empty')
  if [ -n "$API_ERR" ]; then
    log "  ERROR: Figma API: $API_ERR"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  DOWNLOAD_URL=$(echo "$BODY" | jq -r ".images[\"$NODE_ID\"] // empty")
  if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    log "  ERROR: no download URL for node $NODE_ID"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  # 2) 下载原始资源
  RAW_FILE="$TMP_DIR/${NAME}.${FORMAT}"
  if ! curl -sLf "$DOWNLOAD_URL" -o "$RAW_FILE"; then
    log "  ERROR: download failed"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  RAW_SIZE=$(wc -c < "$RAW_FILE" | tr -d ' ')
  log "  downloaded: ${RAW_SIZE} bytes"

  # 3) 落到目标目录（按需转换格式）
  TARGET_DIR="$RES_DIR/$DEST"
  mkdir -p "$TARGET_DIR"
  TARGET_FILE="$TARGET_DIR/${NAME}.${EXT}"

  if [ "$FORMAT" = "png" ] && [ "$EXT" = "webp" ]; then
    # 两步管线：pngquant 减色（lossy）→ cwebp -q 80 -m 6 -mt（lossy 强参数）
    # 参数依据：cwebp 部分匹配项目 compress_images.sh webp 路径，pngquant 部分匹配 PNG 路径
    QUANT_FILE="$TMP_DIR/${NAME}.quant.png"
    SOURCE_FOR_CWEBP="$RAW_FILE"
    if pngquant --quality=65-80 --speed 1 --strip --force --output "$QUANT_FILE" "$RAW_FILE" 2>/dev/null; then
      SOURCE_FOR_CWEBP="$QUANT_FILE"
    else
      log "  WARN: pngquant skipped for $NAME (减色失败，回退原 PNG)"
    fi
    cwebp -q 80 -m 6 -mt "$SOURCE_FOR_CWEBP" -o "$TARGET_FILE" >/dev/null 2>&1 || {
      log "  ERROR: cwebp conversion failed"
      FAIL_COUNT=$((FAIL_COUNT+1))
      continue
    }
  elif [ "$FORMAT" = "$EXT" ]; then
    cp "$RAW_FILE" "$TARGET_FILE"
  else
    log "  WARN: $FORMAT → $EXT 未支持的转换组合, 拷贝原始文件"
    cp "$RAW_FILE" "$TARGET_FILE"
  fi

  TARGET_SIZE=$(wc -c < "$TARGET_FILE" | tr -d ' ')
  log "  saved: $TARGET_FILE (${TARGET_SIZE} bytes)"
  OK_COUNT=$((OK_COUNT+1))
done

log ""
log "===== Summary ====="
log "OK:    $OK_COUNT"
log "FAIL:  $FAIL_COUNT"
log "SKIP:  $SKIP_COUNT"

[ "$FAIL_COUNT" -eq 0 ] || exit 2