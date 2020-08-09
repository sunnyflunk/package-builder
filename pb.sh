#!/usr/bin/env -S bash --norc --noprofile

executionPath=$(dirname $(realpath -s $0))
PB_BUILD_DIR=/tmp/pb/${1}

# Import used functions, dir variables, yml defaults and the building package
. ${executionPath}/common/functions.sh
. ${executionPath}/common/variables.sh
. ${executionPath}/common/macros.sh
. ${executionPath}/configs/${2}.sh
. ${PB_TESTFILES_DIR}/${1}.sh
validateBuildfile

# Layout execution steps and flags
. ${executionPath}/common/setup-build.sh

# Apply patches (if series file)


function buildProcess()
{
    # Run steps of build
    if [[ ! -z $stepProfile ]]; then
        BUILD_STAGE=stage1
        freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"

        [[ ! -z $stepSetup ]] && setupStep setup-$BUILD_STAGE
        [[ ! -z $stepSetup ]] && executeStep $stepSetup

        [[ ! -z $stepBuild ]] && setupStep build-$BUILD_STAGE
        [[ ! -z $stepBuild ]] && executeStep $stepBuild

        setupStep profile-$BUILD_STAGE
        executeStep $stepProfile

        # Merge PGO info
        if [[ "$buildPgo2" == true ]]; then
            llvm-profdata merge -output=${_PB_PGO_DIR}/ir.profdata ${_PB_PGO_DIR}/IR/default*.profraw
        else
            llvm-profdata merge -output=${_PB_PGO_DIR}/combined.profdata ${_PB_PGO_DIR}/IR/default*.profraw
        fi

        if [[ "$buildClang" == true && "$buildPgo2" == true ]]; then
            BUILD_STAGE=stage2
            freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"

            [[ ! -z $stepSetup ]] && setupStep setup-$BUILD_STAGE
            [[ ! -z $stepSetup ]] && executeStep $stepSetup

            [[ ! -z $stepBuild ]] && setupStep build-$BUILD_STAGE
            [[ ! -z $stepBuild ]] && executeStep $stepBuild

            setupStep profile-$BUILD_STAGE
            executeStep $stepProfile

            # Merge PGO info
            llvm-profdata merge -output=${_PB_PGO_DIR}/combined.profdata ${_PB_PGO_DIR}/ir.profdata ${_PB_PGO_DIR}/CS/default*.profraw
        fi
    fi
    freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"
    BUILD_STAGE=final

    [[ ! -z $stepSetup ]] && setupStep setup-$BUILD_STAGE
    [[ ! -z $stepSetup ]] && executeStep $stepSetup

    [[ ! -z $stepBuild ]] && setupStep build-$BUILD_STAGE
    [[ ! -z $stepBuild ]] && executeStep $stepBuild

    [[ ! -z $stepInstall ]] && setupStep install-$BUILD_STAGE
    [[ ! -z $stepInstall ]] && executeStep $stepInstall

    if [[ ! -z $stepCheck ]]; then
        setupStep check
        executeStep $stepCheck
    fi
}


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

    [[ -f pkg-dev ]] && makePkg -dev
    [[ -f pkg-32 ]] && makePkg -32
    [[ -f pkg-dev32 ]] && makePkg -dev32
    [[ -f pkg-dbg ]] && makePkg -dbg
    [[ -f pkg-dbg32 ]] && makePkg -dbg32
    mkdir ${ymlName}; mv usr ${ymlName}/
    [[ -d ${ymlName}/usr ]] && makePkg
popd

[[ ! -z $stepProfile ]] && printInfo "PGO dir is $(du -sh ${_PB_PGO_DIR} | cut -f1)"
