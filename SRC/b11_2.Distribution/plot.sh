#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot structure histogram result.
#
# Shule Yu
# May 28 2015
# ===========================================================

VERTICNUM=2
HORIZNUM=3
VERTICPER="0.75"
HORIZPER="0.8"
PLOTORIENT=""

if [ -z ${PLOTORIENT} ]
then
    YMOVE="8.1"
    PLOTVERTIC="7.5"
    PLOTHORIZ="10"
else
    YMOVE="10.7"
    PLOTVERTIC="10.5"
    PLOTHORIZ="7.5"
fi

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

hskip=`echo "${PLOTVERTIC}/${VERTICNUM}" | bc -l`
wskip=`echo "${PLOTHORIZ}/($((HORIZNUM-1))+${HORIZPER})" | bc -l`
height=`echo "${hskip}*${VERTICPER}" | bc -l`
width=`echo "${wskip}*${HORIZPER}" | bc -l`

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 10p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.25p,gray,-

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

for EQ in ${EQnames}
do
    # CMT info.
    CMT=`grep ${EQ} ${CMTINFO} | awk 'NR==1 {print $0}'`
	strike=`echo "${CMT}" | awk '{print $3}'`
	dip=`echo "${CMT}" | awk '{print $4}'`
	rake=`echo "${CMT}" | awk '{print $5}'`

    # Check calculation result.
    if ! [ -e ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/INFILE ]
    then
        echo "    !=> Run ESF_All first on ${EQ}..."
        continue
    fi

    echo "    ==> Ploting S waveform cluster distribution of ${EQ}..."

    # Gather information.
	mysql -N -u shule ScS > tmpfile_$$ << EOF
select evde from Master_a11 where eq=${EQ} limit 1;
EOF
	read evde < tmpfile_$$
    Vs=`${BASHCODEDIR}/prem_velocity.sh S ${evde}`

	mysql -N -u shule ScS > tmpfile_allinfo << EOF
select category,stlo,stla,gcarc,az,asin(Srayp*${Vs}/(6371.0-evde))*180.0/PI(),asin(ScSrayp*${Vs}/(6371.0-evde))*180.0/PI(),Misfit_S_All,Misfit_ScS_All from Master_a11 where eq=${EQ} and wantit=1;
EOF

	awk '{print $1,$2,$3}' tmpfile_allinfo > tmpfile_cate_stlo_stla
	awk '{print $1,$4,$5}' tmpfile_allinfo > tmpfile_cate_gcarc_az
	awk '{print $1,$5,$6,$8}' tmpfile_allinfo > tmpfile_cate_az_Stakeoff_misfit
	awk '{print $1,$5,$7,$9}' tmpfile_allinfo > tmpfile_cate_az_ScStakeoff_misfit
	awk '{print $1,$8,$9}' tmpfile_allinfo > tmpfile_cate_Smisfit_ScSmisfit

    for cate in `seq 1 ${CateN}`
    do
        NR[${cate}]=`awk -v C=${cate} '{ if ($1==C) print $1 }' tmpfile_allinfo | wc -l`
    done


    # Plot Begin.

	OUTFILE=${EQ}.ps

	title=${EQ}
	PROJ="-JX${PLOTHORIZ}i/0.3i"
	REG="-R-1/1/-1/1"

	cat > tmpfile_$$ << EOF
0 0 ${title}, Number of traces: @;${color[1]};${NR[1]}@;; @;${color[2]};${NR[2]}@;; @;${color[3]};${NR[3]}@;;
EOF

	gmt pstext tmpfile_$$ -F+jCB+f16p ${REG} ${PROJ} -X0.65i -Ya${YMOVE}i ${PLOTORIENT} -N -K > ${OUTFILE}

	gmt psxy -J -R -Y${PLOTVERTIC}i -O -K >> ${OUTFILE} << EOF
EOF
	gmt psxy -J -R -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

	# SubPlots.
	for count2 in `seq 1 $((VERTICNUM*HORIZNUM))`
	do
		if [ -e ${PLOTSRCDIR}/plot_${count2}.sh ]
		then
			${PLOTSRCDIR}/plot_${count2}.sh
		fi

		if [ $((count2%HORIZNUM)) -eq 0 ]
		then
			gmt psxy -J -R -X`echo "-$((HORIZNUM-1))*${wskip}" | bc -l`i -Y-${hskip}i -O -K >> ${OUTFILE} << EOF
EOF
		else
			gmt psxy -J -R -X${wskip}i -O -K >> ${OUTFILE} << EOF
EOF
		fi

	done

	# Seal it.
	rm -f tmpfile*
	gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # done EQ loop.

# Make PDF.
Title=${0}
Title=${Title%/plot.sh}
Title=${Title##*/}
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title}.pdf

cd ${CODEDIR}

exit 0
