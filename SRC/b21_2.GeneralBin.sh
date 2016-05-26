#!/bin/bash

# ===========================================================
# Plot Geographic bin results.
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
    echo "    !=> `basename $0`: Run GeoBin first ..."
    exit 1
fi

echo "    ==> Ploting geographic map from FRS stacking."

# Plot parameters.

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.1p,200/200/200,-

BinCenter="-W0.02i,green -S+0.13i"

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=orange
color[10]=pink
color[11]=magenta
color[12]=yellow
color[13]=navy

shape[1]="a"
shape[2]="+"
shape[3]="c"
shape[4]="d"
shape[5]="g"
shape[6]="i"
shape[7]="h"
shape[8]="n"
shape[9]="t"
shape[10]="s"
shape[11]="x"
shape[12]="-"
shape[13]="y"


# =====================================================
#   ! Bin Boundary and color coded sampling poition  !
# =====================================================

OUTFILE=1.ps

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -Wblack -O -K >> ${OUTFILE}

# Plot bin edge.
for file in `ls ${WORKDIR_Geo}/*.bin`
do
	psxy -R -J ${file} -Wblack,- -L -N -O -K >> ${OUTFILE}
done

# Plot valid bin.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    BinN=${file%.*}
    BinN=${BinN##*/}

	# Plot sampling points.
	keys="<Hitlo> <Hitla>"
	${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_$$
	Cnt=`echo "${BinN}%13+1"|bc`
	psxy tmpfile_$$ -R -J -S${shape[${Cnt}]}0.03i -G${color[${Cnt}]} -O -K >> ${OUTFILE}

	# Plot bin center.
    keys="<binR> <binLon> <binLat>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    binLon=`echo ${INFO} | awk '{print $2}'`
    binLat=`echo ${INFO} | awk '{print $3}'`
    psxy -R -J ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
${binLon} ${binLat}
EOF
    pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${binLon}-0.1" | bc -l` `echo "${binLat}-0.1" | bc -l` 7 0 0 RT ${BinN}
`echo "${binLon}+0.1" | bc -l` `echo "${binLat}-0.1" | bc -l` 7 0 0 LT ${NR}
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
