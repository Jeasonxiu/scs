#!/bin/bash

# ==============================================================
# This script make ESF for S.
#
# Outputs:
#
#           ${WORKDIR_ESF}/${EQ}_S/
#
# Mysql:    ScS.Master_a12
#
# Shule Yu
# Jun 22 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a11;
EOF

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

    echo "    ==> EQ ${EQ}. E.S.F begin ! ( ${ReferencePhase}_${COMP} )."

    # EQ specialized parameters.

    E1_S=`grep ${EQ} ${WORKDIR}/EQ_ESW_${RunNumber} | awk '{print $2}'`
    E2_S=`grep ${EQ} ${WORKDIR}/EQ_ESW_${RunNumber} | awk '{print $3}'`
    F1=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`
    WBegin=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $2}'`
    WLen=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $3}'`
    WBegin_ScS=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $4}'`
    WLen_ScS=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $5}'`

    for cate in `seq 1 ${CateN}`
    do

        rm -rf ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}
        mkdir -p ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}
        cd ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}
        cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/INFILE
        trap "rm -rf ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate} ${WORKDIR}/tmpfile*${RunNumber}; exit 1" SIGINT

		# Information collection.
		mysql -N -u shule ${DB} > tmpfile_Cin_$$ << EOF
select file,stnm,${ReferencePhase},0.0,${N_A_S},Rad_Pat_${ReferencePhase} from Master_$$ where eq=${EQ} and Category=${cate} and WantIt=1;
EOF


        # C code.
		${EXECDIR}/ESW.out 3 6 20 << EOF
${passes}
${order}
${Filter_Flag}
${EQ}
${ReferencePhase}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}
tmpfile_Cin_$$
STDOUT
${EQ}.ESF_DT
${Cut1_S}
${Cut2_S}
${E1_S}
${E2_S}
${F1}
${F2}
${S1_S}
${S2_S}
${N1_S}
${N2_S}
${Taper_ESF}
${DELTA}
${SNRLOW}
${SNRHIGH}
${CCCOFF}
${RAMP}
${WBegin}
${WLen}
${WBegin_ScS}
${WLen_ScS}
EOF
        if [ $? -ne 0 ]
        then
            echo "    !=> ESF C code failed on ${EQ}_${ReferencePhase}_Category${cate} ..."
            exit 1
        fi


		# format infile.
		sed 's/[[:blank:]]\+/,/g' ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_DT | awk 'NR>1 {print $0}' > tmpfile_in_$$

		# put the calculation into Master_$$.
		mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName   varchar(22) not null unique primary key,
ESWFile_S  varchar(200) comment "S ESW file.",
FullStackFile_S  varchar(200) comment "S ESW full stack file.",
D_T_S      double comment "S arrival relative to PREM, ESW by categorized data.",
CCC_S      double comment "S wave shape CCC, ESW by categorized data.",
SNR_S      double comment "S SNR, ESW by categorized data.",
Weight_S   double comment "Given weight to S constructing the ESW by categorized data.",
Misfit_S   double comment "S half-height width comparing to ESW by categorized data.",
Misfit2_S  double comment "S half-height area comparing to ESW by categorized data.",
Misfit3_S  double comment "S Peak to zero width comparing to ESW by categorized data.",
Misfit4_S  double comment "S Peak to zero area comparing to ESW by categorized data.",
M1_B_S     double comment "S half-height begin position. in sec. relative to prem.",
M1_E_S     double comment "S half-height end position. in sec. relative to prem.",
M2_B_S     double comment "S zero-crossing begin position. in sec. relative to prem.",
M2_E_S     double comment "S zero-crossing end position. in sec. relative to prem.",
Norm2_S    double comment "S Norm2 difference comparing to ESW by categorized data.",
Peak_S     double comment "S peak time relative to PREM, ESW by categorized data.",
NA_S       double comment "S noise anchor time relative to S arrival time, ESW by categorized data.",
N_T1_S     double comment "S noise Window T1 relative to S arrival time, ESW by categorized data.",
N_T2_S     double comment "S noise Window T2 relative to S arrival time, ESW by categorized data.",
S_T1_S     double comment "S signal Window T1 relative to S arrival time, ESW by categorized data.",
S_T2_S     double comment "S signal Window T2 relative to S arrival time, ESW by categorized data.",
Polarity_S integer comment "S Polarity, ESW by categorized data.",
WL_S       double comment "S noise section spectrum maximum, ESW by categorized data.",
Amp_S      double comment "S amplitude after filtering, ESW by categorized data."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(@tmp1,@tmp2,D_T_S,CCC_S,SNR_S,Weight_S,Misfit_S,Misfit2_S,Misfit3_S,Misfit4_S,M1_B_S,M1_E_S,M2_B_S,M2_E_S,Norm2_S,Peak_S,NA_S,N_T1_S,N_T2_S,S_T1_S,S_T2_S,Polarity_S,@tmp3,WL_S,Amp_S)
set PairName=concat(@tmp1,"_",@tmp2),
ESWFile_S="${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_F",
FullStackFile_S="${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${cate}/fullstack";
EOF

		# update Master_$$.
		${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName
		mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where eq=${EQ} and Weight_S=0;
EOF

        # Clean up.
        rm -f ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/tmpfile*$$

    done # Done category loop.

done # Done EQ loop.


mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a12;
create table Master_a12 as select * from Master_$$;
drop table if exists Master_$$;
EOF



cd ${WORKDIR}

exit 0
