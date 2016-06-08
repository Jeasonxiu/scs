#!/bin/bash

# ==============================================================
# This script make ESF for ScS.
#
# Outputs:
#
#           ${WORKDIR_ESF}/${EQ}_ScS/
#
# Mysql:    ScS.Master_a13
#
# Shule Yu
# Jun 22 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a12;
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

	echo "    ==> EQ ${EQ}. E.S.F begin ! ( ${MainPhase}_${COMP} )."

    # EQ specialized parameters.

    E1_ScS=`grep ${EQ} ${WORKDIR}/EQ_ESW_${RunNumber} | awk '{print $4}'`
    E2_ScS=`grep ${EQ} ${WORKDIR}/EQ_ESW_${RunNumber} | awk '{print $5}'`
    F1=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`
    WBegin=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $2}'`
    WLen=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $3}'`
    WBegin_ScS=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $4}'`
    WLen_ScS=`grep ${EQ} ${WORKDIR}/EQ_Peak_${RunNumber} | awk '{print $5}'`

    for cate in `seq 1 ${CateN}`
    do

        rm -rf ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}
        mkdir -p ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}
        cd ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}
        cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/INFILE
        trap "rm -rf ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate} ${WORKDIR}/tmpfile*_${RunNumber}; exit 1" SIGINT


		# Information collection.
		mysql -N -u shule ${DB} > tmpfile_Cin_$$ << EOF
select file,stnm,${MainPhase}+D_T_S,${N_A_ScS},Rad_Pat_${MainPhase} from Master_$$ where eq=${EQ} and Category=${cate} and WantIt=1;
EOF
		mysql -N -u shule ${DB} > tmpfile_POLARITY << EOF
select stnm,Polarity_S from Master_$$ where eq=${EQ} and WantIt=1;
EOF


        # C code.
		${EXECDIR}/ESW.out 3 6 20 << EOF
${passes}
${order}
${Filter_Flag}
${EQ}
${MainPhase}
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}
tmpfile_Cin_$$
STDOUT
${EQ}.ESF_DT
${Cut1_ScS}
${Cut2_ScS}
${E1_ScS}
${E2_ScS}
${F1}
${F2}
${S1_ScS}
${S2_ScS}
${N1_ScS}
${N2_ScS}
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
            echo "    !=> ESF C code failed on ${EQ}_${MainPhase}_Category${cate} ..."
            exit 1
        fi

		# format infile.
		sed 's/[[:blank:]]\+/,/g' ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}.ESF_DT | awk 'NR>1 {print $0}' > tmpfile_in_$$

		# put the calculation into Master_$$.
		mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
ESWFile_ScS  varchar(200) comment "ScS ESW file.",
FullStackFile_ScS  varchar(200) comment "ScS ESW full stack file.",
D_T_ScS      double comment "ScS arrival relative to PREM, ESW by categorized data.",
CCC_ScS      double comment "ScS wave shape CCC, ESW by categorized data.",
SNR_ScS      double comment "ScS SNR, ESW by categorized data.",
Weight_ScS   double comment "Given weight to ScS constructing the ESW by categorized data.",
Misfit_ScS   double comment "ScS half-height width comparing to ESW by categorized data.",
Misfit2_ScS  double comment "ScS half-height area comparing to ESW by categorized data.",
Misfit3_ScS  double comment "ScS Peak to zero width comparing to ESW by categorized data.",
Misfit4_ScS  double comment "ScS Peak to zero area comparing to ESW by categorized data.",
M1_B_ScS     double comment "ScS half-height begin position. in sec. relative to prem.",
M1_E_ScS     double comment "ScS half-height end position. in sec. relative to prem.",
M2_B_ScS     double comment "ScS zero-crossing begin position. in sec. relative to prem.",
M2_E_ScS     double comment "ScS zero-crossing end position. in sec. relative to prem.",
Norm2_ScS    double comment "ScS Norm2 difference comparing to ESW by categorized data.",
Peak_ScS     double comment "ScS peak time relative to PREM+D_T_S, ESW by categorized data.",
NA_ScS       double comment "ScS noise anchor time relative to ScS arrival time, ESW by categorized data.",
N_T1_ScS     double comment "ScS noise Window T1 relative to ScS arrival time, ESW by categorized data.",
N_T2_ScS     double comment "ScS noise Window T2 relative to ScS arrival time, ESW by categorized data.",
S_T1_ScS     double comment "ScS signal Window T1 relative to ScS arrival time, ESW by categorized data.",
S_T2_ScS     double comment "ScS signal Window T2 relative to ScS arrival time, ESW by categorized data.",
Polarity_ScS integer comment "ScS Polarity, ESW by categorized data.",
Amp_ScS      double comment "ScS amplitude after filtering, ESW by categorized data."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(@tmp1,@tmp2,D_T_ScS,CCC_ScS,SNR_ScS,Weight_ScS,Misfit_ScS,Misfit2_ScS,Misfit3_ScS,Misfit4_ScS,M1_B_ScS,M1_E_ScS,M2_B_ScS,M2_E_ScS,Norm2_ScS,Peak_ScS,NA_ScS,N_T1_ScS,N_T2_ScS,S_T1_ScS,S_T2_ScS,Polarity_ScS,@tmp3,@tmp4,Amp_ScS)
set PairName=concat(@tmp1,"_",@tmp2),
ESWFile_ScS="${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${cate}/${EQ}.ESF_F",
FullStackFile_ScS="${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${cate}/fullstack";
EOF

		# update Master_$$.
		${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName
		mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where eq=${EQ} and Weight_ScS=0;
EOF

        # Clean up.
        rm -f ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/tmpfile*

    done # Done category loop.

done # Done EQ loop.


mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a13;
create table Master_a13 as select * from Master_$$;
drop table if exists Master_$$;
EOF



cd ${WORKDIR}

exit 0
