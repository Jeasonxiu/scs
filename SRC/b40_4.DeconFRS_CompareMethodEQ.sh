#!/bin/bash

# ================================================================
# Compare Plot: source equalized ScS and its FRS from two selcted
# methods for 2 given EQs. (from Different Decon Dir)
#
# This is only used for synthesis plot.
#
# Shule Yu
# Nov 16 2015
# ================================================================

if [ "${Method1}" = "Waterlevel" ]
then
    DeconDIR1=${WORKDIR_WaterDecon}
    FRSDIR1=${WORKDIR_WaterFRS}
elif [ "${Method1}" = "Ammon" ]
then
    DeconDIR1=${WORKDIR_AmmonDecon}
    FRSDIR1=${WORKDIR_AmmonFRS}
elif [ "${Method1}" = "Subtract" ]
then
    DeconDIR1=${WORKDIR_SubtractDecon}
    FRSDIR1=${WORKDIR_SubtractFRS}
else
    DeconDIR1=${WORKDIR}/CompareDecon
    FRSDIR1=${WORKDIR}/CompareFRS
fi

if [ "${Method2}" = "Waterlevel" ]
then
    DeconDIR2=${WORKDIR_WaterDecon}
    FRSDIR2=${WORKDIR_WaterFRS}
elif [ "${Method2}" = "Ammon" ]
then
    DeconDIR2=${WORKDIR_AmmonDecon}
    FRSDIR2=${WORKDIR_AmmonFRS}
elif [ "${Method2}" = "Subtract" ]
then
    DeconDIR2=${WORKDIR_SubtractDecon}
    FRSDIR2=${WORKDIR_SubtractFRS}
else
    DeconDIR2=${WORKDIR}/CompareDecon
    FRSDIR2=${WORKDIR}/CompareFRS
fi

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onethirdwidth=`echo ${PLOTWIDTH_ALL} / 2.5 | bc -l`
onesixthwidth=`echo ${PLOTWIDTH_ALL} / 6 | bc -l`

color[1]=red
color[2]=blue

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

# ================================================
#         ! Check calculation result !
# ================================================

if ! [ -e ${FRSDIR1}/INFO_All ] || ! [ -e ${FRSDIR2}/INFO_All ]
then
    echo "    ==> `basename $0`: Run FRS first ..."
    exit 1
fi

echo "    ==> `basename $0`: Plotting ${EQ1} & ${EQ2} Decon, FRS result from method ${Method1} and ${Method2} ..."

# =========================================
#     ! Check the calculation result !
# =========================================
INFILE1=${FRSDIR1}/INFILE
INFILE2=${FRSDIR2}/INFILE

order1=`grep "<order>" ${INFILE1} | awk '{print $2}'`
passes1=`grep "<passes>" ${INFILE1} | awk '{print $2}'`
Time1=`grep "<Time>" ${INFILE1} | awk '{print $2}'`
F11=`grep "<F1>" ${INFILE1} | awk '{print $2}'`
F12=`grep "<F2>" ${INFILE1} | awk '{print $2}'`

order2=`grep "<order>" ${INFILE2} | awk '{print $2}'`
passes2=`grep "<passes>" ${INFILE2} | awk '{print $2}'`
Time2=`grep "<Time>" ${INFILE2} | awk '{print $2}'`
F21=`grep "<F1>" ${INFILE2} | awk '{print $2}'`
F22=`grep "<F2>" ${INFILE2} | awk '{print $2}'`

if ! [ ${order1} = ${order2} ] || ! [ ${passes1} = ${passes2} ] || ! [ ${Time1} = ${Time2} ] || ! [ ${F11} = ${F21} ] || ! [ ${F12} = ${F22} ]
then
	echo "    !=> `basename $0`: Operations don't match ..."
	exit 1
fi


# EQs info.
keys="<EQ> <Vs_Bot> <Rho_Bot> <Thickness>"
${BASHCODEDIR}/Findfield.sh ${Index1} "${keys}" > tmpfile_$$

INFO=`grep ${EQ1} tmpfile_$$ | awk '{print $0}'`
Vs_Change_1=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
Rho_Change_1=`echo "${INFO}" | awk '{printf "%.2lf",$3}'`
Thickness_1=`echo "${INFO}" | awk '{printf "%.2lf",$4}'`

keys="<EQ> <Vs> <Rho> <Thickness>"
${BASHCODEDIR}/Findfield.sh ${Index2} "${keys}" > tmpfile_$$
INFO=`grep ${EQ2} tmpfile_$$ | awk '{print $0}'`
Vs_Change_2=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
Rho_Change_2=`echo "${INFO}" | awk '{printf "%.2lf",$3}'`
Thickness_2=`echo "${INFO}" | awk '{printf "%.2lf",$4}'`

# ================================================
#         ! Make Plot Data !
# ================================================

keys="<EQ> <STNM> <GCARC>"
${BASHCODEDIR}/Findfield.sh ${FRSDIR1}/INFO_All "${keys}" | awk -v E=${EQ1} '{if ($1==E) {$1="";print $0}}' > tmpfile1_info
${BASHCODEDIR}/Findfield.sh ${FRSDIR2}/INFO_All "${keys}" | awk -v E=${EQ2} '{if ($1==E) {$1="";print $0}}' > tmpfile2_info

awk '{print $2}' tmpfile1_info | sort -g > tmpfile_gcarc1
awk '{print $2}' tmpfile2_info | sort -g > tmpfile_gcarc2

comm -1 -2 tmpfile_gcarc1 tmpfile_gcarc2 > tmpfile_samegcarc

# ===================================
#        ! Plot !
# ===================================

NSTA=`wc -l < tmpfile_samegcarc`

PROJ="-JX`echo "${onethirdwidth}*0.95"| bc -l`i/${halfh}i"
REGESF="-R-50/50/-1/1"
PROJ2="-JX`echo "${onethirdwidth}*2*0.95"| bc -l`i/${halfh}i"
REGESF2="-R-100/100/-1/1"
PROJFRS="-JX${onesixthwidth}i/${halfh}i"
REGFRS="-R0/${Time1}/-1/1"

page=0
plot=$(($PLOTPERPAGE_ALL+1))
while read Gcarc
do

	STNM1=`grep -w ${Gcarc} tmpfile1_info | awk 'NR==1 {print $1}'`
	STNM2=`grep -w ${Gcarc} tmpfile2_info | awk 'NR==1 {print $1}'`

	Gcarc=`printf "%.2lf" ${Gcarc}`
	Decon1file=${DeconDIR1}/${EQ1}/${STNM1}.trace
	Decon2file=${DeconDIR2}/${EQ2}/${STNM2}.trace
	frs1file=${FRSDIR1}/${EQ1}_${STNM1}.frs
	frs2file=${FRSDIR2}/${EQ2}_${STNM2}.frs

	## 6.1 check if need to plot on a new page.
	if [ $plot -eq $(($PLOTPERPAGE_ALL+1)) ]
	then

		### 6.2.1 if this isn't first page, seal it (without -K option).
		if [ ${page} -gt 0 ]
		then
			psxy -J -R -O >> ${OUTFILE} << EOF
EOF
		fi

		### 6.2.2. plot titles and legends
		plot=1
		page=$(($page+1))
		OUTFILE="${page}.ps"
		title1="Deconed ScS & FRS Comparison. @;${color[1]};${Marker1}@;;, @;${color[2]};${Marker2}@;;  Page: ${page}"
		title2="H: @;${color[1]};${Thickness_1}@;;, @;${color[2]};${Thickness_2}@;; km.  Vs: @;${color[1]};${Vs_Change_1}@;;, @;${color[2]};${Vs_Change_2}@;;  Rho: @;${color[1]};${Rho_Change_1}@;;, @;${color[2]};${Rho_Change_2}@;;  NSTA: ${NSTA}"
		title3="Time tick interval: ${Tick_A} sec."

		pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
		pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${title2}
EOF
		pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF
		pstext ${PROJFRS} -R-1/1/-1/1 -X`echo ${onethirdwidth}*2 | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title3}
EOF

		psxy -J -R -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
	fi # end the test whether it's a new page.

	### 4.4.0 plot Checkbox.

### 6.6. plot Decon1file waveform and Stretched S esf.
	psxy ${PROJ} ${REGESF} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
	for time in `seq -10 10`
	do
		psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
		psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
	done

	psxy ${Decon1file} ${PROJ} ${REGESF} -W${color[1]} -O -K >> ${OUTFILE}

	### 6.6. plot Decon2file waveform with S esf.
	psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onethirdwidth}i -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
	for time in `seq -10 10`
	do
		psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
		psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
	done

	psxy ${Decon2file} ${PROJ} ${REGESF} -W${color[2]} -O -K >> ${OUTFILE}

### 6.6. plot FRS waveform.
	psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -X${onethirdwidth}i -O -K >> ${OUTFILE} << EOF
0 0
${Time1} 0
>
0 -1
0 1
EOF
	for time in `seq -10 10`
	do
		psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
		psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
0 `echo "${time} * 0.25" | bc -l`
EOF
	done

	pstext ${PROJFRS} ${REGFRS} -O -K >> ${OUTFILE} << EOF
`echo "${Time1} * 0.05" | bc -l` 1 6 0 0 LT FRS
EOF
	psxy ${PROJFRS} ${REGFRS} ${frs1file} -W${color[1]} -O -K >> ${OUTFILE}
	psxy ${PROJFRS} ${REGFRS} ${frs2file} -W${color[2]} -O -K >> ${OUTFILE}

	## 6.4 go to the right position prepare to plot seismograms.
	psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF

	### 6.6. plot Decon waveform.
	psxy ${PROJ2} ${REGESF2} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
-100 0
100 0
>
-100 -1
-100 1
EOF
	for time in `seq -10 10`
	do
		psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
		psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-100 `echo "${time} * 0.5" | bc -l`
EOF
	done

	psvelo -J -R -Wblack -Ggreen -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
0 -0.5 0 0.5
EOF
	psvelo -J -R -Wblack -Gred -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
${Time1} 0.5 0 -0.5
-${Time1} 0.5 0 -0.5
EOF
	psxy ${Decon1file} ${PROJ2} ${REGESF2} -W${color[1]} -O -K >> ${OUTFILE}
	psxy ${Decon2file} ${PROJ2} ${REGESF2} -W${color[2]} -O -K >> ${OUTFILE}

	### 6.6. Info.
	pstext ${PROJFRS} ${REGFRS} -X`echo "2*${onethirdwidth}" | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT @;${color[1]};${STNM1}@;;  @;${color[2]};${STNM2}@;;  gcp=${Gcarc}
EOF

	psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
	plot=$((plot+1))

done < tmpfile_samegcarc # end of plot loop.

# Make PDF.
psxy -J -R -O >> ${OUTFILE} << EOF
EOF
cat `ls *.ps | sort -n` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ1}_${Marker1}_${EQ2}_${Marker2}.pdf

exit 0
