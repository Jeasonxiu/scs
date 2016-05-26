#!/bin/bash

#==============================================================
# This script do bootstrap test on PREM group.
#
# Outputs:
#
#           ${WORKDIR_Cluster}/PREM.waveform
#           ${WORKDIR_Cluster}/PREM.Sig
#           ${WORKDIR_Cluster}/PREM.Sig_max
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. "

# Check cluster result.
if ! [ -e ${WORKDIR_Cluster}/INFILE ]
then
    echo "    !=> `basename $0`: no cluster result in ${WORKDIR_Cluster} ..."
    exit 1
fi

cd ${WORKDIR_Cluster}
trap "rm ${WORKDIR_Cluster}/PREM* ${WORKDIR_Cluster}/tmpfile* ${WORKDIR}/*_${RunNumber} 2>/dev/null; exit 1" SIGINT

# Work Begins.

# BootSrtap on PREM group.
# Assume that the group with greater traces is the PREM group.

echo "    ==> BootStrapping PREM bins ..."

# C code I/O.
rm tmpfile_$$ 2>/dev/null
for binN in `awk '{if ($2==2) print $1}' Grid_Cate`
do
    awk 'NR>1 {print $1}' ${WORKDIR_Geo}/${binN}.grid >> tmpfile_$$
done
sort -u tmpfile_$$ > tmpfile_PREM

tmpfile=${WORKDIR_FRS}/`head -n 1 tmpfile_PREM`.frs
keys="<EQ> <STNM> <Weight>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_Geo}/INFO "${keys}" > tmpfile_StationFile

rm tmpfile_Cin 2>/dev/null
while read EQ_STNM
do
    EQ=${EQ_STNM%_*}
    STNM=${EQ_STNM#*_}
    awk -v E=${EQ} -v S=${STNM} -v F=${EQ_STNM} -v D=${WORKDIR_FRS} '{ if ($1==E && $2==S) print D"/"F".frs",$3}' tmpfile_StationFile >> tmpfile_Cin
done < tmpfile_PREM

# C code.
${EXECDIR}/BootStrap.out 3 4 2 << EOF
`wc -l < tmpfile_Cin`
`wc -l < ${tmpfile}`
${BootN}
tmpfile_Cin
PREM.waveform
PREM.Sig
PREM.Sig_max
${DELTA}
${BootSigLevel}
EOF

if [ $? -ne 0 ]
then
    echo "    !=> Bootstrap C code failed ..."
    rm ${WORKDIR_Cluster}/PREM* ${WORKDIR_Cluster}/tmpfile* 2>/dev/null
    exit 1;
fi

# Clean up.
rm tmpfile* 2>/dev/null

cd ${CODEDIR}

exit 0
