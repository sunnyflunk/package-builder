#!/bin/true

# Common macros used in buildfiles

configOptions="
        --datadir=/usr/share \
        --infodir=/usr/share/info \
        --libdir=${libdir} \
        --localstatedir=/var
        --mandir=/usr/share/man \
        --prefix=/usr \
        --sysconfdir=/etc
"

function configure()
{
    ./configure $configOptions AR=${AR} NM=${NM} RANLIB=${RANLIB}

}
