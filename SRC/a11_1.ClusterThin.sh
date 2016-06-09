#!/bin/bash

# =========================================================
# This script use misfit1 measurements on S to select thin
# S traces from each earthquakes.
#
# Mysql:    ScS.Master_a11
#
# Shule Yu
# Jun 23 2015
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
update Master_$$ set WantIt=0 where Weight_S_All is null or Weight_S_All<0.85 or Weight_ScS_All is null or Weight_ScS_All<0.1;
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

    rm -rf ${WORKDIR_Category}/${EQ}
    mkdir -p ${WORKDIR_Category}/${EQ}
    cd ${WORKDIR_Category}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Category}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Category}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    echo "    ==> Using the thin S shape of ${EQ} ..."

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select PairName,misfit_s_all from Master_$$ where eq=${EQ} and WantIt=1 order by misfit_s_all;
EOF

    # Get thin criteria.
    Line=`wc -l < tmpfile_$$`
    Line=`echo ${Line}/2 | bc`
	Thin=`awk -v L=${Line} 'NR==L {print $2}' tmpfile_$$`

	# format infile.
	sed 's/[[:blank:]]\+/,/g' tmpfile_$$ > tmpfile_in_$$

    # put the calculation into Master_$$.
	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
Category     integer comment "Which category this pair belongs to"
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,@tmp1)
set Category=if(@tmp1<${Thin},1,0);
EOF

	# update Master_$$.
	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

    
    # Step 2. For the sake of code conformity, we use code in a11_2 to output waveforms.

	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select PairName,concat("${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/",STNM,".waveform"),STNM,D_T_S_All,Polarity_S_All from Master_$$ where eq=${EQ} and Category=1;
EOF

    # C code.
    ${EXECDIR}/Cluster.out 1 2 4 << EOF
1
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


    # Clean up.
    rm -r ${WORKDIR_Category}/${EQ}/tmpfile*$$

done # Done EQ loop.

mysql -u shule ${DB} << EOF
update Master_$$ set WantIt=0 where Category!=1;
drop table if exists Master_a11;
create table Master_a11 as select * from Master_$$;
drop table if exists tmptable$$;
drop table if exists Master_$$;
EOF


cd ${WORKDIR}

exit 0
