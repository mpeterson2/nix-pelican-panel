#!/usr/bin/env bash

set -e

get_latest_version() {
    local repo=$1
    curl -s "https://api.github.com/repos/pelican-dev/$repo/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

update_version() {
    local file=$1
    local version=$2
    sed -i "s/version = \".*\";/version = \"$version\";/" "$file"
}

update_source_hash() {
    local file=$1
    local repo=$2
    local version=$3
    local hash=$(nix-shell -p nix-prefetch-github --run "nix-prefetch-github pelican-dev $repo --rev v$version" 2>/dev/null | jq -r '.hash')
    sed -i "s|sha256 = \"sha256-.*\";|sha256 = \"$hash\";|" "$file"
}

update_dependency_hash() {
    local file=$1
    local hash_key=$2
    local flake=$3
    sed -i "s|$hash_key = \"sha256-.*\";|$hash_key = \"\";|" "$file"
    local hash=$(nix build ".#$flake" 2>&1 >/dev/null | grep -oP 'got:\s+\K\S+' | head -1)
    sed -i "s|$hash_key = \"\";|$hash_key = \"$hash\";|" "$file"
}

update_vendor_hash() {
    local file=$1
    local flake=$2
    update_dependency_hash "$file" "vendorHash" "$flake"
}

update_hash() {
    local file=$1
    local flake=$2
    update_dependency_hash "$file" "hash" "$flake"
}

echo "🔄 Updating Pelican Panel packages..."

echo "📡 Fetching latest versions..."
panel_version=$(get_latest_version "panel")
wings_version=$(get_latest_version "wings")

echo "🔧 Updating Pelican Panel to $panel_version"
update_version "lib/pelican-panel.nix" "$panel_version"
update_source_hash "lib/pelican-panel.nix" "panel" "$panel_version"
update_vendor_hash "lib/pelican-panel-php.nix" "pelican-panel"
update_hash "lib/pelican-panel-js.nix" "pelican-panel"

echo "🔧 Updating Wings to $wings_version"
update_version "lib/wings.nix" "$wings_version"
update_source_hash "lib/wings.nix" "wings" "$wings_version"

echo "🔧 Updating Wings vendor hash..."
update_vendor_hash "lib/wings.nix" "wings"

echo "✅ Done! Updated to Panel $panel_version, Wings $wings_version"
