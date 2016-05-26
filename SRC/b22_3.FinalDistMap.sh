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
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c

# ================================================
#         ! Make Data Info !
# ================================================

mysql -N -u shule ${DB} > tmpfile_hitlo_hitla_gcarc << EOF
select hitlo,hitla,shift_gcarc from Master_a21 where wantit=1;
EOF
minval=`minmax -C tmpfile_hitlo_hitla_gcarc | awk '{print $5}'`
maxval=`minmax -C tmpfile_hitlo_hitla_gcarc | awk '{print $6}'`
makecpt -I -Cseis -T${minval}/${maxval}/`echo "${maxval} ${minval}" | awk '{print ($1-$2)/8}'` -Z >> tmpfile.cpt

# ==============================
#   ! Plot !
# ==============================

OUTFILE=tmp.ps
REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

psbasemap ${REG} ${PROJ} -Ba5f1:"Longitude":/a5f1:"Latitude":WS -K > ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}
psxy tmpfile_hitlo_hitla_gcarc ${REG} ${PROJ} -Sc0.05i -Ctmpfile.cpt -O -K >> ${OUTFILE}
psscale -Ctmpfile.cpt -D`echo ${PLOTWIDTH_Map} | awk '{print $1+1.5}'`i/`echo "${PLOTHEIGHT_Map}" | awk '{print $1*0.382}'`i/2.5i/0.13ih -B:"GCP Distance (500km Deep)": -N300 -O >> ${OUTFILE}


# Make PDF.
Title=`basename $0`
ps2pdf ${OUTFILE} ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${CODEDIR}

exit 0
