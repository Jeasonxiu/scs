#!/bin/bash

#==============================================================
# This script chop each de-convolved ScS at their peak and do
# Flip-Reverse-Sum ( FRS ) operation.
#
# Outputs:
#
#           ${WORKDIR_FRS}/${EQ}_${STNM}.frs
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Check info result.
if ! [ -e ${WORKDIR_FRS}/INFO_All ] || [ `wc -l < ${WORKDIR_FRS}/INFO_All` -le 1 ]
then
    echo "    !=> `basename $0`: no traces in INFO_All ..."
    exit 1
fi

echo "    ==> Flipping ..."
cd ${WORKDIR_FRS}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_FRS}/INFILE
trap "rm -f ${WORKDIR_FRS}/tmpfile* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# ==================================================
#       ! Flip-Reverse-Sum !
# ==================================================

# C code I/O.
keys="<EQ> <STNM>"
${BASHCODEDIR}/Findfield.sh INFO_All "${keys}" > tmpfile_$$

rm -f tmpfile_Cinfile
while read EQ STNM
do
    echo "${WORKDIR_Decon}/${EQ}/${STNM}.trace ${EQ}_${STNM}.frs" >> tmpfile_Cinfile
done < tmpfile_$$

# C code.
${EXECDIR}/NOFRS.out 0 1 2 << EOF
tmpfile_Cinfile
${Time}
${DELTA}
EOF

if [ $? -ne 0 ]
then
    echo "    !=> FRS C code failed ..."
    rm -f ${WORKDIR_FRS}/*
    exit 1;
fi

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
