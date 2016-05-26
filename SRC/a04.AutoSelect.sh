#!/bin/bash

# ============================================================
# This script uses basic information and ScS sampling location
# to select proper data.
#
# a. reject data with begin/end time error.
# b. gcarc selection .
# c. ScS sampling point located within target area.
# d. traffic, reject ${TrafficP} too close to ScS. (Pridicted by PREM)
#
# Mysql:    ScS.Master_a04
#
#
# Shule Yu
# Mar 20 2015
# ============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
trap "rm -f ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.

## Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a03;
EOF

# a. select good begin / end time trace.
mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where S is null or ScS is null or S+${Cut1_S}<begin or S+${Cut2_S}>end or ScS+${Cut1_ScS}<begin or ScS+${Cut2_ScS}>end;
EOF

# b. select gcarc.
mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where GCARC<${DISTMIN} or GCARC>${DISTMAX};
EOF

# c. select sampling.
mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where HITLO<${RLOMIN} or HITLO>${RLOMAX} or HITLA<${RLAMIN} or HITLA>${RLAMAX};
EOF

# d. select traffic.
for PHASE2 in `cat ${WORKDIR}/tmpfile_TrafficP_${RunNumber}`
do
	mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where ${PHASE2} is null or abs(${PHASE2}-${MainPhase})<${Buff};
EOF
done

# e. If the total trace of one EQ < 50, we don't use this EQ.
for EQ in ${EQnames}
do
	cat > tmpfile_$$ << EOF
select count(*) from Master_$$ where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_$$`

	if [ ${NR} -lt 50 ]
	then
		mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where eq=${EQ};
EOF
	fi
done


# Make backup.
mysql -u shule ${DB} << EOF
drop table if exists Master_a04;
create table Master_a04 as select * from Master_$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
