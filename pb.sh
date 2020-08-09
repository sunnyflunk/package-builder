#!/usr/bin/env -S bash --norc --noprofile

executionPath=$(dirname $(realpath -s $0))
PB_BUILD_DIR=/tmp/pb/${1}

# Import used functions, dir variables, yml defaults and the building package
. ${executionPath}/common/functions.sh
. ${executionPath}/common/variables.sh
. ${executionPath}/common/macros.sh
. ${executionPath}/configs/${2}.sh || serpentFail "Config ${2} is not a valid profile"
. ${PB_TESTFILES_DIR}/${1}.sh
validateBuildfile

# Layout execution steps and flags
. ${executionPath}/common/setup-build.sh

# Apply patches (if series file)


if [[ "$build32bit" == true ]]; then
    printInfo "Starting 32bit Build"
    BUILD32=true
    buildProcess || serpentFail "Failed to build 32bit version"
    unset BUILD32
fi
printInfo "Starting 64bit Build"
buildProcess

[[ "$(ls -A ${PB_INSTALLDIR})" ]] || serpentFail "No files installed to ${PB_INSTALLDIR}"
printInfo "Examine and create the packages"
pushd "${PB_INSTALLDIR}"
    debugAndstrip

    abireport scan-tree .
    cp ${PB_TESTFILES_DIR}/${1}.sh .

    splitPkgs
popd

[[ ! -z $stepProfile ]] && printInfo "PGO dir is $(du -sh ${_PB_PGO_DIR} | cut -f1)"
