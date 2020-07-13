#!/bin/true

# Setup build directories
echo "${PB_BUILD_DIR}"
rm -rf "${PB_BUILD_DIR}" || serpentFail "Failed to clean previous build directory"
mkdir -p "${PB_BUILD_DIR}" || serpentFail "Failed to create build directory"
mkdir -p "${PB_WORKDIR}" || serpentFail "Failed to create workdir directory"

# Fetch sources
for source in ${!ymlSources[@]}; do
    downloadSource ${ymlSources[$source]} ${ymlSha256sums[$source]}
done

# Extract source
pushd ${PB_WORKDIR}
    extractSource ${PB_SOURCES_DIR}/`basename ${ymlSources[0]}`
popd
