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


function buildProcess()
{
    [[ ! -z $stepProfile ]] && PGO_STEP=stage1
    freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"

    # Run steps of build
    setupStep setup
    executeStep $stepSetup

    setupStep build
    executeStep $stepBuild

    if [[ ! -z $stepProfile ]]; then
        setupStep profile-$PGO_STEP
        executeStep $stepProfile

        if [[ "$buildClang" == true ]]; then
            PGO_STEP=stage2
            freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"

            # Merge PGO info
            llvm-profdata merge -output=${_PB_PGO_DIR}/ir.profdata ${_PB_PGO_DIR}/IR/default*.profraw

            setupStep setup
            executeStep $stepSetup

            setupStep build
            executeStep $stepBuild

            setupStep profile-$PGO_STEP
            executeStep $stepProfile

            # Merge PGO info
            llvm-profdata merge -output=${_PB_PGO_DIR}/combined.profdata ${_PB_PGO_DIR}/ir.profdata ${_PB_PGO_DIR}/CS/default*.profraw
        fi

        PGO_STEP=build
        freshBuildEnvironment || serpentFail "Failed to setup clean workdir environment"

        setupStep setup
        executeStep $stepSetup

        setupStep build
        executeStep $stepBuild
    fi

    setupStep install
    executeStep $stepInstall
}


if [[ "$build32bit" == true ]]; then
    printInfo "Starting 32bit Build"
    BUILD32=true
    buildProcess || serpentFail "Failed to build 32bit version"
    unset BUILD32
fi
printInfo "Starting 64bit Build"
buildProcess

printInfo "Examine and create the packages"
pushd "${PB_INSTALLDIR}"
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

    abireport scan-tree .
    cp ${PB_TESTFILES_DIR}/${1}.sh .

    makePkg()
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
            tar --zstd -cf ../${ymlName}${pkgSuffix}-${ymlVersion}-${ymlRelease}.tar.zst *
        popd
        [[ -f pkg${pkgSuffix} ]] && rm pkg${pkgSuffix}
    }

    [[ -f pkg-dev ]] && makePkg -dev
    [[ -f pkg-32 ]] && makePkg -32
    [[ -f pkg-dev32 ]] && makePkg -dev32
    [[ -f pkg-dbg ]] && makePkg -dbg
    [[ -f pkg-dbg32 ]] && makePkg -dbg32
    mkdir ${ymlName}; mv usr ${ymlName}/
    makePkg
popd

[[ ! -z $stepProfile ]] && printInfo "PGO dir is $(du -sh ${_PB_PGO_DIR} | cut -f1)"
