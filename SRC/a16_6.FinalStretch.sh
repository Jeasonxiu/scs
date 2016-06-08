#!/bin/bash

#=================================================================
# This script: Stretch S/ScS ESF to look like ScS/S ESF.
# Vertical stretch is always applied on S.
# Horizontal stretch (tstar) is applied on S when Ts>=0.
# Horizontal stretch (tstar) is applied on ScS when Ts<0.
#
# Outputs:
#
#           ${WORKDIR_Stretch}/${EQ}/
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a13;
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

    echo "    ==> ${EQ} Stretching begin !"

	rm -rf ${WORKDIR_Stretch}/${EQ}
    mkdir -p ${WORKDIR_Stretch}/${EQ}
    cd ${WORKDIR_Stretch}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stretch}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Stretch}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

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
		mysql -N -u shule ${DB} > tmpfile_PairName_$$ << EOF
select PairName from Master_$$ where eq=${EQ} and wantit=1 and Category=${cate};
EOF

        # C Code.
        ${EXECDIR}/FinalStretch.out 3 7 8 << EOF
${nXStretch}
${nYStretch}
${cate}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/fullstack
${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched
${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.newScS
${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate}
${WORKDIR_Stretch}/${EQ}/plotfile_shifted_original_${cate}
${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate}
${LCompare}
${RCompare}
-2.0
2.0
${V1}
${V2}
${AMPlevel_Default}
${DELTA}
EOF

        if [ $? -ne 0 ]
        then
            echo "    !=> Stretch: ${EQ} stretch C code failed for Category: ${cate} ..."
            continue
        fi

		# put the calculation into Master_$$.
		mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
DeconSource  varchar(200) comment "Decon source file for this pair."
);
load data local infile "tmpfile_PairName_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
set DeconSource="${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched";
EOF
		# update Master_$$.
		${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

    done # Done Category loop.

	rm -f tmpfile*$$

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a16;
create table Master_a16 as select * from Master_$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
