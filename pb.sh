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
. ${executionPath}/common/flags.sh

# Apply patches (if series file)



# Run steps of build
setupStep setup
executeStep $stepSetup

setupStep build
executeStep $stepBuild

setupStep install
executeStep $stepInstall
