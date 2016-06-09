#!/bin/bash

# =================================================================
# Calculate radiation pattern for the stations.
# Using pre-collected CMT solutions.
# If we don't have CMT info, return 1.0 for both phases.
#
# Mysql:    ScS.Master_a08
#
#
# Shule Yu
# Apr 22 2015
# =================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR}/tmpdir_$$
cd ${WORKDIR}/tmpdir_$$
trap "rm -f ${WORKDIR}/tmpdir_$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a06;
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

    echo "    ==> Calculating rad_pat for ${EQ}."

    # CMT info.
    CMT=`grep ${EQ} ${CMTINFO} | awk 'NR==1 {print $0}'`
    if ! [ -z "${CMT}" ]
    then
        STRIKE=`echo "${CMT}" | awk '{print $3}'`
        DIP=`echo "${CMT}" | awk '{print $4}'`
        RAKE=`echo "${CMT}" | awk '{print $5}'`
        HaveCMT=1
    else
        HaveCMT=0
    fi

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_Cin_$$ << EOF
	select stnm,evlo,evla,evde,stlo,stla,${MainPhase}rayp,${ReferencePhase}rayp from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/RadPat.out 1 3 3 << EOF
${HaveCMT}
tmpfile_Cin_$$
tmpfile_Cout_$$
${EQ}
${STRIKE}
${DIP}
${RAKE}
EOF
    if [ $? -ne 0 ]
    then
        echo "    !=> radpat C code failed ..."
        exit 1
    fi

	# format infile.
	sed 's/[[:blank:]]\+/,/g' tmpfile_Cout_$$> tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
Rad_Pat_ScS  double comment "ScS radiation pattern.",
Rad_Pat_S    double comment "S radiation pattern."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,@tmp1,@tmp2)
set Rad_Pat_ScS=if(convert(@tmp1,double),@tmp1,NULL),
Rad_Pat_S=if(convert(@tmp2,double),@tmp2,NULL);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a08;
create table Master_a08 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR}/tmpdir_$$

cd ${WORKDIR}

exit 0
