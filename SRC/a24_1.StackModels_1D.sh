#!/bin/bash

# ========================================================
# This script populate the synthesis to make a same set of
# synthesis as data in terms of the great circle distance.
# Execute after a41. is done.
#
# Outputs:
#
#           ${WORKDIR_Model}/${Model}_${BinN}.frstack
#
# Shule Yu
# Apr 22 2015
# ========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Check bin stack result.
if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> `basename $0`: No bin stack result in ${WORKDIR_Geo} ..."
    exit 1
fi

# Check Synthesis FRS result.
if ! [ -e ${SYNWORKDIR_FRS}/INFILE ]
then
    echo "    !=> `basename $0`: no synthesis frs traces in ${SYNWORKDIR_FRS} ..."
    exit 1
fi

mkdir -p ${WORKDIR_Model}
cd ${WORKDIR_Model}
rm -f ${WORKDIR_Model}/*
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Model}/INFILE
trap "rm -f ${WORKDIR_Model}/* ${WORKDIR}/*_${RunNumber} ; exit 1" SIGINT

# Work Begins.

echo "    ==> Stacking Synthesis for each bins ..."

# Make synthesis stacks.

# I/O. Part I.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    keys="<EQ> <STNM> <Weight_Smooth>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_$$

    keys="<EQ> <STNM> <SHIFT_GCARC> <Weight>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Geo}/INFO "${keys}" > tmpfile_StationFile_$$

    rm -f tmpfile_${binN}_shiftgcarc_$$
    while read EQ STNM weight
    do
        awk -v E=${EQ} -v S=${STNM} -v W=${weight} '{ if ($1==E && $2==S) printf "%.1lf\t%.4lf\n",$3,W}' tmpfile_StationFile_$$ >> tmpfile_${binN}_shiftgcarc_$$
    done < tmpfile_$$

done # Done bin loop.

# I/O. Part II.

for Model in ${Modelnames}
do

    keys="<EQ> <STNM> <GCARC>"
    ${BASHCODEDIR}/Findfield.sh ${SYNWORKDIR_FRS}/INFO_All "${keys}" | awk -v M=${Model} -v D=${SYNWORKDIR_FRS} '{if ($1==M) printf "%.1lf\t%s/%s_%s.frs\n",$3,D,$1,$2}' > tmpfile_${Model}_$$

done

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    for Model in ${Modelnames}
    do
        # C code I/O.
        D_Max=`minmax -C tmpfile_${Model}_$$ | awk '{print $2}'`
        awk -v D=${D_Max} '{ if ($1>D) printf "%.1lf\n",D ; else printf "%.1lf\n",$1}' tmpfile_${binN}_shiftgcarc_$$ > tmpfile_grouplist_$$

        awk '{ print $2 }' tmpfile_${binN}_shiftgcarc_$$ > tmpfile_weight_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_${Model}_$$ tmpfile_grouplist_$$ | awk '{print $2}' > tmpfile1_$$
        paste tmpfile1_$$ tmpfile_weight_$$ > tmpfile_Cin_$$

        firstfile=`head -n 1 tmpfile_Cin_$$ | awk '{print $1}'`

        # C code.
        ${EXECDIR}/StackModels.out 2 2 1 << EOF
`wc -l < tmpfile_Cin_$$`
`wc -l < ${firstfile}`
tmpfile_Cin_$$
${Model}_${binN}.frstack
${DELTA}
EOF
		mv tmpfile_Cin_$$ ${Model}_${binN}.frs_weight

    done # Done Model loop.

done # Done Bin loop.

# Clean up.
rm -f ${WORKDIR_Model}/tmpfile*$$

cd ${CODEDIR}

exit 0
