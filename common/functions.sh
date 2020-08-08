#!/bin/true

# Common functionality between all scripts


# Emit a warning to tty
function printWarning()
{
    echo -en '\e[1m\e[93m[WARNING]\e[0m '
    echo -e $*
}

# Emit an error to tty
function printError()
{
    echo -en '\e[1m\e[91m[ERROR]\e[0m '
    echo -e $*
}

# Emit info to tty
function printInfo()
{
    echo -en '\e[1m\e[94m[INFO]\e[0m '
    echo -e $*
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

    if [ "${computeHash}" != "${sourceHash}" ]; then
        rm -v "${sourcePath}"
        serpentFail "Corrupt download: ${sourcePath}\nExpected: ${sourceHash}\nFound: ${computeHash}"
    fi
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
        verifyDownload "${1}" "${2}"
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

function freshBuildEnvironment()
{
    . ${executionPath}/common/flags.sh
    rm -rf "${PB_WORKDIR}"/* || serpentFail "Failed to clean workdir directory"
    pushd ${PB_WORKDIR}
        extractSource ${PB_SOURCES_DIR}/`basename ${ymlSources[0]}`
    popd
    . ${executionPath}/common/macros.sh
    . ${executionPath}/testfiles/${ymlName}.sh
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
    export CFLAGS=${_CFLAGS}
    export CXXFLAGS=${_CXXFLAGS}
    export LDFLAGS=${_LDFLAGS}
    export FFLAGS=${_FFFLAGS}
    export FCFLAGS=${_FCFLAGS}
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    export workdir=$(pwd)
    export package=$ymlName
    export release=$ymlRelease
    export version=$ymlVersion
    export sources=$PB_SOURCES_DIR
    export pkgfiles=
    export installdir=$PB_INSTALLDIR
    export libdir=${_LIBDIR}
    # For autotools
    export LT_SYS_LIBRARY_PATH=${_LIBDIR}
    export CC="${_CC}"
    export CXX="${_CXX}"
    export AR="${_AR}"
    export NM="${_NM}"
    export RANLIB="${_RANLIB}"
    export TERM=dumb
    export SOURCE_DATA_EPOCH=

    eval "${stepEnvironment[@]}"
}


function executeStep()
{
    echo "${@}"
    eval "${@}"
}

function debugAndstrip()
{
    elfFILES=$(find -type f -exec file {} \; | grep -i elf | cut -d: -f1)
    for elf in $elfFILES; do
        if [[ "$buildDebug" == true ]]; then
            ${_OBJCOPY} --compress-debug-sections=zlib --only-keep-debug ${elf} ${elf}.debug
            ${_OBJCOPY} --add-gnu-debuglink=${elf}.debug ${elf}
            [[ -d ${PB_INSTALLDIR}/usr/lib/debug/$(dirname ${elf}.debug) ]] || mkdir -p ${PB_INSTALLDIR}/usr/lib/debug/$(dirname ${elf}.debug)
            mv ${elf}.debug ${PB_INSTALLDIR}/usr/lib/debug/${elf}.debug
        fi

        if [[ "$buildStrip" == true ]]; then
            ${_STRIP} -S --strip-unneeded --remove-section=.comment $elf
        fi
    done
}

function splitPkgs()
{
    find -type f,l -wholename *lib*/lib*.a | grep -v /lib32/ | sed 's|^./||' >> pkg-dev
    find -type l -wholename *lib*/lib*.so | grep -v /lib32/ | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */pkgconfig/*.pc | grep -v /lib32/ | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/include/* | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/share/aclocal* | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename *cmake/* | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/share/vala*/vapi/* | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/share/qt5/mkspecs/modules/*.pri | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/lib64/*.prl | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/share/doc/qt5/*.qch | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/share/doc/qt5/*.tags | sed 's|^./||' >> pkg-dev
    find -type f,l -wholename */usr/lib32/lib*.so.* | grep -v [.]debug$ | sed 's|^./||' >> pkg-32
    find -type f,l -wholename */usr/lib32/lib*.a | grep -v [.]debug$ | sed 's|^./||' >> pkg-32
    find -type l -wholename */usr/lib32/lib*.so | sed 's|^./||' >> pkg-dev32
    find -type f,l -wholename */usr/lib32/cmake/* | sed 's|^./||' >> pkg-dev32
    find -type f,l -wholename */usr/lib32/pkgconfig/*.pc | sed 's|^./||' >> pkg-dev32
    find -type f -name *.debug | grep -v /lib32/ | sed 's|^./||' >> pkg-dbg
    find -type f,l -wholename */usr/lib32/* -name *.debug  | sed 's|^./||' >> pkg-dbg32
}

function makePkg()
{
    pkgSuffix=$1
    if [[ ! -d ${ymlName}${pkgSuffix} ]]; then
        mkdir -p ${ymlName}${pkgSuffix}
        for file in $(cat pkg${pkgSuffix}); do
            [[ -d ${ymlName}${pkgSuffix}/$(dirname $file) ]] || mkdir -p ${ymlName}${pkgSuffix}/$(dirname $file)
            mv $file ${ymlName}${pkgSuffix}/$(dirname $file)/
        done
    fi
    pushd ${ymlName}${pkgSuffix}
        find -type f,l | grep -v files.yml$ | sed 's|^./||' | xargs sha256sum > files.yml
        echo "Name: $ymlName${pkgSuffix}" > metadata.yml
        echo "Version: $ymlVersion" >> metadata.yml
        echo "Release: $ymlRelease" >> metadata.yml
        echo "License: $ymlLicense" >> metadata.yml
        echo "Summary: $ymlSummary" >> metadata.yml
        echo "Description: $ymlDescription" >> metadata.yml
        find -empty -type d -delete
        tar --zstd -cf ../${ymlName}${pkgSuffix}-${ymlVersion}-${ymlRelease}.tar.zst *
    popd
    [[ -f pkg${pkgSuffix} ]] && rm pkg${pkgSuffix}
}

function validateBuildfile()
{
    [[ -z $ymlName ]] && serpentFail "ymlName not set in build file"
    [[ -z $ymlVersion ]] && serpentFail "ymlVersion not set in build file"
    [[ -z $ymlRelease ]] && serpentFail "ymlRelease not set in build file"
    [[ -z $ymlLicense ]] && serpentFail "ymlLicense not set in build file"
    [[ -z $ymlSources ]] && serpentFail "ymlSources not set in build file"
    [[ -z $ymlSha256sums ]] && serpentFail "ymlSha256sums not set in build file"
    [[ -z $ymlSummary ]] && serpentFail "ymlSummary not set in build file"
    [[ -z $ymlDescription ]] && serpentFail "ymlDescription not set in build file"
}
