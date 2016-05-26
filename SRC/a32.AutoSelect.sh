#!/bin/bash

# ============================================================
# SYNTHESIS
# This script uses basic information to select proper data.
#
# a. reject data with begin/end time error.
# b. gcarc selection .
# c. traffic, reject S and sS too close to ScS.
#        (Since our synthesis doesn't contain up-going energy,
#        traffic by sS is not considered here.)
# d. add artificial radiation pattern ( = 1 ) to
#    <Rad_${ReferencePhase}> and <Rad_${MainPhase}> in basicinfo.
#
# Outputs:
#
#           ${WORKDIR_AutoSelect}/${EQ}.File_List
#           ${WORKDIR_AutoSelect}/${EQ}.Station_List
#           ${WORKDIR_Select}/${EQ}.File_List
#           ${WORKDIR_Select}/${EQ}.Station_List
#           ${WORKDIR_Select}/${EQ}.BasicInfo
#
# Shule Yu
# Mar 20 2015
# ============================================================

echo ""
echo "--> `basename $0` is running. "
trap "rm -f ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.

## Continue from last modification.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a31;
EOF


# a. select good begin / end time trace.
mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where S is null or ScS is null or S+${Cut1_S}<begin or S+${Cut2_S}>end or ScS+${Cut1_ScS}<begin or ScS+${Cut2_ScS}>end;
EOF


# b. select gcarc.
mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where GCARC<${DISTMIN} or GCARC>${DISTMAX};
EOF


# c. select traffic.
for PHASE2 in `cat ${WORKDIR}/tmpfile_TrafficP_${RunNumber}`
do
	mysql -u shule ${SYNDB} << EOF
update Master_$$ set WantIt=0 where ${PHASE2} is null or abs(${PHASE2}-${MainPhase})<${Buff};
EOF
done

# Make backup.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_a32;
create table Master_a32 as select * from Master_$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
