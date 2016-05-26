#!/bin/bash

#==============================================================
# This script: skip decon and directly use ScS into the FRS
# operation.
#
# Shule Yu
# Apr 22 2015
#==============================================================

echo ""
echo "--> `basename $0` is running."

for EQ in ${EQnames}
do

    echo "    ==> EQ ${EQ}. NO deconvolution begin ! ( ${MainPhase}_${COMP} )"
    OUTDIR="${WORKDIR_Decon}/${EQ}"
    mkdir -p ${OUTDIR}
    cd ${OUTDIR}
    cp ${CODEDIR}/INFILE .
    trap "rm -r ${OUTDIR} 2> /dev/null; exit 1" SIGINT

    # Judge whether Stretched S ESF has been made.
    ESFDIR=${WORKDIR_Stretch}/${EQ}
    DATADIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}
    esffile="${ESFDIR}/${EQ}.ESF_F"
    if ! [ -d ${ESFDIR} ]
    then
        echo "    ==> Stretched ESF of ${ReferencePhase} of ${EQ} doesn't exist ..."
        continue
    fi

    for cate in `seq 1 ${CateN}`
    do
        # I/O for stretching.
        keys="<STNM> <Peak> <D_T> <Nanchor>"
        ${BASHCODEDIR}/Findfield.sh ${DATADIR_ScS}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$

        rm tmpfile_infile_* 2>/dev/null
        while read stnm peak OnSet Nanchor
        do
            echo ${stnm} ${DATADIR_ScS}/${cate}/${stnm}.waveform ${esffile}${cate}.stretched ${peak} ${OnSet} ${Nanchor} >> tmpfile_infile_${cate}
        done < tmpfile_$$

        # Run C Code.
        ${EXECDIR}/nodecon.out 2 1 13 << EOF
${cate}
`wc -l < tmpfile_infile_${cate}`
tmpfile_infile_${cate}
${Waterlevel}
${Sigma}
${gwidth}
${DELTA}
${Taper_source}
${Taper_signal}
${C1_D}
${C2_D}
${N1_D}
${N2_D}
${S1_D}
${S2_D}
${AN}
EOF
        if [ $? -ne 0 ]
        then
            echo "    ==> Decon: ${EQ} No deconvolution C code failed on Category ${cate}..."
            continue
        fi
    done # done Category loop.

    cat tmpfile_1_StretchDeconInfo > ${EQ}_StretchDecon_Info
    for cate in `seq 2 ${CateN}`
    do
        awk 'NR>1 {print $0}' tmpfile_${cate}_StretchDeconInfo >> ${EQ}_StretchDecon_Info 2>/dev/null
    done

    rm tmpfile* 2>/dev/null

done # End of EQ loop.

cd ${CODEDIR}

exit 0
