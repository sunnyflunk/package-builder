#!/bin/true

SERPENT_BUILD_JOBS=$(nproc)
SERPENT_ARCH="x86_64"
SERPENT_TRIPLET="x86_64-serpent-linux-musl"

build32bit=false
buildClang=true
buildPgo2=true
buildDebug=true
buildStrip=true
buildCcache=false
buildNetworking=false

tunePerformance=false
tuneOptimize=true
tunePolly=true
tuneAsneeded=true
tuneBindnow=true
tuneSymbolic=true
tuneRunpath=false
tuneIcf=true
tuneLto=false
tuneLtoextra=true
tuneCommon=false
tuneNoplt=true
tuneMath=false
tuneHardened=false
tuneSamplepgo=false
