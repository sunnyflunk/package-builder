#!/bin/true

# Setup build directories
echo "${PB_BUILD_DIR}"
rm -rf "${PB_BUILD_DIR}" || serpentFail "Failed to clean previous build directory"
mkdir -p "${PB_BUILD_DIR}" || serpentFail "Failed to create build directory"
mkdir -p "${PB_WORKDIR}" || serpentFail "Failed to create workdir directory"
mkdir -p "${PB_INSTALLDIR}" || serpentFail "Failed to create installdir directory"
mkdir -p "${PB_PGO_DIR}" || serpentFail "Failed to create pgo directory"
mkdir -p "${PB_PGO_DIR}-32" || serpentFail "Failed to create pgo-32 directory"

# PM fetch and install dependencies

# Fetch sources
for source in ${!ymlSources[@]}; do
    downloadSource ${ymlSources[$source]} ${ymlSha256sums[$source]}
done
