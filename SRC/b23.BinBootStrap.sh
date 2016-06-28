#!/bin/bash

# ===========================================================
# Plot BootStrap results.
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

if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> Run GeoBin first ..."
    exit 1
fi

if ! [ -e ${WORKDIR_BootStrap}/INFILE ]
then
    echo "    !=> Run BootStrap first ..."
    exit 1
fi

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black

BinCenter="-W0.02i,green -S+0.13i"

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"

gmt xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:

# ========================================
#    ! Plot0: Bin Info.
# ========================================

OUTFILE=0.ps

# Count how many pairs are used in binning.
rm -f tmpfile_$$
for file in `ls ${WORKDIR_Geo}/*.grid`
do
	awk 'NR>1 {print $1"_"$2}' ${file} >> tmpfile_$$
done
NSTA=`sort -u tmpfile_$$ | wc -l`

# Title.
cat > tmpfile_$$ << EOF
0 60 FRS bin-BootStrap Info. Pair Num=${NSTA}.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

# Backgrounds.
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# Plot FRS stacks.
keys="<binLon> <binLat>"
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    FRSfile=${WORKDIR_Geo}/${BinN}.frstack
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
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

    # Go back to original.
    gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# ========================================
#    ! Plot1: FRS stack v.s BootStrap.
# ========================================
OUTFILE=1.ps

# Title.
cat > tmpfile_$$ << EOF
0 60 FRS @;red;bin-Stack@;; v.s. bin-BootStrap.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

# Backgrounds.
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# Plot FRS stacks.
keys="<binLon> <binLat>"
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    FRSfile=${WORKDIR_Geo}/${BinN}.frstack
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# BinCenter.
	gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF

    # Amplitude line.
    gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF

    # Amplitude tick.
    gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
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
`echo "${time} * ${Tick_Map}" | bc -l` 0
EOF
    done

    # BootStrap result.
    awk '{print $1,$2}' ${file1} | gmt psxy ${REG1} ${PROJ1} -W0.5p,black -O -K >> ${OUTFILE}

    # FRS stack.
    awk '{print $1,$2}' ${FRSfile} | gmt psxy ${REG1} ${PROJ1} -W0.5p,red -O -K >> ${OUTFILE}

    # Go back to original.
    gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# =========================================================
#    ! Plot2: BootStrap result with Standard deviation.
# =========================================================

OUTFILE=2.ps

# Title.
cat > tmpfile_$$ << EOF
0 60 FRS bin-BootStrap with standard deviation.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

# Backgrounds.
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

keys="<binLon> <binLat>"
# Plot FRS stacks.
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# BinCenter.
	gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF

    # Amplitude line.
    gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF

    # Amplitude tick.
    gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
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
`echo "${time} * ${Tick_Map}" | bc -l` 0
EOF
    done

    # FRS BootStrap stack.
    awk '{print $1,$2}' ${file1} | gmt psxy ${REG1} ${PROJ1} -O -K >> ${OUTFILE}

    # FRS BootStrap std.
    awk '{print $1,$2-$3}' ${file1} | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}
    awk '{print $1,$2+$3}' ${file1} | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}


    # Go back to original.
    gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# =========================================================
#    ! Plot3: FRS BootStrap with Upper / Lower Bound !
# =========================================================
OUTFILE=3.ps

# Title.
cat > tmpfile_$$ << EOF
0 60 FRS bin-BootStrap with Upper/Lower Bound.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

# Backgrounds.
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# Plot FRS stacks.
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

	# BinCenter.
	gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF

    # Amplitude line.
    gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF

    # Amplitude tick.
    gmt psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
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
`echo "${time} * ${Tick_Map}" | bc -l` 0
EOF
    done

    # FRS stack.
    awk '{print $1,$2}' ${file1} | gmt psxy ${REG1} ${PROJ1} -Wpurple -O -K >> ${OUTFILE}

    # FRS stack Upper & Lower Bound.
    awk '{print $1,$4}' ${file1} | gmt psxy ${REG1} ${PROJ1} -Wblue -O -K >> ${OUTFILE}
    awk '{print $1,$5}' ${file1} | gmt psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}

    # Go back to original.
    gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# ====================================
#     ! Plot4: Lower bound > 0 !
# ====================================
ls ${WORKDIR_BootStrap}/*bootSig_low >/dev/null 2>&1

if [ $? -eq 0 ]
then

    OUTFILE=4.ps

	# Title.
	cat > tmpfile_$$ << EOF
0 60 FRS bin-BootStrap with Lower Bound > 0.
EOF
	# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

	# Backgrounds.
    gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
    gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
	gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

    # Plot FRS stacks.
    for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
    do
        BinN=${file%.*}
        BinN=${BinN##*/}

        NR=`wc -l < ${file} | awk '{print $1-1}'`
        INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
        lon=`echo ${INFO} | awk '{print $1}'`
        lat=`echo ${INFO} | awk '{print $2}'`

        if [ -e ${WORKDIR_BootStrap}/${BinN}.bootSig_low ]
        then
            file1=${WORKDIR_BootStrap}/${BinN}.bootSig_low
        else
            continue
        fi

        # Go to right position.
        gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF
        # Amplitude line.
#         psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
# 0 -1
# 0 1
# EOF
        # Amplitude tick.
#         psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
# 0 -0.5
# 0 0.5
# EOF
        # Time zero line.
        gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
        # Time tick.
        for time in `seq -5 5`
        do
            gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_Map}" | bc -l` 0
EOF
        done

        # Lower Bound > 0
        tac ${file1} | awk '{print $1,0}' > tmpfile_$$
        awk '{print $1,2*$2}' ${file1} >> tmpfile_$$
        gmt psxy tmpfile_$$ ${REG1} ${PROJ1} -Gred -L -O -K >> ${OUTFILE}

        # CMB position.
        gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF
        # Go back to origin.
        gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

    done

    gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

fi # if there is an lower bound greater than 0.

# ====================================
#     ! Plot5: Upper bound < 0 !
# ====================================
ls ${WORKDIR_BootStrap}/*bootSig_high >/dev/null 2>&1

if [ $? -eq 0 ]
then

    OUTFILE=5.ps

	# Title.
	cat > tmpfile_$$ << EOF
0 60 FRS bin-BootStrap with Upper Bound < 0.
EOF
	# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}

    gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
    gmt psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -O -K >> ${OUTFILE}
	gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

    # Plot FRS stacks.
    for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
    do
        BinN=${file%.*}
        BinN=${BinN##*/}

        NR=`wc -l < ${file} | awk '{print $1-1}'`
        INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
        lon=`echo ${INFO} | awk '{print $1}'`
        lat=`echo ${INFO} | awk '{print $2}'`

        if [ -e ${WORKDIR_BootStrap}/${BinN}.bootSig_high ]
        then
            file1=${WORKDIR_BootStrap}/${BinN}.bootSig_high
        else
            continue
        fi

        # Go to right position.
        gmt psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF
#         # Amplitude line.
#         psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
# 0 -1
# 0 1
# EOF
#         # Amplitude tick.
#         psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
# 0 -0.5
# 0 0.5
# EOF
        # Time zero line.
        gmt psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
        # Time tick.
        for time in `seq -5 5`
        do
            gmt psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_Map}" | bc -l` 0
EOF
        done

        # Upper Bound < 0
        tac ${file1} | awk '{print $1,0}' > tmpfile_$$
        awk '{print $1,2*$2}' ${file1} >> tmpfile_$$
        gmt psxy tmpfile_$$ ${REG1} ${PROJ1} -Gblue -L -O -K >> ${OUTFILE}

        # CMB position.
        gmt psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 0
EOF
        # Go back to origin.
        gmt psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

    done

    gmt psxy -R -J -O >> ${OUTFILE} << EOF
EOF

fi # if there is an upper bound smaller than 0.

# ====================================
#     ! Make PDF !
# ====================================
Title=`basename $0`
cat `ls -rt *.ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
