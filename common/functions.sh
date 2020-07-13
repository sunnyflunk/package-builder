#!/bin/true

# Common functionality between all scripts


# Emit a warning to tty
function printWarning()
{
    echo -en '\e[1m\e[93m[WARNING]\e[0m '
    echo $*
}

# Emit an error to tty
function printError()
{
    echo -en '\e[1m\e[91m[ERROR]\e[0m '
    echo $*
}

# Emit info to tty
function printInfo()
{
    echo -en '\e[1m\e[94m[INFO]\e[0m '
    echo $*
}

# Failed to do a thing. Exit fatally.
function serpentFail()
{
    printError $*
    exit 1
}

# Verify the download is correct
function verifyDownload()
{
    sourceURL="${1}"
    sourceHash="${2}"
    [ ! -z "${sourceURL}" ] || serpentFail "Missing URL for source: $1"
    [ ! -z "${sourceHash}" ] || serpentFail "Missing hash for source: $1"
    sourcePathBase=$(basename "${sourceURL}")
    sourcePath="${PB_SOURCES_DIR}/${sourcePathBase}"

    printInfo "Computing hash for ${sourcePathBase}"

    computeHash=$(sha256sum "${sourcePath}" | cut -d ' ' -f 1)
    [ $? -eq 0 ] || serpentFail "Failed to compute SHA256sum"

    [ "${computeHash}" == "${sourceHash}" ] || serpentFail "Corrupt download: ${sourcePath}"
}

# Download a file from sources/
function downloadSource()
{
    sourceURL="${1}"
    sourceHash="${2}"
    [ ! -z "${sourceURL}" ] || serpentFail "Missing URL for source: $1"
    [ ! -z "${sourceHash}" ] || serpentFail "Missing hash for source: $1"
    sourcePathBase=$(basename "${sourceURL}")
    sourcePath="${PB_SOURCES_DIR}/${sourcePathBase}"

    mkdir -p "${PB_SOURCES_DIR}" || serpentFail "Failed to create download tree"

    if [[ -f "${sourcePath}" ]]; then
        printInfo "Skipping download of ${sourcePathBase}"
        return
    fi

    printInfo "Downloading ${sourcePathBase}"
    curl -L --output "${sourcePath}" "${sourceURL}"
    verifyDownload "${1}" "${2}"
}

# Extract a tarball into the current working directory
function extractSource()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of extractSource"
    printInfo "Extracting ${sourcePathBase}"

    tar xf "${1}" -C . || serpentFail "Failed to extract ${1}"
}

# Setup step with required environment variables
function setupStep()
{
    [ ! -z "${1}" ] || serpentFail "Incorrect use of executeStep"
    printInfo "Begin step: ${1}"

    cd "${PB_WORKDIR}"
    tmpFiles=$(ls | tr ' ' '/n' | wc -l)
    [ ${tmpFiles} == 1 ] && cd $(ls)

    # Setup flag creations
    export CFLAGS=
    export CXXFLAGS=
    export LDFLAGS=
    export FFLAGS=
    export FCFLAGS=
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    export workdir=
    export package=$ymlName
    export release=$ymlRelease
    export version=$ymlVersion
    export sources=$PB_SOURCES_DIR
    export pkgfiles=
    export installdir=$PB_INSTALLDIR
    # For autotools
    export LT_SYS_LIBRARY_PATH=/usr/lib64
    export CC=gcc
    export CXX=g++
    export TERM=dumb
    export SOURCE_DATA_EPOCH=

    eval "${stepEnvironment}"
}


function executeStep()
{
    echo "${@}"
    eval "${@}"
}
