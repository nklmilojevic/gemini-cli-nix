#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_FILE="$REPO_DIR/package.nix"
WRAPPER_DIR="$REPO_DIR/wrapper"

usage() {
    echo "Usage: $0 [--check | <version>]"
    echo ""
    echo "Options:"
    echo "  --check     Check if a new version is available"
    echo "  <version>   Update to a specific version (e.g., 0.29.3)"
    echo ""
    echo "Examples:"
    echo "  $0 --check"
    echo "  $0 0.29.3"
    exit 1
}

get_current_version() {
    grep 'version = ' "$PACKAGE_FILE" | head -1 | cut -d'"' -f2
}

get_latest_version() {
    curl -s https://registry.npmjs.org/@google/gemini-cli/latest | \
        sed -n 's/.*"version":"\([^"]*\)".*/\1/p'
}

if [ $# -eq 0 ]; then
    usage
fi

if [ "$1" = "--check" ]; then
    CURRENT_VERSION=$(get_current_version)
    LATEST_VERSION=$(get_latest_version)

    echo "Current version: $CURRENT_VERSION"
    echo "Latest version:  $LATEST_VERSION"

    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo "Already up to date!"
        exit 0
    else
        echo "New version available: $LATEST_VERSION"
        echo "Run './scripts/update.sh $LATEST_VERSION' to update"
        exit 1
    fi
fi

VERSION="$1"

echo "Updating to Gemini CLI version $VERSION..."

# Update wrapper/package.json
echo "Updating wrapper/package.json..."
cat > "$WRAPPER_DIR/package.json" << EOF
{
  "name": "gemini-cli-nix-wrapper",
  "version": "$VERSION",
  "private": true,
  "dependencies": {
    "@google/gemini-cli": "$VERSION"
  }
}
EOF

# Regenerate package-lock.json
echo "Regenerating package-lock.json..."
cd "$WRAPPER_DIR"
rm -rf node_modules
npm install --package-lock-only 2>/dev/null

if [ ! -f package-lock.json ]; then
    echo "Error: Failed to generate package-lock.json for version $VERSION"
    echo "The version might not exist on npm"
    exit 1
fi

# Clean up node_modules if created
rm -rf node_modules
cd "$REPO_DIR"

# Calculate npmDepsHash
echo "Calculating npmDepsHash..."
NPM_DEPS_HASH=$(prefetch-npm-deps "$WRAPPER_DIR/package-lock.json" 2>/dev/null || \
    nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$WRAPPER_DIR/package-lock.json" 2>/dev/null)

if [ -z "$NPM_DEPS_HASH" ]; then
    echo "Error: Could not calculate npmDepsHash"
    exit 1
fi

echo "  npmDepsHash: $NPM_DEPS_HASH"

# Update package.nix version
sed -i.bak 's/version = "[^"]*"/version = "'"$VERSION"'"/' "$PACKAGE_FILE"
rm -f "${PACKAGE_FILE}.bak"

# Update npmDepsHash
sed -i.bak 's|npmDepsHash = "[^"]*"|npmDepsHash = "'"$NPM_DEPS_HASH"'"|' "$PACKAGE_FILE"
rm -f "${PACKAGE_FILE}.bak"

echo "Testing build..."
if nix build --no-link; then
    echo "Build successful!"
    echo ""
    echo "Version $VERSION has been successfully updated."
    echo "Don't forget to:"
    echo "  1. Test the new version: nix run . -- --version"
    echo "  2. Commit your changes"
    echo "  3. Push to GitHub"
else
    echo "Build failed. Please check the error messages above."
    exit 1
fi
