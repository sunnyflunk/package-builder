#!/bin/true

ymlName=zlib
ymlVersion=1.2.11
ymlRelease=1
ymlLicense=ZLIB
ymlSources=( "https://github.com/madler/zlib/archive/v1.2.11.tar.gz" )
ymlSha256sums=( "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff" )
ymlSummary="Zlib package"
ymlDescription="zlib is a general purpose data compression library. All the code is thread safe."

build32bit=true
buildClang=true

tuneLto=true

stepEnvironment="echo 'Environment working'"
stepSetup="$cmdConfigure_min"
stepBuild="$cmdMake"
stepProfile="$cmdMake check"
stepInstall="$cmdMake_install"
