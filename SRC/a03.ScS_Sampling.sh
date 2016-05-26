#!/bin/bash

# ===============================================
# This script uses basic information to calculate
# ScS CMB bouncing locaiton.
#
# Outputs:
#
#       ${WORKDIR_Sampling}/${EQ}.Hitlocation
#
# Mysql:    ScS.Master_a03
#
# Shule Yu
# Mar 20 2015
# ===============================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Sampling}
cd ${WORKDIR_Sampling}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Sampling}/INFILE

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a02;
EOF

# Work Begins.
for EQ in ${EQnames}
do

    echo "    ==> Calculating ScS sampling locations for ${EQ}..."
    trap "rm -f ${EQ}* ${WORKDIR_Sampling}/tmpfile*$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_Cin_$$ << EOF
select evlo,evla,evde,stlo,stla,stnm from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/ScS_Sampling.out 0 5 0 << EOF
tmpfile_Cin_$$
${EQ}.Hitlocation
${MainPhase}
${ReferencePhase}
${EQ}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> scs_sampling C code failed ..."
        exit 1
    fi

	## format infile.
	awk 'NR>1 {print $4,$2,$3,$5}' ${EQ}.Hitlocation | sed 's/[[:blank:]]\+/,/g' > tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
WantIt       integer comment "This column decide weather the pair goes into next step",
PairName     varchar(22) not null unique primary key comment "Unique Pair Name, made by eq_stnm.",
HITLO        double comment "ScS CMB bounce point longitude",
HITLA        double comment "ScS CMB bounce point latitude"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,@tmpHITLO,@tmpHITLA,WantIt)
set HITLO=if(convert(@tmpHITLO,double),@tmpHITLO,NULL),
HITLA=if(convert(@tmpHITLA,double),@tmpHITLA,NULL);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a03;
create table Master_a03 as select * from Master_$$;
drop table if exists Master_$$;
EOF


# Clean up.
rm -f ${WORKDIR_Sampling}/tmpfile*$$ ${WORKDIR_Sampling}/.taup

cd ${WORKDIR}

exit 0
