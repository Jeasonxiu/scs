#!/bin/bash

# =================================================================
# Extract human selection from pdf files and update the selection
# database table.
#
# Mysql:    Create/Update ScS.a06
#
# Shule Yu
# Mar 23 2015
# =================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
cd ${WORKDIR_HandPick}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_HandPick}/INFILE
trap "rm -f ${WORKDIR_HandPick}/tmpfile* ${WORKDIR_HandPick}/*checked ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a04;
create table if not exists a06 as select PairName from Master_$$;
EOF

# Extract info from hand picked PDFs.
${BASHCODEDIR}/ExtractCheckbox.sh *.pdf

# Update S/ScS Info.
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


	## format infile.
	sed 's/[[:blank:]]\+/,/g' ${EQ}*_S_*.checked > tmpfile_in_$$
	sed 's/[[:blank:]]\+/,/g' ${EQ}*_S_*.unchecked > tmpfile_in2_$$
	sed 's/[[:blank:]]\+/,/g' ${EQ}*_ScS_*.checked > tmpfile_in3_$$
	sed 's/[[:blank:]]\+/,/g' ${EQ}*_ScS_*.unchecked > tmpfile_in4_$$

	mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists tmptable2$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key comment "Unique Pair Name, made by eq_stnm.",
KeepS        integer comment "Equal to 1 means S shape is good."
);
create table tmptable2$$(
PairName     varchar(22) not null unique primary key comment "Unique Pair Name, made by eq_stnm.",
KeepScS      integer comment "Equal to 1 means ScS shape is good."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName)
set KeepS=0;
load data local infile "tmpfile_in2_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName)
set KeepS=1;
load data local infile "tmpfile_in3_$$" into table tmptable2$$
fields terminated by "," lines terminated by "\n"
(PairName)
set KeepScS=0;
load data local infile "tmpfile_in4_$$" into table tmptable2$$
fields terminated by "," lines terminated by "\n"
(PairName)
set KeepScS=1;
EOF

	# update a06.
	${BASHCODEDIR}/UpdateTable.sh ${DB} a06 tmptable$$ PairName
	${BASHCODEDIR}/UpdateTable.sh ${DB} a06 tmptable2$$ PairName

done # Done EQ loop.

# update Master_$$.
${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ a06 PairName
mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists tmptable2$$;
update Master_$$ set WantIt=0 where KeepS=0 or KeepScS=0;
drop table if exists Master_a06;
create table Master_a06 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR_HandPick}/tmpfile* ${WORKDIR_HandPick}/*checked

cd ${WORKDIR}

exit 0
