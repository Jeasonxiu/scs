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


# ==========================================
#   ! First plot, the original bins  !
# ==========================================

OUTFILE=1.ps

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -Wblack -O -K >> ${OUTFILE}

# Plot bouncing points.
mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select hitlo,hitla from Master_a21 where wantit=1;
EOF
psxy tmpfile_$$ -R -J -Sc0.03i -Gblack -O -K >> ${OUTFILE}

# Plot bin circles.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    BinN=${file%.*}
    BinN=${BinN##*/}

    keys="<binR> <binLon_Before> <binLat_Before>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    Radius=`echo ${INFO} | awk '{print $1}'`
    binLon_Before=`echo ${INFO} | awk '{print $2}'`
    binLat_Before=`echo ${INFO} | awk '{print $3}'`

    psxy ${BinN}.circle.before -R -J -L -Wred -O -K >> ${OUTFILE}
    psxy -R -J ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
${binLon_Before} ${binLat_Before}
EOF
    pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${binLon_Before}-0.1" | bc -l` `echo "${binLat_Before}-0.1" | bc -l` 7 0 0 RT ${BinN}
`echo "${binLon_Before}+0.1" | bc -l` `echo "${binLat_Before}-0.1" | bc -l` 7 0 0 LT ${NR}
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# ==========================================
#   ! Second plot, the shifted bins  !
# ==========================================

OUTFILE=2.ps

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -Wblack -O -K >> ${OUTFILE}

# Plot bouncing points.
mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select hitlo,hitla from Master_a21 where wantit=1;
EOF
psxy tmpfile_$$ -R -J -Sc0.03i -Gblack -O -K >> ${OUTFILE}

# Plot bin circles.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    BinN=${file%.*}
    BinN=${BinN##*/}

    keys="<binR> <binLon> <binLat>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    Radius=`echo ${INFO} | awk '{print $1}'`
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
