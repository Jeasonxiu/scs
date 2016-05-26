#!/bin/bash

# ===================================================
# This script count how the categorization behave on
# the basis of each stations.
#
# Shule Yu
# Jun 17 2015
# ===================================================

echo ""
echo "--> `basename $0` is running."
mkdir -p ${WORKDIR_Stations}
cd ${WORKDIR_Stations}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stations}/INFILE
trap "rm -rf ${WORKDIR_Stations} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT
echo "    ==> Merging station info... "

# Work Begins.

# Find Stations list.
rm -f tmpfile_stnm_cate
for file in `find ${WORKDIR_Category} -iname "*.Category"`
do
    awk 'NR>1 {print $0}' ${file} >> tmpfile_stnm_cate
done

sort -u -k 1,1 tmpfile_stnm_cate | awk '{print $1}' > tmpfile_stnm


echo "<STNM> <Cate1> <Cate2> <Cate3>" > Main
while read stnm
do
    grep -w ${stnm} tmpfile_stnm_cate > tmpfile_$$
    if [ `wc -l < tmpfile_$$` -lt ${Threshold_STNM} ]
    then
        continue
    fi

    printf "%7s" ${stnm} >> Main

    for count in `seq 1 ${CateN}`
    do
        printf "\t%5d" `awk -v C=${count} '{if ($2==C) print $0}' tmpfile_$$ | wc -l` >> Main
    done

    printf "\n" >> Main

done < tmpfile_stnm

# grep -w 0 Main | awk '{print $1}' > SpecialList
grep -w 0 Main | awk '{if ($2==0) $2=""; if ($3==0) $3=""; if ($4==0) $4=""; print $0}' | awk '{if ($3=="" || $2/$3<0.5 || $2/$3 > 2) print $1 }' > SpecialList
grep -w 0 Main | awk '{if ($2==0) $2=""; if ($3==0) $3=""; if ($4==0) $4=""; print $0}' | awk '{if ($3=="" || $2/$3<0.5 || $2/$3 > 2) print $0 }' > SpecialList_Item

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
