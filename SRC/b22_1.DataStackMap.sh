#!/bin/bash

# ===========================================================
# Plot Geographic bin stack results.
#
# Shule Yu
# Oct 27 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# ===============================================
#     ! Check the calculation results !
# ===============================================

if ! [ -e ${WORKDIR_FRS}/INFILE ]
then
    echo "    ==> `basename $0`: Run FRS first ..."
    exit 1
fi

if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    ==> `basename $0`: Run GeoBin first ..."
    exit 1
fi

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black

BinCenter="-W0.02i,green -S+0.13i"

# Count how many pairs are used in binning.
rm -f tmpfile_$$
for file in `ls ${WORKDIR_Geo}/*.grid`
do
	awk 'NR>1 {print $1"_"$2}' ${file} >> tmpfile_$$
done
NSTA=`sort -u tmpfile_$$ | wc -l`


REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"
gmt xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:

# Decide amplitude.
AMP1="1"
AMP2="0.5"
AMP3=0
for file in `ls ${WORKDIR_Geo}/*.frstack`
do
	AMP3=`minmax -C ${file} | awk -v A=${AMP3} '{ if (-$3>$4 && -$3>A) print -$3 ; else if ($4>-$3 && $4>A) print $4; else print A}'`
done

# ==================================
#   ! Plot0: FRS stack Info !
# ==================================

OUTFILE=tmp.ps

# Title.
cat > tmpfile_$$ << EOF
0 60 FRS bin stack Info. Pair Num=${NSTA}.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

# Backgrounds.
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# FRS Info.

for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
do
	BinN=${file%.*}
	BinN=${BinN##*/}

	keys="<binLon> <binLat>"
	INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
	binLon=`echo ${INFO} | awk '{print $1}'`
	binLat=`echo ${INFO} | awk '{print $2}'`

	NR=`wc -l < ${file} | awk '{print $1-1}'`

	# Go to right position.
	gmt psxy -R -J -X`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF
	# BinCenter.
	gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF
	# Info.

	cat > tmpfile_$$ << EOF
0 0 #${BinN}, ${NR}.
EOF
	gmt pstext tmpfile_$$ -J -R -F+jLM+f7p,0,black -N -O -K >> ${OUTFILE}

	# Go back.
	gmt psxy -R -J -X-`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

done # Done FRS loop.

gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

for AMP in ${AMP1} ${AMP2} ${AMP3}
do

	# ==============================
	#   ! Plot1: FRS stack !
	# ==============================

	OUTFILE=tmp_${AMP}_1.ps

	# Title.
	cat > tmpfile_$$ << EOF
0 60 FRS bin stack. Pair Num=${NSTA}.
EOF
	# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

	# Backgrounds.
	gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
	gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
	gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

	# Plot scale bar at leftup corner.
	gmt psxy -R -J -X`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# Amplitude line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
	# Amplitude tick.
	gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 1
0 0.5
0 -0.5
0 -1
EOF
	# Amplitude mark.
	cat > tmpfile_$$ << EOF
-0.7 -1   `echo "${AMP}" | awk '{printf "%.2f",-$1}'`
-0.7 -0.5 `echo "${AMP}" | awk '{printf "%.2f",-$1/2}'`
-0.7 0    0.00
-0.7 0.5  `echo "${AMP}" | awk '{printf "%.2f",$1/2}'`
-0.7 1    `echo "${AMP}" | awk '{printf "%.2f",$1}'`
-0.7 1.5  (Relative to ScS Peak)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jRM+f5p,0,black -N -O -K >> ${OUTFILE}


	# Time zero line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
	# Time tick / mark.
	for time in `seq -5 5`
	do
		gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
	done
	# Time mark.
	cat > tmpfile_$$ << EOF
`echo "${Time}" | awk '{printf "%.2f",$1/3}'`   -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*2}'` -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3*2}'`
`echo "${Time}" | awk '{printf "%.2f",$1}'`     -0.2   `echo "${Time}" | awk '{printf "%.0f",$1}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*4}'` -0.2   (sec.)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jCT+f5p,0,black -N -O -K >> ${OUTFILE}

	gmt psxy -R -J -O -K -X-`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

	# FRS stacks.

	for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
	do
		BinN=${file%.*}
		BinN=${BinN##*/}

		keys="<binLon> <binLat>"
		INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
		binLon=`echo ${INFO} | awk '{print $1}'`
		binLat=`echo ${INFO} | awk '{print $2}'`

		# Go to right position.
		gmt psxy -R -J -X`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

		# BinCenter.
		gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF

		# Time zero line.
		gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

		# Time tick.
		for time in `seq -5 5`
		do
			gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
		done

		# FRS stack.
		awk -v A=${AMP} '{print $1,$2/A}' ${WORKDIR_Geo}/${BinN}.frstack | gmt psxy ${REG1} ${PROJ1} -W1p,black -O -K >> ${OUTFILE}

		# Go back.
		gmt psxy -R -J -X-`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	done # Done FRS loop.

	gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

	# ==================================
	#   ! Plot2: FRS stack with STD !
	# ==================================

	OUTFILE=tmp_${AMP}_2.ps

	# Title.
	cat > tmpfile_$$ << EOF
0 60 FRS bin stack & standard deviatin. Pair Num=${NSTA}.
EOF
	# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

	# Backgrounds.
	gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
	gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
	gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

	# Plot scale bar at leftup corner.
	gmt psxy -R -J -X`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# Amplitude line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
	# Amplitude tick.
	gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 1
0 0.5
0 -0.5
0 -1
EOF
	# Amplitude mark.
	cat > tmpfile_$$ << EOF
-0.7 -1   `echo "${AMP}" | awk '{printf "%.2f",-$1}'`
-0.7 -0.5 `echo "${AMP}" | awk '{printf "%.2f",-$1/2}'`
-0.7 0    0.00
-0.7 0.5  `echo "${AMP}" | awk '{printf "%.2f",$1/2}'`
-0.7 1    `echo "${AMP}" | awk '{printf "%.2f",$1}'`
-0.7 1.5  (Relative to ScS Peak)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jRM+f5p,0,black -N -O -K >> ${OUTFILE}


	# Time zero line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
	# Time tick / mark.
	for time in `seq -5 5`
	do
		gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
	done
	# Time mark.
	cat > tmpfile_$$ << EOF
`echo "${Time}" | awk '{printf "%.2f",$1/3}'`   -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*2}'` -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3*2}'`
`echo "${Time}" | awk '{printf "%.2f",$1}'`     -0.2   `echo "${Time}" | awk '{printf "%.0f",$1}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*4}'` -0.2   (sec.)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jCT+f5p,0,black -N -O -K >> ${OUTFILE}

	gmt psxy -R -J -O -K -X-`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

	# FRS stacks & STD.

	for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
	do
		BinN=${file%.*}
		BinN=${BinN##*/}

		keys="<binR> <binLon> <binLat>"
		INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
		binLon=`echo ${INFO} | awk '{print $2}'`
		binLat=`echo ${INFO} | awk '{print $3}'`

		# Go to right position.
		gmt psxy -R -J -X`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF


		# Time zero line.
		gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

		# Time tick.
		for time in `seq -5 5`
		do
			gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
		done

		# FRS stack.
		awk -v A=${AMP} '{print $1,$2/A}' ${WORKDIR_Geo}/${BinN}.frstack | gmt psxy ${REG1} ${PROJ1} -W1p,black -O -K >> ${OUTFILE}

		# STD.
		awk -v A=${AMP} '{print $1,($2-$3)/A}' ${WORKDIR_Geo}/${BinN}.frstack | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}
		awk -v A=${AMP} '{print $1,($2+$3)/A}' ${WORKDIR_Geo}/${BinN}.frstack | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}

		# Go back.
		gmt psxy -R -J -O -K -X-`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

	done # Done FRS loop.

	gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF


	# ============================
	#     ! Plot3: STD > 0 !
	# ============================

	ls ${WORKDIR_Geo}/*stackSig >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		continue
	fi

	OUTFILE=tmp_${AMP}_3.ps

	# Title.
	cat > tmpfile_$$ << EOF
0 60 FRS bin stack with lower STD>`echo ${StdSig} | awk '{printf "%.0f",$1*100}'`%. Pair Num=${NSTA}.
EOF
	# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

	# Backgrounds.
	gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
	gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
	gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

	# Plot scale bar at leftup corner.
	gmt psxy -R -J -X`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# Amplitude line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
	# Amplitude tick.
	gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 1
0 0.5
0 -0.5
0 -1
EOF
	# Amplitude mark.
	cat > tmpfile_$$ << EOF
-0.7 -1   `echo "${AMP}" | awk '{printf "%.2f",-$1}'`
-0.7 -0.5 `echo "${AMP}" | awk '{printf "%.2f",-$1/2}'`
-0.7 0    0.00
-0.7 0.5  `echo "${AMP}" | awk '{printf "%.2f",$1/2}'`
-0.7 1    `echo "${AMP}" | awk '{printf "%.2f",$1}'`
-0.7 1.5  (Relative to ScS Peak)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jRM+f5p,0,black -N -O -K >> ${OUTFILE}


	# Time zero line.
	gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
	# Time tick / mark.
	for time in `seq -5 5`
	do
		gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
	done
	# Time mark.
	cat > tmpfile_$$ << EOF
`echo "${Time}" | awk '{printf "%.2f",$1/3}'`   -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*2}'` -0.2   `echo "${Time}" | awk '{printf "%.0f",$1/3*2}'`
`echo "${Time}" | awk '{printf "%.2f",$1}'`     -0.2   `echo "${Time}" | awk '{printf "%.0f",$1}'`
`echo "${Time}" | awk '{printf "%.2f",$1/3*4}'` -0.2   (sec.)
EOF
	gmt pstext tmpfile_$$ -J -R -F+jCT+f5p,0,black -N -O -K >> ${OUTFILE}

	gmt psxy -R -J -O -K -X-`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

    # FRS STD>5%.

    for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
    do
        BinN=${file%.*}
        BinN=${BinN##*/}

        keys="<binR> <binLon> <binLat>"
        INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
        binLon=`echo ${INFO} | awk '{print $2}'`
        binLat=`echo ${INFO} | awk '{print $3}'`

        if ! [ -e ${WORKDIR_Geo}/${BinN}.stackSig ]
        then
			continue
		fi

		# Go to right position.
		gmt psxy -R -J -X`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

		# Time zero line.
		gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
		# Time tick.
		for time in `seq -5 5`
		do
			gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
		done

		# STD > 5%.
		awk -v A=${AMP} '{print $1,$2/A}' ${WORKDIR_Geo}/${BinN}.stackSig | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}

		# Go back.
		gmt psxy -R -J -X-`echo "${binLon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${binLat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	done # Done FRS loop.

	gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # Done AMP loop.

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
