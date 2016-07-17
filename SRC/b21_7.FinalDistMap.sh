#!/bin/bash

# =============================================================
# Plot Final Selection Earthquake-Station GCP distribution Map.
#
# Shule Yu
# Jan 13 2016
# =============================================================

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
	echo "    !=> In `basename $0` No Selected Traces ... "
	exit 1
fi

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black

# ================================================
#         ! Make Data Info !
# ================================================

mysql -N -u shule ${DB} > tmpfile_hitlo_hitla_gcarc << EOF
select hitlo,hitla,shift_gcarc from Master_a21 where wantit=1;
EOF
minval=`minmax -C tmpfile_hitlo_hitla_gcarc | awk '{printf "%d",$5/5}' | awk '{print $1*5}'`
maxval=`minmax -C tmpfile_hitlo_hitla_gcarc | awk '{printf "%d",$6/5}' | awk '{print ($1+1)*5}'`
INCNUM=`echo ${maxval} ${minval} | awk '{print ($1-$2)/5}'`

gmt makecpt -I -Cseis -T45/80/5 -Z >> tmpfile.cpt
# gmt makecpt -I -Cseis -T${minval}/${maxval}/`echo "${maxval} ${minval} ${INCNUM}" | awk '{print ($1-$2)/$3}'` -Z >> tmpfile.cpt
NSTA=`wc -l < tmpfile_hitlo_hitla_gcarc`

# ==============================
#   ! Plot !
# ==============================

OUTFILE=tmp.ps
REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"


# Title.
cat > tmpfile_$$ << EOF
0 60 Gcarc Distribution. Pair Num=${NSTA}.
EOF
# -Ba10g10/a10f10
gmt pstext tmpfile_$$ -JX6.9i/10i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf1.5i -P -K > ${OUTFILE}


${EXECDIR}/RandIt.out 0 2 0 << EOF
tmpfile_hitlo_hitla_gcarc
tmpfile_$$
EOF

gmt psbasemap ${REG} ${PROJ} -Ba5f1:"Longitude":/a5f1:"Latitude":WS -O -K >> ${OUTFILE}
gmt pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}
gmt psxy tmpfile_$$ ${REG} ${PROJ} -Sc0.05i -Ctmpfile.cpt -O -K >> ${OUTFILE}
gmt psscale -Ctmpfile.cpt -D`echo ${PLOTWIDTH_Map} | awk '{print $1/2}'`i/-0.5i/5i/0.13ih -B:"GCP Distance (Shifted to 500km)": -N300 -O >> ${OUTFILE}


# Make PDF.
Title=`basename $0`
ps2pdf ${OUTFILE} ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${WORKDIR}

exit 0
