#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/electron/electron"
VERSION="37.2.3"
TARBALL="electron-${VERSION}.tar.gz"
SPEC_FILE="electron.spec"
GIT_CACHE_PATH="${PWD}/.git_cache"
WORK_DIR="${PWD}/electron"
DEPOT_TOOLS_DIR="${HOME}/depot_tools"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64|znver1)
        CIPD_PLATFORM="linux-amd64"
        ;;
    aarch64|arm64)
        CIPD_PLATFORM="linux-arm64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

FRESH=false
if [[ "${1:-}" == "--fresh" ]]; then
FRESH=true
fi

if ! command -v gclient &> /dev/null; then
echo "depot_tools not found. Installing..."
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ${DEPOT_TOOLS_DIR}
#sudo dnf install depot_tools && setup-depot-tools
export PATH="${DEPOT_TOOLS_DIR}:${PATH}"
echo "Installed depot_tools at $DEPOT_TOOLS_DIR and added to PATH."
 else
 echo "depot_tools already available."
 fi

# Download CIPD client as a single file
curl -Lo ${DEPOT_TOOLS_DIR}/.cipd_client "https://chrome-infra-packages.appspot.com/client?platform=${CIPD_PLATFORM}"
chmod +x ${DEPOT_TOOLS_DIR}/.cipd_client

mkdir -p ${DEPOT_TOOLS_DIR}/.cipd_bin
ln -sf ${DEPOT_TOOLS_DIR}/.cipd_client ${DEPOT_TOOLS_DIR}/.cipd_bin/cipd

# Use a local CIPD cache directory inside depot_tools to store downloaded packages
export CIPD_CACHE_DIR="$PWD/depot_tools/.cipd_cache"
mkdir -p "$CIPD_CACHE_DIR"

export PATH="$PWD/depot_tools/.cipd_bin:$PWD/depot_tools:$PATH"
export PATH="${DEPOT_TOOLS_DIR}:${PATH}"
cd ${DEPOT_TOOLS_DIR}

# Bootstrap depot_tools with local CIPD cache
./update_depot_tools
./gclient

mkdir -p "${GIT_CACHE_PATH}"
export GIT_CACHE_PATH="${GIT_CACHE_PATH}"
if [[ "$FRESH" == true ]]; then
echo "Fresh sync requested. Removing existing cache and work dir."
rm -rf "${GIT_CACHE_PATH}"
rm -rf "${WORK_DIR}" "${TARBALL}"
mkdir -p "${GIT_CACHE_PATH}"
fi

mkdir "${WORK_DIR}"
cd "${WORK_DIR}"

echo "Syncing electron dependendies"
${DEPOT_TOOLS_DIR}/gclient config --name=src/electron --unmanaged "${REPO_URL}"
${DEPOT_TOOLS_DIR}/gclient sync --with_branch_heads --with_tags

echo "Fetching electron v${VERSION}"
cd src/electron
git fetch --tags
git checkout "v${VERSION}"

cd "${WORK_DIR}"

echo "Creating tarball: $TARBALL"
tar czf "$TARBALL" src/
mv "$TARBALL" ..

echo "Created tarball: $TARBALL"

if [[ -f "$SPEC_FILE" ]]; then
    sed -i "s/^%global electron_version .*/%global electron_version ${VERSION}/" "$SPEC_FILE"
    echo "Updated Version in $SPEC_FILE to: ${VERSION}"
else
    echo "$SPEC_FILE not found — skipped updating Version"
fi
