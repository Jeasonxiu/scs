#!/bin/bash

# ===========================================================
# Plot Geographic bin stack results.
#
# Shule Yu
# Oct 27 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

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

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=yellow

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.1p,200/200/200,-

BinCenter="-Gblack -Sc0.07i"

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map} ${LOMAX} ${LOMIN}" | awk '{print ($1/($2-$3))}'`
yscale=`echo "${PLOTHEIGHT_Map} ${LAMAX} ${LAMIN}" | awk '{print ($1/($2-$3))}'`
PROJ="-Jx${xscale}i/${yscale}i"

# ==============================
#   ! Make Circls for plots !
# ==============================

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    BinN=${file%.*}
    BinN=${BinN##*/}

    keys="<binR> <binLon> <binLat> <binLon_Before> <binLat_Before>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    Radius=`echo ${INFO} | awk '{print $1}'`
    binLon=`echo ${INFO} | awk '{print $2}'`
    binLat=`echo ${INFO} | awk '{print $3}'`
    binLon_Before=`echo ${INFO} | awk '{print $4}'`
    binLat_Before=`echo ${INFO} | awk '{print $5}'`

    ${EXECDIR}/circle.out ${binLon} ${binLat} ${Radius} > ${BinN}.circle
    ${EXECDIR}/circle.out ${binLon_Before} ${binLat_Before} ${Radius} > ${BinN}.circle.before

done

# ==============================
#   ! Plot2: FRS stack !
# ==============================
OUTFILE=1.ps

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"

AMP=1

xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:

# Grid line basemap:
# psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}

# No grid line basemap:
psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5:"Longitude":/a${LAINC}f0.5:"Latitude":WS -K > ${OUTFILE}

# grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
# pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# Plot scale.

psxy -R -J -X`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

# Amplitude line.
psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
# Amplitude tick.
psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
EOF
# Amplitude mark.
pstext -R -J -N -O -K >> ${OUTFILE} << EOF
0 -1   5 0 0 RB -${AMP}
0 -0.5 5 0 0 RB `echo "${AMP}" | awk '{print -$1/2}'`
0 0    5 0 0 RB 0
0 0.5 5 0 0 RB `echo "${AMP}" | awk '{print $1/2}'`
0 1   5 0 0 RB ${AMP}
EOF

# Time zero line.
psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

# Time tick / mark.
for time in `seq -5 5`
do
    psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
done

psxy -R -J -O -K -X-`echo "-70 ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "22 ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

# Plot bouncing points.
keys="<HITLO> <HITLA>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_Geo}/INFO "${keys}" | sort -u > tmpfile_$$
psxy ${REG} ${PROJ} tmpfile_$$ -Sc0.03i -Ggray -O -K >> ${OUTFILE}

# Plot bin circles.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    BinN=${file%.*}
    BinN=${BinN##*/}
    psxy ${BinN}.circle -R -J -L -Wgray -O -K >> ${OUTFILE}
done

# Plot FRS stacks.

for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
do
    BinN=${file%.*}
    BinN=${BinN##*/}
    NR=`wc -l < ${file} | awk '{print $1-1}'`

	keys="<binLon> <binLat>"
	${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1 > tmpfile_$$

    lon=`awk '{print $1}' tmpfile_$$`
    lat=`awk '{print $2}' tmpfile_$$`

    # Go to bin position.
    psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    # Time zero line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

    # Time tick.
    for time in `seq -5 5`
    do
    psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
    done

    # CMB position.
    psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF

    # FRS stack.
    awk -v A=${AMP} '{print $1,$2/A}' ${WORKDIR_Geo}/${BinN}.frstack > tmpfile_plotdata
    Cate=`awk -v B=${BinN} '{if ($1==B) print $2}' ${WORKDIR_Cluster}/Grid_Cate`
    psxy tmpfile_plotdata ${REG1} ${PROJ1} -W1p,${color[${Cate}]} -O -K >> ${OUTFILE}

    # Go back to original.
    psxy -R -J -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} -O -K << EOF
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# Make PDF.
cat `ls *.ps | sort -n` > tmpfile.ps

ps2pdf tmpfile.ps ${WORKDIR_Plot}/ClusterFRS.pdf
cp tmpfile.ps ${WORKDIR_Plot}/ClusterFRS.ps

exit 0
