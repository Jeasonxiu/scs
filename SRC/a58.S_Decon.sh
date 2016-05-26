#!/bin/bash

#==============================================================
# This script: Deconvolve S ESF from each S traces, to evaluate
# how the deconvolution algorithm works.
#
# Outputs:
#
#           ${WORKDIR_DeconS}/${EQ}/
#
# Shule Yu
# May 20 2015
#==============================================================

echo ""
echo "--> `basename $0` is running."

# Work Begins.
for EQ in ${EQnames}
do
    echo "    ==> EQ ${EQ}. S Deconvolution begin ! ( ${ReferencePhase}_${COMP} )"

	rm -rf ${WORKDIR_DeconS}/${EQ}
    mkdir -p ${WORKDIR_DeconS}/${EQ}
    cd ${WORKDIR_DeconS}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_DeconS}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_DeconS}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    for cate in `seq 1 ${CateN}`
    do
        # Judge whether Stretched S ESF has been made.
        if ! [ -d ${WORKDIR_ESF}/${EQ}_${ReferencePhase} ]
        then
            echo "    ~=> ESF of ${ReferencePhase} of ${EQ}, cate ${cate} doesn't exist ..."
            continue
        fi

        # C code I/O.
        keys="<STNM> <Peak> <Nanchor>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$

        rm -f tmpfile_infile_*
        while read stnm peak Nanchor
        do
            echo ${stnm} ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${stnm}.waveform ${peak} ${Nanchor} >> tmpfile_infile_${cate}
        done < tmpfile_$$

        # C Code.
		# If ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} has negative value as stretch (first column),
		# do Tstar on ScS traces.
		Ratio=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $1}'`

        ${EXECDIR}/Decon.out 3 2 16 << EOF
${cate}
`wc -l < tmpfile_infile_${cate}`
${MoreInfo}
tmpfile_infile_${cate}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
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
${F1_D}
${F2_D}
${Ratio}
EOF
        if [ $? -ne 0 ]
        then
			echo "    !=> Decon: ${EQ} S Deconvolution C code failed on Category ${cate}..."
            continue
        fi

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

	# Clean up.
    rm -f ${WORKDIR_DeconS}/${EQ}/tmpfile*

done # End of EQ loop.

cd ${WORKDIR}

exit 0
