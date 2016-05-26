#!/bin/bash

#==============================================================
# SYNTHESIS
# This script: Deconvolve modified S ESF from each ScS traces.
# Using Ammon's iterative deconvolution code.
#
# Outputs:
#
#           ${WORKDIR_AmmonDecon}/${EQ}/
#
# Shule Yu
# Jul 12 2015
#==============================================================

echo ""
echo "--> `basename $0` is running."

# Work Begins.
for EQ in ${EQnames}
do

    echo "    ==> EQ ${EQ}. Iterative Deconvolution begin ! ( ${MainPhase}_${COMP} )"

    mkdir -p ${WORKDIR_AmmonDecon}/${EQ}
    cd ${WORKDIR_AmmonDecon}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ./INFILE
    trap "rm -rf ${WORKDIR_AmmonDecon}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Check stretch result.
    if ! [ -d ${WORKDIR_Stretch}/${EQ} ]
    then
        echo "    !=> Stretched ESF of ${EQ}_${ReferencePhase} doesn't exist ..."
        continue
    fi

    for cate in `seq 1 ${CateN}`
    do
        # C code I/O.
        keys="<STNM> <Peak>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$

        rm -f tmpfile_infile_*

        while read stnm peak
        do
            ${BASHCODEDIR}/Shift_Normalize.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${stnm}.waveform ${peak} 5 > ${stnm}.shifted_trace
            echo ${stnm} ${WORKDIR_AmmonDecon}/${EQ}/${stnm}.shifted_trace 0 >> tmpfile_infile_${cate}
        done < tmpfile_$$

        # C Code. (prepare data for simmon's decovolution)
        ${EXECDIR}/Ammon.out 2 2 4 << EOF
${cate}
`wc -l < tmpfile_infile_${cate}`
tmpfile_infile_${cate}
${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched
${DELTA}
-100
100
0.3
EOF
        if [ $? -ne 0 ]
        then
            echo "    !=> ${EQ}_Category${cate} Ammon C code failed ..."
            continue
        fi

        # Run Ammon's code.
        while read stnm waveformfile peak
        do
            ${EXECDIR}/iterdecon > /dev/null << EOF
${stnm}.tapered.sac
${cate}.esf.sac
${NBumps}
0.0
0.001
${Gauss_Ammon}
1
0
EOF
            if [ $? -ne 0 ]
            then
                echo "    !=> ${EQ}_Category${cate} Ammon F code failed ..."
                continue
            fi

            cp decon.out ${stnm}.trace.sac

            sac > /dev/null << EOF
r decon.out
w alpha decon.out.ascii
q
EOF
            # Find peak of ESF.
            keys="<ESFPeak>"
            ESFPeak=`${BASHCODEDIR}/Findfield.sh tmpfile_${cate}_StretchDeconInfo "${keys}" | head -n 1`
#             ESFPeak=15


            awk ' NR>30 {print $1"\n"$2"\n"$3"\n"$4"\n"$5}' decon.out.ascii \
            | sed '/^$/d' \
            | awk -v D=${DELTA} -v T=${ESFPeak} '{printf "%.4lf %.5e\n",NR*D-(100-T),$1}' > tmpfile_$$

            ${BASHCODEDIR}/Shift_Normalize.sh tmpfile_$$ 0 5 > ${stnm}.trace

        done < tmpfile_infile_${cate}

    done # done Category loop.

    # Post-process some info.

    cat tmpfile_1_StretchDeconInfo > ${EQ}_StretchDecon_Info

    if [ ${CateN} -ge 2 ]
    then
        for cate in `seq 2 ${CateN}`
        do
            awk 'NR>1 {print $0}' tmpfile_${cate}_StretchDeconInfo >> ${EQ}_StretchDecon_Info 2>/dev/null
        done
    fi

    rm -f ${WORKDIR_AmmonDecon}/${EQ}/tmpfile*

done # End of EQ loop.

cd ${CODEDIR}

exit 0
