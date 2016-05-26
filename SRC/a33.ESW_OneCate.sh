#!/bin/bash

# ==============================================================
# SYNTHESIS
# This script make ESF on all S traces to find the S waveform
# position.
#
# Outputs:
#
#           ${WORKDIR_ESFAll}/${EQ}/
#
# Mysql:    Update ScS.Master
#
# Shule Yu
# Jun 22 2014
# ==============================================================

echo ""
echo "--> `basename $0` is running. "

# Continue from last modification.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a32;
EOF

# Work Begins.
for EQ in ${EQnames}
do

    # EQ specialized parameters.

	WBegin="-5"
	WLen="15"
	WBegin_ScS="-5"
	WLen_ScS="15"

    # S.
    rm -rf ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}
    mkdir -p ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}
    cd ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/INFILE
    trap "rm -rf ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    echo "    ==> EQ ${EQ}. E.S.W begin ! ( ${ReferencePhase}_${COMP} )."

	# Information collection.
	mysql -N -u shule ${SYNDB} > tmpfile_Cin_$$ << EOF
select file,stnm,${ReferencePhase},${N_A_S},Rad_Pat_${ReferencePhase} from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/ESW.out 3 6 20 << EOF
${passes}
${order}
${Filter_Flag}
${EQ}
${ReferencePhase}
${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}
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
        echo "    !=> ESW C code failed on ${EQ}_${ReferencePhase} ..."
        exit 1
    fi

	# format infile.
	sed 's/[[:blank:]]\+/,/g' ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${EQ}.ESF_DT | awk 'NR>1 {print $0}' > tmpfile_in_$$

    # put the calculation into Master.
	mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName       varchar(22) not null unique primary key,
D_T_S_All      double comment "S arrival relative to PREM, ESW by all data.",
CCC_S_All      double comment "S wave shape CCC, ESW by all data.",
SNR_S_All      double comment "S SNR, ESW by all data.",
Weight_S_All   double comment "Given weight to S constructing the ESW by all data.",
Misfit_S_All   double comment "S half-height width comparing to ESW by all data.",
Misfit2_S_All  double comment "S half-height area comparing to ESW by all data.",
Norm2_S_All    double comment "S Norm2 difference comparing to ESW by all data.",
Peak_S_All     double comment "S peak time relative to PREM, ESW by all data.",
NA_S_All       double comment "S noise anchor time relative to S arrival time, ESW by all data.",
N_T1_S_All     double comment "S noise Window T1 relative to S arrival time, ESW by all data.",
N_T2_S_All     double comment "S noise Window T2 relative to S arrival time, ESW by all data.",
S_T1_S_All     double comment "S signal Window T1 relative to S arrival time, ESW by all data.",
S_T2_S_All     double comment "S signal Window T2 relative to S arrival time, ESW by all data.",
Polarity_S_All integer comment "S Polarity, ESW by all data.",
WL_S_All       double comment "S noise section spectrum maximum, ESW by all data.",
Amp_S_All      double comment "S amplitude after filtering, ESW by all data."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(@tmp1,@tmp2,D_T_S_All,CCC_S_All,SNR_S_All,Weight_S_All,Misfit_S_All,Misfit2_S_All,Norm2_S_All,Peak_S_All,NA_S_All,N_T1_S_All,N_T2_S_All,S_T1_S_All,S_T2_S_All,Polarity_S_All,@tmp3,WL_S_All,Amp_S_All)
set PairName=concat(@tmp1,"_",@tmp2);
EOF

	# update Master.
	${BASHCODEDIR}/UpdateTable.sh ${SYNDB} Master_$$ tmptable$$ PairName
	mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where eq=${EQ} and Weight_S_All=0;
EOF
	# deal with bad data
	if [ -s ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/BadTraces.txt ]
	then
		for item in `cat ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/BadTraces.txt`
		do

			mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where file="${item}";
EOF
		done
	fi

	# Clean up.
	rm -f ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/tmpfile*$$





    # ScS.
    rm -rf ${WORKDIR_ESFAll}/${EQ}_${MainPhase}
    mkdir -p ${WORKDIR_ESFAll}/${EQ}_${MainPhase}
    cd ${WORKDIR_ESFAll}/${EQ}_${MainPhase}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/INFILE
    trap "rm -rf ${WORKDIR_ESFAll}/${EQ}_${MainPhase} ${WORKDIR}/*_${RunNumber} ; exit 1" SIGINT

    echo "    ==> EQ ${EQ}. E.S.W begin ! ( ${MainPhase}_${COMP} )."



	# Information collection.
	mysql -N -u shule ${SYNDB} > tmpfile_Cin_$$ << EOF
select file,stnm,${MainPhase}+D_T_S_All,${N_A_ScS},Rad_Pat_${MainPhase} from Master_$$ where eq=${EQ} and WantIt=1;
EOF
	mysql -N -u shule ${SYNDB} > tmpfile_POLARITY << EOF
select stnm,Polarity_S_All from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/ESW.out 3 6 20 << EOF
${passes}
${order}
${Filter_Flag}
${EQ}
${MainPhase}
${WORKDIR_ESFAll}/${EQ}_${MainPhase}
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
        echo "    !=> ESF C code failed on ${EQ}_${MainPhase} ..."
        exit 1
    fi

	# format infile.
	sed 's/[[:blank:]]\+/,/g' ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${EQ}.ESF_DT | awk 'NR>1 {print $0}' > tmpfile_in_$$

    # put the calculation into Master.
	mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName         varchar(22) not null unique primary key,
D_T_ScS_All      double comment "ScS arrival relative to PREM, ESW by all data.",
CCC_ScS_All      double comment "ScS wave shape CCC, ESW by all data.",
SNR_ScS_All      double comment "ScS SNR, ESW by all data.",
Weight_ScS_All   double comment "Given weight to ScS constructing the ESW by all data.",
Misfit_ScS_All   double comment "ScS half-height width comparing to ESW by all data.",
Misfit2_ScS_All  double comment "ScS half-height area comparing to ESW by all data.",
Norm2_ScS_All    double comment "ScS Norm2 difference comparing to ESW by all data.",
Peak_ScS_All     double comment "ScS peak time relative to PREM+D_T_S_All, ESW by all data.",
NA_ScS_All       double comment "ScS noise anchor time relative to ScS arrival time, ESW by all data.",
N_T1_ScS_All     double comment "ScS noise Window T1 relative to ScS arrival time, ESW by all data.",
N_T2_ScS_All     double comment "ScS noise Window T2 relative to ScS arrival time, ESW by all data.",
S_T1_ScS_All     double comment "ScS signal Window T1 relative to ScS arrival time, ESW by all data.",
S_T2_ScS_All     double comment "ScS signal Window T2 relative to ScS arrival time, ESW by all data.",
Polarity_ScS_All integer comment "ScS Polarity, ESW by all data.",
Amp_ScS_All      double comment "ScS amplitude after filtering, ESW by all data."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(@tmp1,@tmp2,D_T_ScS_All,CCC_ScS_All,SNR_ScS_All,Weight_ScS_All,Misfit_ScS_All,Misfit2_ScS_All,Norm2_ScS_All,Peak_ScS_All,NA_ScS_All,N_T1_ScS_All,N_T2_ScS_All,S_T1_ScS_All,S_T2_ScS_All,Polarity_ScS_All,@tmp3,@tmp4,Amp_ScS_All)
set PairName=concat(@tmp1,"_",@tmp2);
EOF

	# update Master.
	${BASHCODEDIR}/UpdateTable.sh ${SYNDB} Master_$$ tmptable$$ PairName
	mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where eq=${EQ} and Weight_ScS_All=0;
EOF

	# deal with bad data
	if [ -s ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/BadTraces.txt ]
	then
		for item in `cat ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/BadTraces.txt`
		do

			mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where file="${item}";
EOF
		done
	fi

	# Clean up.
	rm -f ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/tmpfile*

done # Done EQ loop.

mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a33;
create table Master_a33 as select * from Master_$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
