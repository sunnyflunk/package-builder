#!/usr/bin/env -S bash --norc --noprofile

executionPath=$(dirname $(realpath -s $0))
PB_BUILD_DIR=/tmp/pb/${1}

# Import used functions, dir variables, yml defaults and the building package
. ${executionPath}/common/functions.sh
. ${executionPath}/common/variables.sh
. ${executionPath}/common/macros.sh
. ${executionPath}/common/defaults-yml.sh
. ${PB_TESTFILES_DIR}/${1}.sh

# Layout execution steps and flags
. ${executionPath}/common/setup-build.sh

# Apply patches (if series file)



[[ ! -z $stepProfile ]] && PGO_STEP=stage1
. ${executionPath}/common/flags.sh

# Run steps of build
setupStep setup
executeStep $stepSetup

setupStep build
executeStep $stepBuild

if [[ ! -z $stepProfile ]]; then
    setupStep profile
    executeStep $stepProfile

    if [[ "$buildClang" == true ]]; then
        PGO_STEP=stage2
        . ${executionPath}/common/flags.sh

        # Merge PGO info
        llvm-profdata merge -output=${PB_PGO_DIR}/ir.profdata ${PB_PGO_DIR}/IR/default*.profraw

        setupStep setup
        executeStep $stepSetup

        setupStep build
        executeStep $stepBuild

        setupStep profile
        executeStep $stepProfile

        # Merge PGO info
        llvm-profdata merge -output=${PB_PGO_DIR}/combined.profdata ${PB_PGO_DIR}/ir.profdata ${PB_PGO_DIR}/CS/default*.profraw
    fi

    PGO_STEP=build
    . ${executionPath}/common/flags.sh
    setupStep setup
    executeStep $stepSetup

    setupStep build
    executeStep $stepBuild
fi

setupStep install
executeStep $stepInstall
