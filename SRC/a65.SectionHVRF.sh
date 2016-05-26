#!/bin/bash

# ====================================================================
# This script count how many high-velocity anomalies does one certain
# ray path pass through.
#
# Shule Yu
# May 27 2015
# =================================================================

echo ""
echo "--> `basename $0` is running."

for TomoModel in `cat ${WORKDIR}/tmpfile_TomoModels_${RunNumber}`
do
    # Model parameters.
    MODELname=${TomoModel%_*}
    MODELcomp=${TomoModel#*_}
    echo "    ==> Tomography Model: ${MODELname}"
    echo "        Component       : ${MODELcomp}"

    mkdir -p ${WORKDIR_Structure}/${TomoModel}
    cd ${WORKDIR_Structure}/${TomoModel}
	cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Structure}/${TomoModel}/INFILE
    trap "rm -r ${WORKDIR_Structure}/${TomoModel} ${WORKDIR}/*_${RunNumber} 2>/dev/null; exit 1" SIGINT

    # Check the chosen tomography model.
    cp ${WORKDIR_Decompress}/${TomoModel}/*dat .
    if [ $? -ne 0 ]
    then
        echo "    !=> Run model decompression first ..."
        exit 1;
    fi

    # Work Begins.
    for EQ in ${EQnames}
    do
        echo "    ==> Counting path for ${EQ} on ${MODELname} ... "

        # C code I/O.
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "<STNM>" | awk '{print $1}' | sort -u > tmpfile1_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Category}/${EQ}/${EQ}.Category "<STNM>" | awk '{print $1}' | sort -u > tmpfile2_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${EQ}.ESF_DT "<STNM> <Weight>" | awk '{if ($2>0) print $1}' | sort -u > tmpfile3_$$
        comm -1 -2 tmpfile1_$$ tmpfile2_$$ > tmpfile_$$
        comm -1 -2 tmpfile_$$ tmpfile3_$$  > tmpfile_stnm

        rm tmpfile_Cin 2>/dev/null
        while read stnm
        do
            echo "${VFast} ${stnm} ${WORKDIR_Sampling}/${EQ}_${stnm}_${ReferencePhase}.path ${WORKDIR_Sampling}/${EQ}_${stnm}_${MainPhase}.path" >> tmpfile_Cin
        done < tmpfile_stnm

        # C code.
        ${EXECDIR}/SectionHVRF.out 0 3 $((SectionNum+1)) << EOF
tmpfile_Cin
S
${EQ}
${D1}
${D2}
${D3}
${D4}
EOF

        if [ $? -ne 0 ]
        then
            echo "    !=> structure_section C code failed ..."
            exit 1
        fi

    done # Done EQ loop.

done # Done TomoModel loop.

# Clean up.
rm *dat tmpfile* 2>/dev/null

cd ${CODEDIR}

exit 0
