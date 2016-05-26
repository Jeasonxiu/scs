#!/bin/bash

# ============================================================
# This script extract header information from sac files.
#
# Will select "good" sac data ( non-segments, all three
# component exists ... see ${BASHCODEDIR}/select_sac_data.sh )
#
# Outputs:
#
#           ${WORKDIR_Basicinfo}/${EQ}.BasicInfo
#
# Mysql:
#           Create ScS.Master_a02
#
# Shule Yu
# Mar 20 2015
# ============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Basicinfo}
cd ${WORKDIR_Basicinfo}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Basicinfo}/INFILE

# create database ${DB}
mysql -u shule << EOF
create database if not exists ${DB};
EOF

# create Master_$$.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$(
WantIt       integer comment "This column decide wether the pair goes into next step",
PairName     varchar(22) not null unique primary key comment "Unique Pair Name, made by eq_stnm.",
EQ           varchar(12) comment "12-digit eq name",
STNM         varchar(10) comment "station name",
NETWK        varchar(5) comment "network name",
KCMPNM       varchar(5) comment "component",
FILE         varchar(200) comment "file name and position",
BEGIN        double comment "sac begin time,relative to source",
END          double comment "sac end time,relative to source",
GCARC        double comment "great circle distance",
AZ           double comment "azimuth",
BAZ          double comment "back azimuth",
EVLO         double comment "event longitude",
EVLA         double comment "event latitude",
EVDE         double comment "event depth in km",
MAG          double comment "event magnitude",
STLO         double comment "station longitude",
STLA         double comment "station latitude",
DELTA        double comment "signal sampling rate",
P            double comment "P arrival time",
Prayp        double comment "P ray parameter in sec.",
xpP          double comment "pP arrival time",
xpPrayp      double comment "pP ray parameter in sec.",
S            double comment "S arrival time",
Srayp        double comment "S ray parameter in sec.",
xsS          double comment "sS arrival time",
xsSrayp      double comment "sS ray parameter in sec.",
PP           double comment "PP arrival time",
PPrayp       double comment "PP ray parameter in sec.",
SS           double comment "SS arrival time",
SSrayp       double comment "SS ray parameter in sec.",
SKKS         double comment "SKKS arrival time",
SKKSrayp     double comment "SKKS ray parameter in sec.",
PKP          double comment "PKP arrival time",
PKPrayp      double comment "PKP ray parameter in sec.",
SKS          double comment "SKS arrival time",
SKSrayp      double comment "SKS ray parameter in sec.",
ScS          double comment "ScS arrival time",
ScSrayp      double comment "ScS ray parameter in sec."
);
EOF

# Work Begins.

for EQ in ${EQnames}
do

    echo "    ==> Generating general Information of ${EQ} ... "
    trap "rm -f ${WORKDIR_Basicinfo}/${EQ}* ${WORKDIR_Basicinfo}/tmpfile*$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Select good sac files and make general info file.
    ${BASHCODEDIR}/select_sac_data.sh ${DATADIR}/${EQ} ${COMP} > tmpfile_$$

    # Extract header info.
    echo "<EQ> <STNM> <NETWK> <BEGIN> <END> <KCMPNM> <GCARC> <AZ> <BAZ> <EVLO> <EVLA> <EVDE> <MAG> <STLO> <STLA> <DELTA> <P> <Prayp> <pP> <pPrayp> <S> <Srayp> <sS> <sSrayp> <PP> <PPrayp> <SS> <SSrayp> <SKKS> <SKKSrayp> <PKP> <PKPrayp> <SKS> <SKSrayp> <ScS> <ScSrayp> <FILE>" > ${EQ}.BasicInfo
    saclst kstnm knetwk b npts delta kcmpnm gcarc az baz evlo evla evdp mag stlo stla delta t0 user0 t1 user1 t2 user2 t3 user4 t4 user4 t5 user5 t6 user6 t7 user7 t8 user8 t9 user9 f `cat tmpfile_$$` | awk -v E=${EQ} '{$(NF+1)=$1; $1=""; $5=$4+$5*$6; $6=""; print E" "$0}' >> ${EQ}.BasicInfo

	# format infile.
	awk 'NR>1 {{if ($12>1000) $12=$12/1000} print $0}' ${EQ}.BasicInfo | sed 's/[[:blank:]]\+/,/g' > tmpfile_in_$$

	# update Master_$$.
	mysql -u shule ${DB} << EOF
load data local infile "tmpfile_in_$$" into table Master_$$
fields terminated by "," lines terminated by "\n"
(EQ,STNM,NETWK,BEGIN,END,KCMPNM,GCARC,AZ,BAZ,EVLO,EVLA,EVDE,MAG,STLO,STLA,DELTA,@tmpP,@tmpPrayp,@tmpxpP,@tmpxpPrayp,@tmpS,@tmpSrayp,@tmpxsS,@tmpxsSrayp,@tmpPP,@tmpPPrayp,@tmpSS,@tmpSSrayp,@tmpSKKS,@tmpSKKSrayp,@tmpPKP,@tmpPKPrayp,@tmpSKS,@tmpSKSrayp,@tmpScS,@tmpScSrayp,FILE)
set PairName=concat(EQ,"_",STNM),
P=if(@tmpP>0,@tmpP,NULL),
Prayp=if(@tmpPrayp>0,@tmpPrayp,NULL),
xpP=if(@tmpxpP>0,@tmpxpP,NULL),
xpPrayp=if(@tmpxpPrayp>0,@tmpxpPrayp,NULL),
S=if(@tmpS>0,@tmpS,NULL),
Srayp=if(@tmpSrayp>0,@tmpSrayp,NULL),
xsS=if(@tmpxsS>0,@tmpxsS,NULL),
xsSrayp=if(@tmpxsSrayp>0,@tmpxsSrayp,NULL),
PP=if(@tmpPP>0,@tmpPP,NULL),
PPrayp=if(@tmpPPrayp>0,@tmpPPrayp,NULL),
SS=if(@tmpSS>0,@tmpSS,NULL),
SSrayp=if(@tmpSSrayp>0,@tmpSSrayp,NULL),
SKKS=if(@tmpSKKS>0,@tmpSKKS,NULL),
SKKSrayp=if(@tmpSKKSrayp>0,@tmpSKKSrayp,NULL),
PKP=if(@tmpPKP>0,@tmpPKP,NULL),
PKPrayp=if(@tmpPKPrayp>0,@tmpPKPrayp,NULL),
SKS=if(@tmpSKS>0,@tmpSKS,NULL),
SKSrayp=if(@tmpSKSrayp>0,@tmpSKSrayp,NULL),
ScS=if(@tmpScS>0,@tmpScS,NULL),
ScSrayp=if(@tmpScSrayp>0,@tmpScSrayp,NULL),
WantIt=1;
EOF

done # Done EQ loop.

mysql -u shule ${DB} << EOF
drop table if exists Master_a02;
create table Master_a02 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR_Basicinfo}/tmpfile*$$

cd ${WORKDIR}

exit 0
