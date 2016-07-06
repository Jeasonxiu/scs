#!/bin/bash

#==============================================================
# This script stack FRS over geological bins cover target CMB
# area.
#
# Firstly, select traces according to gcarc, weight and human
#       inspection.
# Secondly, create bins, print out the geographyic bin result.
#
# Outputs:
#
#           ${WORKDIR_Geo}/${BinN}.grid
#           ScS.Master_a21
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

mkdir -p ${WORKDIR_Geo}
rm -f ${WORKDIR_Geo}/*
cd ${WORKDIR_Geo}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ./INFILE
trap "rm -f ${WORKDIR_Geo}/* ${WORKDIR}/*_${RunNumber} ; exit 1" SIGINT


# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a20;
EOF

# Work Begins.

# Select FRS goes into stack.

## 1. Select Gcarc / Weight.

echo "    ==> Selecting traces goes into bin stack ..."

mysql -u shule ${DB} << EOF
update Master_$$ set wantit=0 where SHIFT_GCARC<${D1_FRS} or SHIFT_GCARC>${D2_FRS} or Weight_Final<${Threshold_Weight} or Weight_Final is null ;
EOF

echo "select count(*) from Master_$$ where wantit=1" > tmpfile_$$
Count=`mysql -N -u shule ${DB} < tmpfile_$$`

if [ "${Count}" -le 1 ]
then
    echo "        !=> No traces selected after gcarc, weight threshold ..."
    rm -f ${WORKDIR_Geo}/*
    exit 1
fi

## 2. Human pick.
if [ "${flag_goodfile}" -eq 1 ]
then

	cp ${GoodDecon} tmpfile_in_$$

	mysql -u shule ${DB} << EOF
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
HandSelect   integer comment "HandPicked Good Decon."
);
load data local infile "tmpfile_in_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName)
set HandSelect=1;
EOF

	${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

	mysql -u shule ${DB} << EOF
update Master_$$ set wantit=0 where HandSelect is null or HandSelect!=1;
EOF

fi

echo "select count(*) from Master_$$ where wantit=1" > tmpfile_$$
Count=`mysql -N -u shule ${DB} < tmpfile_$$`
echo "        ==> Number of Selected FRS ( after gcarc, weight thresholds and human selection ): ${Count}."

# 3. Create bins.

echo "    ==> Creating Bins."
if [ "${flag_bin}" -eq 1 ]
then
    cp ${BinFile} tmpfile_BinFile_$$
else
    ${EXECDIR}/SetBins.out 0 1 7 << EOF
tmpfile_BinFile_$$
${LOMIN}
${LOMAX}
${LOINC}
${LAMIN}
${LAMAX}
${LAINC}
${Radius}
EOF
    if [ $? -ne 0 ]
    then
        echo "    !=> makebins C code failed ..."
        rm -f ${WORKDIR_Geo}/*
        exit 1;
    fi
fi

# 4. Binning records, using distance judgements.
echo "    ==> Geographic binning traces."

# C code I/O.
mysql -N -u shule ${DB} > tmpfile_Cin_$$ << EOF
select EQ,STNM,HITLO,HITLA from Master_$$ where wantit=1;
EOF

# C code.
${EXECDIR}/CircleBins.out 1 2 0 << EOF
${Threshold}
tmpfile_Cin_$$
tmpfile_BinFile_$$
EOF

if [ $? -ne 0 ]
then
    echo "    !=> GeoBin C code failed ..."
    rm -f ${WORKDIR_Geo}/*
    exit 1;
fi

# Count how many records are we using for modeling.
rm -f tmpfile_$$
for file in `ls ${WORKDIR_Geo}/*.grid`
do
	awk 'NR>1 {print $1"_"$2}' ${file} >> tmpfile_$$
done
echo "        ==> Number of bined FRS: `sort -u tmpfile_$$ | wc -l`."


# Make Master_a21;
mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a21;
create table Master_a21 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR_Geo}/tmpfile*$$

cd ${WORKDIR}

exit 0
