# Package-Variables

This lists all of the variables one can use in the packaging format.

## Package variables

| Variable       | What it does                             | Default value    |
| :------------- | :--------------------------------------- | ---------------: |
| ymlName        | Sets package name                        |                  |
| ymlVersion     | Sets package version                     |                  |
| ymlRelease     | Sets package release                     |                  |
| ymlLicense     | Sets package licenses                    |                  |
| ymlSummary     | Sets package summary                     |                  |
| ymlDescription | Sets package description                 |                  |
| ymlSources     | Package sources to download for build    |                  |
| ymlSha256sums  | Validation sums of sources               |                  |

## Build variables

| Variable        | What it does                             | Default value    |
| :-------------- | :--------------------------------------- | ---------------: |
| build32bit      | Adds 32bit build                         | false            |
| buildClang      | Uses Clang compiler                      | true             |
| buildPgo2       | Enables 2 stage PGO with clang           | true             |
| buildDebug      | Add debug flags to build                 | false            |
| buildStrip      | Strips binary files at end of build      | true             |
| buildCcache     | Enables ccache in build                  | false            |
| buildNetworking | Enables networking during build process  | false            |

## Tuning variables

| Variable        | What it does                                       | Default value          |
| :-------------- | :------------------------------------------------- | ---------------------: |
| tunePerformance | Unsets `-mprefer-vector-width=128`                 | false                  |
| tuneOptimize    | Tunes for performance (otherwise size)             | true                   |
| tunePolly       | Adds `-mllvm -polly` to flags                      | true (with Clang)      |
| tuneAsneeded    | Adds `-Wl,--as-needed` to LDFLAGS                  | true                   |
| tuneBindnow     | Adds `-Wl,-z,relro,-z,now` to LDFLAGS              | true                   |
| tuneSymbolic    | Adds `-Wl,-Bsymbolic-functions` to LDFLAGS         | true                   |
| tuneRunpath     | Adds `-Wl,--enable-new-dtags` to LDFLAGS           | false                  |
| tuneIcf         | Adds `-Wl,--icf=safe` to LDFLAGS                   | true (with Clang)      |
| tuneLto         | Enables LTO build                                  | false                  |
| tuneLtoextra    | Adds extra FLAGS to help with LTO performance      | true (with Lto)        |
| tuneCommon      | Adds `-fcommon` to FLAGS                           | false                  |
| tuneNoplt       | Adds `-fno-plt` to FLAGS                           | true (with Bindnow)    |
| tuneMath        | Adds `-fno-math-errno -fno-trapping-math` to FLAGS | false                  |
| tuneHardened    | Uses stricter security flags in build              | false                  |
| tuneSamplepgo   | Forces optimization on unsampled code              | false                  |

## Build steps

| Variable        | What it does                             | Default value    |
| :-------------- | :--------------------------------------- | ---------------: |
| stepEnvironment | Instructions to add to all other steps   |                  |
| stepSetup       | Instructions for the Setup step          |                  |
| stepBuild       | Instructions for the Build step          |                  |
| stepInstall     | Instructions for the Install step        |                  |
| stepCheck       | Instructions for the Check step          |                  |
| stepProfile     | Steps to generate profiling data         |                  |
