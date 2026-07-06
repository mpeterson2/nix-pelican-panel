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

capture_hash() {
    local flake=$1
    local zero=$2
    local output
    output=$(nix build --no-link ".#$flake" 2>&1) || true
    local hash
    hash=$(echo "$output" | grep -A1 -F "specified: $zero" | grep -oP 'got:\s+\K\S+' | head -1)
    if [ -z "$hash" ]; then
        echo "Error: failed to capture hash for .#$flake — build output:" >&2
        echo "$output" >&2
        exit 1
    fi
    echo "$hash"
}

update_source_hash() {
    local file=$1
    local flake=$2
    local zero="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    sed -i "s|sha256 = \"sha256-.*\";|sha256 = \"$zero\";|" "$file"
    local hash
    hash=$(capture_hash "$flake" "$zero")
    sed -i "s|sha256 = \"$zero\";|sha256 = \"$hash\";|" "$file"
}

update_dependency_hash() {
    local file=$1
    local hash_key=$2
    local flake=$3
    local zero="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    sed -i "s|$hash_key = \"sha256-.*\";|$hash_key = \"$zero\";|" "$file"
    local hash
    hash=$(capture_hash "$flake" "$zero")
    sed -i "s|$hash_key = \"$zero\";|$hash_key = \"$hash\";|" "$file"
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
update_source_hash "lib/pelican-panel.nix" "pelican-panel"
update_vendor_hash "lib/pelican-panel-php.nix" "pelican-panel"
update_hash "lib/pelican-panel-js.nix" "pelican-panel"

echo "🔧 Updating Wings to $wings_version"
update_version "lib/wings.nix" "$wings_version"
update_source_hash "lib/wings.nix" "wings"

echo "🔧 Updating Wings vendor hash..."
update_vendor_hash "lib/wings.nix" "wings"

echo "✅ Done! Updated to Panel $panel_version, Wings $wings_version"
