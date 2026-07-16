#!/usr/bin/env bash
# Last Banner v2 — 풀 → 게임 심볼릭 링크 셋업 (idempotent)
# Wesnoth 2D PNG only (5 factions)
# Copyright (C) 2003-2026 The Battle for Wesnoth contributors — CC-BY-4.0

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
POOL_DIR="$HOME/work/game-assets-pool"

ASSETS_DIR="$PROJECT_DIR/assets"
WESNOTH="$POOL_DIR/extracted/wesnoth"

mkdir -p "$ASSETS_DIR"/fonts

echo "==> Last Banner v2 자산 셋업 시작"
echo "    POOL_DIR: $POOL_DIR"
echo "    PROJECT:  $PROJECT_DIR"

# 5개 faction만 base idle (no attack/defend) PNG으로 선별
# 패턴: 단순 ID 형태의 PNG (예: bowman.png, swordsman.png, knight.png)
# 제외: -attack-, -defend-, -melee-, -ranged-, -mounted-, -die-, -move-, -stand-horse

link_unit_faction() {
  local faction="$1"
  local src="$WESNOTH/units/$faction"
  local dst="$ASSETS_DIR/units/$faction"

  if [ ! -d "$src" ]; then
    echo "    [SKIP] $faction — not in pool"
    return
  fi

  mkdir -p "$dst"
  echo "    [LINK] $faction"

  # 단순 ID PNG만 선택 (영숫자/하이픈, 단 'attack/defend/melee/ranged/mounted/die/move/stand/horse' 제외)
  cd "$src"
  for f in *.png; do
    [ -f "$f" ] || continue
    base="${f%.png}"
    # 제외 패턴
    case "$base" in
      *-attack-*|*-defend-*|*-melee-*|*-ranged-*|*-mounted-*|*-die-*|*-move-*|*-stand-*|*-horse*|*-idle*|*-frame_*|*-frame-*)
        continue ;;
    esac
    # 디렉터리는 제외 (archer/ 같은 서브폴더)
    [ -f "$f" ] || continue
    # 단순 ID: 영숫자, 하이픈 1개 정도 OK
    if [[ "$base" =~ ^[a-z0-9_-]+$ ]] && [ ! -e "$dst/$f" ]; then
      ln -s "$src/$f" "$dst/$f"
    fi
  done

  # 카운트
  count=$(find "$dst" -maxdepth 1 -type l -name "*.png" | wc -l | tr -d ' ')
  echo "           → $count idle PNG"
}

# 5개 faction
link_unit_faction "human-loyalists"
link_unit_faction "human-outlaws"
link_unit_faction "dunefolk"
link_unit_faction "undead-skeletal"
link_unit_faction "orcs"

# Portraits (서브폴더로 정확하게)
for race in humans dunefolk undead orcs; do
  src="$WESNOTH/portraits/$race"
  dst="$ASSETS_DIR/portraits/$race"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    echo "    [LINK] portraits/$race"
    count=0
    for f in "$src"/*.webp "$src"/*.png; do
      [ -f "$f" ] || continue
      base="$(basename "$f")"
      if [ ! -e "$dst/$base" ]; then
        ln -s "$f" "$dst/$base"
        count=$((count + 1))
        [ $count -ge 12 ] && break   # 12개씩만
      fi
    done
    echo "           → $count portraits"
  fi
done

# .gdignore 제거됨 (v2는 res:// 직접 사용 — v1 lazy fetch 패턴 폐기)

echo ""
echo "==> 자산 셋업 완료"
echo "    Linked factions: human-loyalists, human-outlaws, dunefolk, undead-skeletal, orcs"
echo ""
echo "다음 단계:"
echo "  1. cd $PROJECT_DIR"
echo "  2. godot --headless --import"
echo "  3. LB_VERIFY=1 godot --headless    # 검증"
