#!/bin/true

# Common macros used in buildfiles

cmdConfigure="./configure --datadir=/usr/share --infodir=/usr/share/info --libdir=${_LIBDIR} --localstatedir=/var --mandir=/usr/share/man --prefix=/usr --sysconfdir=/etc"
cmdConfigure_min="./configure --libdir=${_LIBDIR} --prefix=/usr --sysconfdir=/etc"
cmdMake="make -j${SERPENT_BUILD_JOBS}"
cmdMake_install="make -j${SERPENT_BUILD_JOBS} install DESTDIR=$PB_INSTALLDIR"
