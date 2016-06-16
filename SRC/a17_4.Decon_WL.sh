#!/bin/bash

#==============================================================
# This script: Deconvolve modified S ESF from each ScS traces.
# Also, we deconvolve original S ESF from S to test the
# stability of our deconvolution.
#
# Outputs:
#
#           ${WORKDIR_WaterWL}/${EQ}/
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Work Begins.
for EQ in ${EQnames}
do
	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_$$ where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
	rm -f tmpfile_CheckValid_$$
	if [ ${NR} -eq 0 ]
	then
		continue
	fi

    echo "    ==> EQ ${EQ}. Deconvolution begin ! ( ${MainPhase}_${COMP} )"

	rm -rf ${WORKDIR_WaterWL}/${EQ}
    mkdir -p ${WORKDIR_WaterWL}/${EQ}
    cd ${WORKDIR_WaterWL}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_WaterWL}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_WaterWL}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Check stretch result.
    if ! [ -d ${WORKDIR_Stretch}/${EQ} ]
    then
        echo "    !=> Stretched ESF of ${EQ}_${ReferencePhase} doesn't exist ..."
        continue
    fi

    for cate in `seq 1 ${CateN}`
    do
        # C code I/O.
        keys="<STNM> <Peak> <Nanchor>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        awk '{print $1}' tmpfile_$$ > tmpfile_stnm

        keys="<STNM> <WaterLevel>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile1_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile1_$$ tmpfile_stnm | awk '{print $2}'> tmpfile2_$$

        paste tmpfile_$$ tmpfile2_$$ > tmpfile1_$$

        rm -f tmpfile_infile_*
        while read stnm peak Nanchor Waterlevel
        do
            echo ${stnm} ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${stnm}.waveform ${peak} ${Nanchor} ${Waterlevel} >> tmpfile_infile_${cate}
        done < tmpfile1_$$

        # C Code.
        ${EXECDIR}/Decon_WL.out 3 2 14 << EOF
${cate}
`wc -l < tmpfile_infile_${cate}`
${MoreInfo}
tmpfile_infile_${cate}
${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched
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
EOF
        if [ $? -ne 0 ]
        then
            echo "    !=> ${EQ}_Category${cate} decon C code failed ..."
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
    rm -f ${WORKDIR_WaterWL}/${EQ}/tmpfile*
done # End of EQ loop.

cd ${WORKDIR}

exit 0
