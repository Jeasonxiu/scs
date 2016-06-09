#!/bin/bash

# ======================================================
# This script calculate the corrected gcarc by equalzing
# the depth of all EQs.
#
# Mysql:    ScS.Master_a09
#
# Shule Yu
# Apr 22 2015
# ======================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR}/tmpdir_$$
cd ${WORKDIR}/tmpdir_$$
trap "rm -rf ${WORKDIR}/tmpdir_$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT


# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a08;
EOF


# Work Begins.

# 1. Generate ray path for PREM, source at surface.
#    From ${DISTMIN} to ${DISTMAX} in 0.1 increment.

cat > .taup << EOF
taup.distance.precision=2
taup.depth.precision=2
EOF

rm -f tmpfile_dist_filename
for dist in `seq ${DISTMIN} 0.1 ${DISTMAX}`
do
	taup_path -mod prem -ph ${MainPhase} -h 0 -deg ${dist} -o stdout | awk 'NR>1 {print $0}' > tmpfile_${dist}.path
	echo "${dist} tmpfile_${dist}.path" >> tmpfile_dist_filename
done

# 2. Correct it EQ by EQ.
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

    echo "    ==> Calculating shifted gcarc for ${EQ}."

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_stnm_evde_gcarc << EOF
	select stnm,evde,gcarc from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/CorrectDepth.out 0 4 1 << EOF
tmpfile_dist_filename
tmpfile_stnm_evde_gcarc
tmpfile_Cout_pairname_shiftgcarc
${EQ}
${ShiftDepth}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> CorrectDepth C++ code failed ..."
		rm -rf ${WORKDIR}/tmpdir_$$
        exit 1
    fi

	# format infile.
	sed 's/[[:blank:]]\+/,/g' tmpfile_Cout_pairname_shiftgcarc > tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
SHIFT_GCARC  double comment "Depth corrected to ${ShiftDepth} km great circle distance."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,@tmp1)
set SHIFT_GCARC=if(convert(@tmp1,double),@tmp1,NULL);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a09;
create table Master_a09 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR}/tmpdir_$$

cd ${WORKDIR}

exit 0
