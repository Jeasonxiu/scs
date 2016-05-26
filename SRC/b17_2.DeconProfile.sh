#!/bin/bash

# ===========================================================
# Plot Deconed ScS profile.
#
# Shule Yu
# Oct 26 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot Parameters.

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

Range=1
TIMEMIN=-20
TIMEMAX=20
DISTMIN=60
DISTMAX=80
XSIZE=2
YSIZE=8.5

DISTMIN=`echo ${DISTMIN}-${Range}/2 | bc -l`
DISTMAX=`echo ${DISTMAX}+${Range}/2 | bc -l`

BY=`echo $DISTMIN $DISTMAX | awk '{print (int(int(($2-$1)/10)/5)+1)*5 }' |  awk '{print $1, $1/5}'`
BY1=`echo ${BY}| awk '{print $1}'`
BY2=`echo ${BY}| awk '{print $2}'`
SCALE=X"$XSIZE"i/-"$YSIZE"i
RANGE=$TIMEMIN/$TIMEMAX/$DISTMIN/$DISTMAX/
BAXIS="a10f5/a${BY1}f${BY2}"
Y0="-Y1.5i"

for EQ in ${EQnames}
do
    # EQ info.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select evlo,evla,evde,mag from Master_a17 where eq=${EQ} limit 1;
EOF
	read EVLO EVLA EVDE EVMA < tmpfile_$$
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`
    HH=`echo ${EQ}   | cut -b 9-10`
    MIN=`echo ${EQ}  | cut -b 11-12`

	# ===============================================
	#     ! Make the calculation results !
	# ===============================================

	for Cate in `seq 1 ${CateN}`
	do
		mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select gcarc,concat("${WORKDIR_Decon}/${EQ}/",stnm,".trace") from Master_a17 where eq=${EQ} and wantit=1 and category=${Cate};
EOF

		${EXECDIR}/seis2xy_p.out 0 2 3 << EOF
tmpfile_$$
xy.seismograms_${Cate}
${Range}
${TIMEMIN}
${TIMEMAX}
EOF

	done

    # ====================
    #     ! Plot !
    # ====================

	OUTFILE=${EQ}.ps

	# Title
	pstext -Jx1i -R0/6/0/9 -K -N -P $Y0 > ${OUTFILE} << EOF
3.0 9.3 20  0 0 CB Event: ${MM}/${DD}/$YYYY ${HH}:${MIN} Phase=${MainPhase} Comp=T
3.0 9.0 15  0 0 CB $EQ  LAT=$EVLO LON=$EVLA Z=$EVDE Mb=$EVMA
-0.5 4.5 15 90 0 CB Distance (deg)
3.0 -0.7 15  0 0 CB Time relative to deconed ScS peak (sec)
EOF

	# more text: script name and time stamp
	echo "3.0 8.7 10 0 0 CB SCRIPT: `basename $0`" > datetag1
	date "+CREATION DATE: %m/%d/%y  %H:%M:%S" > datetag2
	paste datetag1 datetag2 > datetag3
	pstext datetag3 -Jx -R -N -Wored -G0 -O -K >> ${OUTFILE}

	# plot the records
	for Cate in `seq 1 ${CateN}`
	do
		psxy xy.seismograms_${Cate} -J${SCALE} -R${RANGE} -W0.005i,${color[${Cate}]} -B"$BAXIS"WSne -m -O -K >> ${OUTFILE}
		psxy -J -R -O -K -X2.5i >> ${OUTFILE} << EOF
EOF
	done

	# close up plot
	pstext -J -R -O >> ${OUTFILE} << EOF
EOF

done # Done EQ loop.

Title=`basename $0`
cat `ls -rt *ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
