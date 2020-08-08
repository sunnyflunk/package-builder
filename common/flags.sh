#!/bin/true

# Assemble the correct FLAGS from set variables

[[ "$BUILD32" == true ]] && _PB_PGO_DIR="${PB_PGO_DIR}-32" || _PB_PGO_DIR="${PB_PGO_DIR}"
[[ "$BUILD32" == true ]] && _LIBDIR=/usr/lib32 || _LIBDIR=/usr/lib64

[[ "$tunePerformance" == true ]] && _CFLAGS="-march=haswell" || _CFLAGS="-march=haswell -mprefer-vector-width=128"
[[ "$tuneOptimize" == true ]] && _CFLAGS="${_CFLAGS} -O3" || _CFLAGS="${_CFLAGS} -Oz -ffunction-sections -fdata-sections"
[[ "$tunePolly" == true && "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -mllvm -polly"
_CFLAGS="${_CFLAGS} -pipe -D_FORTIFY_SOURCE=2 -fPIC -fomit-frame-pointer -Wall -Wno-error -Wp,-D_REENTRANT"
[[ "$tuneHarden" == true ]] && _CFLAGS="${_CFLAGS} -fstack-protector-strong -fstack-clash-protection -fpie --param ssp-buffer-size=4" || _CFLAGS="${_CFLAGS} -fstack-protector --param ssp-buffer-size=32"
[[ "$tuneLto" == true ]] && _CFLAGS="${_CFLAGS} -flto"
if [[ "$tuneLto" == true && "$tuneLtoextra" == true ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fwhole-program-vtables -fvirtual-function-elimination" || _CFLAGS="${_CFLAGS} -fdevirtualize-at-ltrans -fno-semantic-interposition"
fi
[[ "$tuneNoplt" == true && "$tuneBindnow" == true ]] && _CFLAGS="${_CFLAGS} -fno-plt"
[[ "$tuneMath" == true ]] && _CFLAGS="${_CFLAGS} -fno-math-errno -fno-trapping-math"
[[ "$tuneCommon" == true ]] && _CFLAGS="${_CFLAGS} -fcommon" || _CFLAGS="${_CFLAGS} -fno-common"
if [[ "$tuneSamplepgo" == true ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fno-profile-sample-accurate" || _CFLAGS="${_CFLAGS} -profile-partial-training"
fi
[[ "$buildDebug" == true ]] && _CFLAGS="${_CFLAGS} -g -feliminate-unused-debug-types"

# Add PGO flags if present
if [[ "$BUILD_STAGE" == "stage1" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-generate=${_PB_PGO_DIR}/IR" || _CFLAGS="${_CFLAGS} -fprofile-generate -fprofile-dir=${_PB_PGO_DIR}"
fi
if [[ "$BUILD_STAGE" == "stage2" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-use=${_PB_PGO_DIR}/ir.profdata -fcs-profile-generate=${_PB_PGO_DIR}/CS"
fi
if [[ "$BUILD_STAGE" == "final" ]]; then
    [[ "$buildClang" == true ]] && _CFLAGS="${_CFLAGS} -fprofile-use=${_PB_PGO_DIR}/combined.profdata" || _CFLAGS="${_CFLAGS} -fprofile-use -fprofile-dir=${_PB_PGO_DIR} -fprofile-correction"
fi
_CXXFLAGS="$_CFLAGS"
_FCFLAGS="$_CFLAGS"
_FFFLAGS="$_CFLAGS"
_CFLAGS="$_CFLAGS -Wformat -Wformat-security"

# pic/pie/lto should be part of _LDFLAGS
_LDFLAGS="-Wl,-O2,-z,max-page-size=0x1000,--sort-common,--gc-sections"
[[ "$tuneBindnow" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,-z,relro,-z,now"
[[ "$tuneAsneeded" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,--as-needed"
[[ "$tuneSymbolic" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,-Bsymbolic-functions"
[[ "$tuneIcf" == true && "$buildClang" == true ]] && _LDFLAGS="${_LDFLAGS} -Wl,--icf=safe"
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
[[ "$buildClang" == true ]] && _STRIP=llvm-strip || _STRIP=strip
[[ "$buildClang" == true ]] && _OBJCOPY=llvm-objcopy || _OBJCOPY=objcopy

echo ${_CFLAGS}
echo ${_LDFLAGS}
