#!/bin/bash

#==============================================================
# This script do bootstrap test on each bins.
#
# Outputs:
#
#           ${WORKDIR_BootStrap}/${binN}.bootstrap
#           ${WORKDIR_BootStrap}/${BinN}.bootSig_low
#           ${WORKDIR_BootStrap}/${BinN}.bootSig_high
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Check bin stack result.
if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> `basename $0`: no bin stack result in ${WORKDIR_Geo} ..."
    exit 1
fi

rm -rf ${WORKDIR_BootStrap}
mkdir -p ${WORKDIR_BootStrap}
cd ${WORKDIR_BootStrap}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_BootStrap}/INFILE
trap "rm -f ${WORKDIR_BootStrap}/* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.

echo "    ==> Bootstrap testing through Bins."

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    # C code I/O.

    keys="<EQ> <STNM> <Weight_Smooth>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | awk -v D=${WORKDIR_FRS} '{ print D"/"$1"_"$2".frs",$3}' > tmpfile_Cin

    # C code.
    ${EXECDIR}/BootStrap.out 4 4 2 << EOF
`wc -l < tmpfile_Cin`
`ls ${WORKDIR_FRS}/*.frs | head -n 1 | xargs wc -l | awk '{print $1}'`
${BootN}
${binN}
tmpfile_Cin
${binN}.bootstrap
${binN}.bootSig_low
${binN}.bootSig_high
${DELTA}
${BootSigLevel}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> Bootstrap C code failed on bin${binN} ..."
        rm -f *boot* tmpfile*
        exit 1;
    fi

done # Done Bin loop.

# Clean up.
rm -f ${WORKDIR_BootStrap}/tmpfile*

cd ${CODEDIR}

exit 0
