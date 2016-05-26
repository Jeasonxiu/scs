#!/bin/bash

# =========================================================
# This script run kmeans cluster analysis on S waveforms to
# devide waveforms from one earthquake into several sub-
# categories.
# The waveform is aligned before hand in a cross-correlation 
# scheme in a10. when we do ESW on all the data.
#
# Shule Yu
# Jun 22 2014
# =========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a10;
EOF

## select only high weight traces.
mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where Weight_S_All is null or Weight_S_All<0.7 or Weight_ScS_All is null or Weight_ScS_All<0.1;
EOF

# Work Begins.
for EQ in ${EQnames}
do

    rm -r ${WORKDIR_Category}/${EQ}
    mkdir -p ${WORKDIR_Category}/${EQ}
    cd ${WORKDIR_Category}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Category}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Category}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    echo "    ==> Categorizing ${EQ} S shape..."

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select PairName,concat("${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/",STNM,".waveform"),STNM,D_T_S_All,Polarity_S_All from Master_$$ where eq=${EQ} and WantIt=1;
EOF

    # C code.
    ${EXECDIR}/Cluster.out 1 2 4 << EOF
${CateN}
tmpfile_$$
tmpfile_Cout_$$
${CateB}
${CateWidth}
${CateTaper}
${DELTA}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> category C code failed ..."
        exit 1
    fi

	# format infile.
	sed 's/[[:blank:]]\+/,/g' tmpfile_Cout_$$ > tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
Category     integer comment "Which category this pair belongs to"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,Category);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName


	# Rearrange Clustering result.

	# Information collection.
	case "${CateSort}" in
		1 )
			mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select PairName,Category,misfit_s_all from Master_$$ where eq=${EQ} and WantIt=1;
EOF
			;;

		* )
			rm -f tmpfile_$$
			for cate in `seq 1 ${CateN}`
			do
				mysql -N -u shule ${DB} >> tmpfile_$$ << EOF
set @tmp=(select count(*) from Master_$$ where eq=${EQ} and WantIt=1 and Category=${cate});
select PairName,Category,@tmp from Master_$$ where eq=${EQ} and WantIt=1 and Category=${cate};
EOF
			done
			;;
	esac

    ${EXECDIR}/Cluster_Arrange.out 1 2 0 << EOF
${CateN}
tmpfile_$$
tmpfile_Cout_$$
EOF

	# format infile.
	sed 's/[[:blank:]]\+/,/g' tmpfile_Cout_$$ > tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
Category     integer comment "Which category this pair belongs to"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,Category);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

    # Clean up.
    rm -f ${WORKDIR_Category}/${EQ}/tmpfile*

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists Master_a11;
create table Master_a11 as select * from Master_$$;
drop table if exists tmptable$$;
drop table if exists Master_$$;
EOF

cd ${WORKDIR}

exit 0
