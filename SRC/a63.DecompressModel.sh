#!/bin/bash

set -a

# ==========================================================
# Decompress and pre-process all models to get:
#
# v.dat
# lon.dat
# lat.dat
# depth.dat
#
# Shule Yu
# Apr 11 2015
# ==========================================================

echo ""
echo "--> `basename $0` is running."
mkdir -p ${WORKDIR_Preprocess}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Preprocess}/INFILE

# ==================================================
#              ! Work Begin !
# ==================================================

while read MODEL_Preprocess
do
    mkdir -p ${WORKDIR_Preprocess}/${MODEL_Preprocess}
    cd ${WORKDIR_Preprocess}/${MODEL_Preprocess}
    trap "rm -rf ${WORKDIR_Preprocess}/${MODEL_Preprocess} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

	echo "    ==> Preprocessing ${MODEL_Preprocess} ..."

    # Model parameters.
    MODELname=${MODEL_Preprocess%_*}
    MODELcomp=${MODEL_Preprocess#*_}

    # Preprocess chosen tomography model.
    cp ${SRCDIR}/Models/${MODEL_Preprocess}/*nc ${WORKDIR_Preprocess}/${MODEL_Preprocess}
    cp ${SRCDIR}/Models/${MODEL_Preprocess}/preprocess* ${WORKDIR_Preprocess}/${MODEL_Preprocess}
    ${WORKDIR_Preprocess}/${MODEL_Preprocess}/preprocess.sh

    # Clean up.
    rm -f *nc preprocess* tmpfile*

done << EOF
S40RTS_S
GyPsum_S
HMSL-S06_S
S362ANI+M_S
S362ANI_S
S362WMANI_S
SAW24B16_S
SAW642ANb_S
SAW642AN_S
SEMum_S
TX2000_S
TX2011_S
EOF

cd ${WORKDIR}

exit 0
