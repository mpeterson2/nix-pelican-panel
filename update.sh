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
    local output
    output=$(nix build --no-link ".#$flake" 2>&1) || true
    local hash
    hash=$(echo "$output" | grep -oP 'got:\s+\K\S+' | head -1)
    if [ -z "$hash" ]; then
        echo "Error: failed to capture hash for .#$flake — build output:" >&2
        echo "$output" >&2
        exit 1
    fi
    echo "$hash"
}


set_hash_and_verify() {
    local file=$1
    local key_pattern=$2 # "sha256" or "vendorHash"
    local flake=$3
    local zero="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    local attempt hash build_output
    for attempt in 1 2 3; do
        sed -i "s|$key_pattern = \".*\";|$key_pattern = \"$zero\";|" "$file"
        hash=$(capture_hash "$flake")
        sed -i "s|$key_pattern = \"$zero\";|$key_pattern = \"$hash\";|" "$file"

        build_output=$(nix build --no-link ".#$flake" 2>&1) && return 0

        if ! echo "$build_output" | grep -qF "specified: $hash"; then
            return 0
        fi
        echo "⚠️ $key_pattern for .#$flake did not reproduce on attempt $attempt, recapturing..." >&2
    done

    echo "Error: $key_pattern for .#$flake did not stabilize after $attempt attempts — last build output:" >&2
    echo "$build_output" >&2
    exit 1
}

update_source_hash() {
    local file=$1
    local flake=$2
    set_hash_and_verify "$file" "sha256" "$flake"
}

update_dependency_hash() {
    local file=$1
    local hash_key=$2
    local flake=$3
    set_hash_and_verify "$file" "$hash_key" "$flake"
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
