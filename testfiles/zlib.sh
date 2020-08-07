#!/bin/true

export ymlName=zlib
export ymlVersion=1.2.11
export ymlRelease=1
export ymlLicense=ZLIB
export ymlSources=( "https://github.com/madler/zlib/archive/v1.2.11.tar.gz" )
export ymlSha256sums=( "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff" )
export ymlSummary="Zlib package"
export ymlDescription="zlib is a general purpose data compression library. All the code is thread safe."

export build32bit=true
export buildClang=true

export tuneLto=true

export stepEnvironment="echo 'Environment working'"
export stepSetup="$cmdConfigure_min"
export stepBuild="$cmdMake"
export stepProfile="$cmdMake check"
export stepInstall="$cmdMake_install"
