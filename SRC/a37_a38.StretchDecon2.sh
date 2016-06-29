#!/bin/bash

#=================================================================
# SYNTHESIS
# This script: Stretch S ESW or ScS traces to match their shape.
# Note: Do this record by record.
# Then deconvolve the ESW from the signal.
#
# Different from a37_a38: Search Tstart first, then fix Tstar,
#                         search vertical stretch on S.
#                         See details in StretchDecon2.cpp
#
# Outputs:
#
#           ${WORKDIR_Stretch}/${EQ}/
#           ${WORKDIR_WaterDecon}/${EQ}/
#           ${SYNDB}.Master_a37
#           ${SYNDB}.Master_a38
#
# Shule Yu
# Jun 09 2016
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Continue from last modification.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_$$;
drop table if exists Master2_$$;
create table Master_$$ as select * from Master_a36;
create table Master2_$$ as select * from Master_a36;
EOF

# Work Begins.
for EQ in ${EQnames}
do
	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_$$ where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${SYNDB} < tmpfile_CheckValid_$$`
	rm -f tmpfile_CheckValid_$$
	if [ ${NR} -eq 0 ]
	then
		continue
	fi

	rm -rf ${WORKDIR_Stretch}/${EQ}
	rm -rf ${WORKDIR_WaterDecon}/${EQ}
    mkdir -p ${WORKDIR_Stretch}/${EQ}
    mkdir -p ${WORKDIR_WaterDecon}/${EQ}

    cd ${WORKDIR_Stretch}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stretch}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Stretch}/${EQ} ${WORKDIR_WaterDecon}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    echo "    ==> ${EQ} Stretch/Decon begin !"

    for cate in `seq 1 ${CateN}`
    do

        # Check ESF result.

        if ! [ -d ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate} ]
        then
            echo "    !=> ${ReferencePhase}_${EQ}_Category${cate} ESF doesn't exist ..."
            continue
        fi

        if ! [ -d ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate} ]
        then
            echo "    !=> ${MainPhase}_${EQ}_Category${cate} ESF doesn't exist ..."
            continue
        fi

		# Gather Information.
		mysql -N -u shule ${SYNDB} > tmpfile_Cin_$$ << EOF
select Pairname,stnm,concat("${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/",stnm,".waveform"),FullStackFile_S,concat("${WORKDIR_WaterDecon}/${EQ}/",stnm,".tapered"),concat("${WORKDIR_Stretch}/${EQ}/",stnm,".StretchedTaperSource"),concat("${WORKDIR_WaterDecon}/${EQ}/",stnm,".trace"),Peak_ScS,NA_ScS from Master_$$ where eq=${EQ} and wantit=1 and Category=${cate} order by Misfit4_ScS;
EOF

        # C Code.
        ${EXECDIR}/StretchDecon.out 2 5 17 << EOF
${nXStretch}
${nYStretch}
tmpfile_Cin_$$
tmpfile_Cout_$$
tmpfile_Cout2_$$
${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate}
${WORKDIR_Stretch}/${EQ}/TstaredESW_Cate${cate}_Tstar_
${LCompare}
${RCompare}
2.0
${V1}
${V2}
${AMPlevel_Default}
${DELTA}
${Waterlevel}
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
            echo "    !=> StretchDecon.out failed for Category: ${cate} ..."
            continue
        fi

		# format infile.
		sed 's/[[:blank:]]\+/,/g' tmpfile_Cout_$$ > tmpfile_in_$$

		# put the calculation into Master_$$.
		mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
DeconSource  varchar(200) comment "Decon source file for this pair.",
SNR_W1       double comment "Decon SNR, signal is the peak, noise is right before signal window",
SNR_W2       double comment "Decon SNR, signal is the peak, noise is right after signal window",
SNR_D        double comment "Decon SNR, signal is the peak, noise is the same window as ESW noise window",
Shift_D      double comment "Time Shift (CC between ESW and ScS, first get aligned at their Peak?)",
CCC_D        double comment "CCC between ESW and ScS, first get aligned at their Peak",
Ts_D         double comment "Best fit tstar operator (negative means tstar on ScS)",
Ver_D        double comment "Best fit vertical stretch factor",
Diff_D       double comment "Best fit Average absolute difference",
Misfit_D     double comment "Half-Height difference for ESW and ScS waveforms",
N1_Time      double comment "Noise window begin for SNR_D",
S1_Time      double comment "Signal window begin for SNR_D/SNR_W1/SNR_W2",
N2_Time      double comment "Noise window begin for SNR_W1",
N3_Time      double comment "Noise window begin for SNR_W2"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,DeconSource,SNR_W1,SNR_W2,@tmp1,Shift_D,CCC_D,Ts_D,Ver_D,Diff_D,Misfit_D,N1_Time,S1_Time,N2_Time,N3_Time)
set SNR_D=if(convert(@tmp1,double),@tmp1,NULL);
EOF

		# update Master_$$.
		${BASHCODEDIR}/UpdateTable.sh ${SYNDB} Master_$$ tmptable$$ PairName

		# format infile2.
		sed 's/[[:blank:]]\+/,/g' tmpfile_Cout2_$$ > tmpfile_in_$$

		# put the calculation into Master2_$$.
		mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
DeconSource  varchar(200) comment "Decon source file for this pair."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,DeconSource);
EOF

		# update Master2_$$.
		${BASHCODEDIR}/UpdateTable.sh ${SYNDB} Master2_$$ tmptable$$ PairName

    done # Done Category loop.

	rm -f tmpfile*$$

done # Done EQ loop.

# Create Master_a38
mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a38;
create table Master_a38 as select * from Master_$$;
drop table if exists Master_$$;
EOF


# Create Master_a37
mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a37;
create table Master_a37 as select * from Master2_$$;
drop table if exists Master2_$$;
EOF

cd ${WORKDIR}

exit 0
