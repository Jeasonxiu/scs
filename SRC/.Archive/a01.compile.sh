#!/bin/bash

# ==============================================================
# This script compile the C codes for this projects.
#
# Shule Yu
# Jun 22 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running."
mkdir -p ${EXECDIR}
cd ${EXECDIR}
cp ${WORKDIR}/INFILE .
trap "rm ${EXECDIR}/*.o ${WORKDIR}/*_${RunNumber} 2>/dev/null; exit 1" SIGINT

# ===================================
#     ! Inclusions and Libraries!
# ===================================

echo "    ==> Compiling C codes ..."
INCLUDEDIR="-I${CCODEDIR} -I${SRCDIR} -I${SACDIR}/include"
LIBRARYDIR="-L. -L${SACDIR}/lib -L/opt/local/lib"
# Note the order of the libraries:
# If libA.a depends on libB.a, then -lA should appears before -lB.
LIBRARIES="-lt041 -lASU_tools -lsac -lsacio -lfftw3 -lm"

# ==============================
#     ! ASU Functions !
# ==============================
${CCODEDIR}/compile.sh
rm *fun.o 2>/dev/null

# ==============================
#     ! Project Functions !
# ==============================
gcc -c ${SRCDIR}/*.fun.c ${INCLUDEDIR}
ar cr libt041.a *.o

# ==============================
#     ! Executables !
# ==============================
error_flag=0
while read code
do
    gcc -o ${code}.out ${SRCDIR}/${code}.c ${INCLUDEDIR} ${LIBRARYDIR} ${LIBRARIES}

    if [ $? -ne 0 ]
    then
        echo "=============================================="
        echo "${code} C code is not compiled ..."
        echo "=============================================="
        error_flag=1
    fi

done << EOF
theo
scs_sampling
radpat
shift
esf
category
stretch
decon
weight
frs
makebins
frstack
bootstrap
dataset
circle
seis2xy
seis2xy_p
seis2xy_pp
syn_frstack
syn_compare
freq
deconesf
game
datagame
structure
structure_sectionEHV
structure_sectionHVRF
structure_sectionELV
structure_sectionLVRF
radiation
angle
EOF

# Clean up.
rm *fun.o 2>/dev/null

cd ${CODEDIR}

# Exit error flag.
exit ${error_flag}
