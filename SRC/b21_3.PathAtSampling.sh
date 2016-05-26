#!/bin/bash

# ===========================================================
# Plot Geographic bin results.
#
# Shule Yu
# Feb 11 2016
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

echo "    ==> Ploting geographic map from FRS stacking."

# Plot parameters.

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.1p,200/200/200,-

# ==========================================
#   ! Plot the corridor !
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

# Plot path.
mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select EQ,STNM from Master_a21 where wantit=1;
EOF

while read EQ STNM
do
	file=`ls ${WORKDIR_Sampling}/${EQ}_${STNM}_${MainPhase}.path`
	if ! [ -e ${file} ]
	then
		continue
	fi

	awk '{if ($3>2870) print $1,$2}' ${file} | psxy -J -R -O -K >> ${OUTFILE}

done <  tmpfile_$$

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
