#!/bin/true

# Assemble the correct FLAGS from set variables

[[ "$BUILD32" == true ]] && _PB_PGO_DIR="${PB_PGO_DIR}-32" || _PB_PGO_DIR="${PB_PGO_DIR}"

[[ "$tunePerformance" == true ]] && _CFLAGS="-march=haswell" || _CFLAGS="-march=haswell -mprefer-vector-width=128"
[[ "$tuneOptimize" == true ]] && _CFLAGS="${_CFLAGS} -O3" || _CFLAGS="${_CFLAGS} -Oz -ffunction-sections -fdata-sections"
[[ "$tuneOptimize" == true && "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -mllvm -polly"
_CFLAGS="${_CFLAGS} -pipe -D_FORTIFY_SOURCE=2 -fPIC -fomit-frame-pointer -Wall -Wno-error -Wp,-D_REENTRANT"
[[ "$tuneHarden" == true ]] && _CFLAGS="${_CFLAGS} -fstack-protector-strong -fstack-clash-protection -fpie --param ssp-buffer-size=4" || _CFLAGS="${_CFLAGS} -fstack-protector --param ssp-buffer-size=32"
[[ "$tuneLto" == true ]] && _CFLAGS="${_CFLAGS} -flto"
[[ "$tuneNoplt" == true && "$tuneBindnow" == true ]] && _CFLAGS="${_CFLAGS} -fno-plt"
[[ "$tuneMath" == true ]] && _CFLAGS="${_CFLAGS} -fno-math-errno -fno-trapping-math"
if [[ "$tuneSamplepgo" == true ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fno-profile-sample-accurate" || _CFLAGS="${_CFLAGS} -profile-partial-training"
fi
[[ "$buildDebug" == true ]] && _CFLAGS="${_CFLAGS} -g -feliminate-unused-debug-types"

# Add PGO flags if present
if [[ "$PGO_STEP" == "stage1" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-generate=${_PB_PGO_DIR}/IR" || _CFLAGS="${_CFLAGS} -fprofile-generate -fprofile-dir=${_PB_PGO_DIR}"
fi
if [[ "$PGO_STEP" == "stage2" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-use=${_PB_PGO_DIR}/ir.profdata -fcs-profile-generate=${_PB_PGO_DIR}/CS"
fi
if [[ "$PGO_STEP" == "build" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-use=${_PB_PGO_DIR}/combined.profdata" || _CFLAGS="${_CFLAGS} -fprofile-use -fprofile-dir=${_PB_PGO_DIR} -fprofile-correction"
fi
_CXXFLAGS="$_CFLAGS"
_FCFLAGS="$_CFLAGS"
_FFFLAGS="$_CFLAGS"
_CFLAGS="$_CFLAGS -Wformat -Wformat-security"

# pic/pie/lto should be part of _LDFLAGS
_LDFLAGS="-Wl,-O2,-z,max-page-size=0x1000,--sort-common"
[[ "$tuneBindnow" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,-z,relro,-z,now"
[[ "$tuneAsneeded" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,--as-needed"
[[ "$tuneSymbolic" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,-Bsymbolic-functions"
[[ "$tuneLdclean" == true && "$buildClang" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,--gc-sections,--icf=safe"
[[ "$tuneRunpath" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,--enable-new-dtags"

if [[ "$BUILD32" == true ]]; then
    [[ "$buildClang" == true ]] && _CC="clang -m32" || _CC="gcc -m32"
    [[ "$buildClang" == true ]] && _CXX="clang++ -m32" || _CXX="g++ -m32"
else
    [[ "$buildClang" == true ]] && _CC=clang || _CC=gcc
    [[ "$buildClang" == true ]] && _CXX=clang++ || _CXX=g++
fi
[[ "$buildClang" == true ]] && _AR=llvm-ar || _AR=gcc-ar
[[ "$buildClang" == true ]] && _NM=llvm-nm || _NM=gcc-nm
[[ "$buildClang" == true ]] && _RANLIB=llvm-ranlib || _RANLIB=gcc-ranlib

echo ${_CFLAGS}
echo ${_LDFLAGS}
