#!/bin/bash

#==============================================================
# This script: Deconvolve modified S ESF from each ScS traces.
#
# Outputs:
#
#           ${WORKDIR_WaterDecon}/${EQ}/
#           ScS.Master_a17
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"


# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a16;
EOF


# Work Begins.
for EQ in ${EQnames}
do
	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_$$ where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
	if [ ${NR} -eq 0 ]
	then
		continue
	fi


    echo "    ==> ${EQ} Deconvolution begin ..."

	rm -rf ${WORKDIR_WaterDecon}/${EQ}
    mkdir -p ${WORKDIR_WaterDecon}/${EQ}
    cd ${WORKDIR_WaterDecon}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_WaterDecon}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_WaterDecon}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Check stretch result.
    if ! [ -d ${WORKDIR_Stretch}/${EQ} ]
    then
        echo "    !=> Stretched ESW of ${EQ}_${ReferencePhase} doesn't exist ..."
        continue
    fi

    for cate in `seq 1 ${CateN}`
    do

        # C code I/O.
		mysql -N -u shule ${DB} > tmpfile_infile_${cate} << EOF
select STNM,concat("${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/",STNM,".waveform"),Peak_ScS,NA_ScS from Master_$$ where wantit=1 and eq=${EQ} and Category=${cate};
EOF

        # C Code.
		# If ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} has negative value as stretch (first column),
		# do Tstar on ScS traces.

		Ratio=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $1}'`

        ${EXECDIR}/Decon.out 3 2 16 << EOF
${cate}
`wc -l < tmpfile_infile_${cate}`
${MoreInfo}
tmpfile_infile_${cate}
${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched
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

	# format infile.
	sed 's/[[:blank:]]\+/,/g' ${EQ}_StretchDecon_Info | awk 'NR>1 {print $0}' > tmpfile_in_$$

	# put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
SNR_W1       double comment "Decon SNR, signal is the peak, noise is right before signal window",
SNR_W2       double comment "Decon SNR, signal is the peak, noise is right after signal window",
SNR_D        double comment "Decon SNR, signal is the peak, noise is the same window as ESW noise window",
Shift_D      double comment "Time Shift (CC between ESW and ScS, first get aligned at their Peak?)",
CCC_D        double comment "CCC between ESW and ScS, first get aligned at their Peak?",
Misfit_D     double comment "Half-Height difference for ESW and ScS waveforms",
N1_Time      double comment "Noise window begin for SNR_D",
S1_Time      double comment "Signal window begin for SNR_D/SNR_W1/SNR_W2",
N2_Time      double comment "Noise window begin for SNR_W1",
N3_Time      double comment "Noise window begin for SNR_W2"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(@tmp1,SNR_W1,SNR_W2,@tmp2,Shift_D,CCC_D,Misfit_D,@tmp3,N1_Time,S1_Time,N2_Time,N3_Time)
set PairName=concat("${EQ}_",@tmp1),
SNR_D=if(convert(@tmp2,double),@tmp2,NULL);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName


	# Clean up.
    rm -f ${WORKDIR_WaterDecon}/${EQ}/tmpfile*

done # End of EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a17;
create table Master_a17 as select * from Master_$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
