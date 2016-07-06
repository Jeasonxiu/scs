#!/bin/bash

# ================================================================
# Plot Histogram of the gcarc of all earthquakes.
# Pull information from Master_a21.
#
# Shule Yu
# Apr 27 2016
# ================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 20p
gmt gmtset MAP_LABEL_OFFSET 10p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.5p,gray,-

# Histogram parameters.

XMAX=${D2_FRS}
XMIN=${D1_FRS}
XINC="1"

# ================================================
#         ! Check calculation result !
# ================================================

OUTFILE=tmp.ps

# Gathering Information.

mysql -N -u shule ${DB} > histo.dat << EOF
select SHIFT_GCARC from Master_a21 where wantit=1;
EOF

#==========  x axis ==========
binN=`echo "(${XMAX}-${XMIN})/${XINC}" | bc`
XMAX=`echo "${XMIN} ${XINC} ${binN}" | awk '{print $1+$2*$3}'`

#==========  y axis ==========
gmt pshistogram histo.dat -R${XMIN}/${XMAX}/0/1 -W${XINC} -IO > tmpfile_$$
YMAX=`minmax -C tmpfile_$$ | awk '{print 1.2*$4+10 }'`
YMAX=`echo "${YMAX}/10*10" | bc`
YNUM=`echo "${YMAX}/5" | bc`
YINC=`echo "${YNUM}/2" | bc`

#==========  some text  ==========
cat > tmpfile_$$  << EOF
0 1.1 Final Gcarc Histogram. NR=`wc -l < histo.dat`
EOF
gmt pstext tmpfile_$$ -JX9i/6.5i -R-1/1/-1/1 -F+jCB+f20p -N -K > ${OUTFILE}

#==========  plot histogram ==========
AXIS="-Ba`echo ${XINC} | awk '{print $1*2}'`:Weight:/a${YINC}g${YINC}:Freq:WS"
gmt psbasemap -R${XMIN}/`echo ${XMAX} ${XINC} | awk '{print $1+$2}'`/0/${YMAX} -JX9i/6.5i ${AXIS} -O -K >> ${OUTFILE}
gmt pshistogram histo.dat -R -J -W${XINC} -L0.5p -Gblue -O >> ${OUTFILE}

# Make PDF.
Title=`basename $0`
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

rm -rf ${WORKDIR_Plot}/tmpdir_$$

exit 0
