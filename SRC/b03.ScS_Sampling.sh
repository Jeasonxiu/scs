#!/bin/bash

# ===========================================================
# Plot ScS sampling location on a global map.
#
# Shule Yu
# Nov 10 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.5p,gray,-
gmt gmtset COLOR_NAN white
gmt gmtset COLOR_BACKGROUND black
gmt gmtset COLOR_FOREGROUND white


# Gather information.
mysql -N -u shule ${DB} > tmpfile_EQs << EOF
select distinct evlo,evla from Master_a03 where wantit=1;
EOF

mysql -N -u shule ${DB} > tmpfile_Stations << EOF
select distinct stlo,stla from Master_a03 where wantit=1;
EOF

mysql -N -u shule ${DB} > tmpfile_bounce << EOF
select distinct hitlo,hitla from Master_a03 where wantit=1;
EOF

echo "select count(*) from Master_a03 where wantit=1;" > tmpfile_$$
NSTA=`mysql -N -u shule ${DB} < tmpfile_$$`

# Plot.
OUTFILE=AllScS.ps
echo "    ==> Total traces: ${NSTA}."


# title.
cat > tmpfile_$$ << EOF
0 0 ScS Sampling locations. Event-Station Pair: ${NSTA}
EOF
gmt pstext tmpfile_$$ -R-1/1/-1/1 -JX${PLOTWIDTH_Data}i/1i -F+jCB+f14p,1,black -Y10i -N -P -K > ${OUTFILE}

REG="-R-180/180/-90/90"
PROJ="-JR180/6.5i"

# 1. Tomography S20.
gmt xyz2grd ${BASHCODEDIR}/S40RTS.2800 -G2880.grd -I2 ${REG} -:
gmt grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -Y-4i -O -K >> ${OUTFILE} 2>/dev/null
gmt psscale -C${BASHCODEDIR}/ritsema.cpt -D2i/-0.2i/3.0i/0.13ih -B2/:"@~\144@~Vs (%)": -N300 -O -K >> ${OUTFILE}
gmt pscoast ${REG} ${PROJ} -Dl -A40000 -W0.5p,black -O -K >> ${OUTFILE}

# 2. Distribution.
gmt psxy tmpfile_bounce ${PROJ} ${REG} -Sc0.01i -Gyellow -O -K >> ${OUTFILE}
gmt psxy tmpfile_EQs ${PROJ} ${REG} -Sa0.1i -Gred -O -K >> ${OUTFILE}
gmt psxy tmpfile_Stations ${PROJ} ${REG} -Si0.03i -Gblue -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba60g60/a45g45 -O -K >> ${OUTFILE}

# 4. Color scale, hit count.
${EXECDIR}/CountGrid.out 0 2 6 << EOF
tmpfile_bounce
tmpfile_bounce_grid
-180
180
2
-90
90
2
EOF

if [ $? -ne 0 ]
then
	echo "    !=> CountGrid.out failed..."
	exit 1
fi

MINVAL=`minmax -C tmpfile_bounce_grid | awk '{print $5}'`
MAXVAL=`minmax -C tmpfile_bounce_grid | awk '{print $6}'`

gmt makecpt -I -Chot -M -T${MINVAL}/${MAXVAL}/`echo "(${MAXVAL}-${MINVAL})/10" | bc -l` -Z > tmpfile.cpt
gmt xyz2grd tmpfile_bounce_grid -Gtmp.grd -I2 ${REG} -di0
gmt grdimage tmp.grd -Ctmpfile.cpt ${REG} ${PROJ} -Y-4.8i -E40 -O -K >> ${OUTFILE} 2>/dev/null
gmt pscoast ${REG} ${PROJ}  -Dl -A40000 -W0.5p,black -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba60g60/a45g45 -O -K >> ${OUTFILE}
gmt psscale -Ctmpfile.cpt -D1.8i/-0.3i/3.0i/0.13ih -B`echo "(${MAXVAL}-${MINVAL})/10" | bc`/:"Hit Count": -N300 -O -K >> ${OUTFILE}

# Make PDF.
gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

Title=`basename $0`
cat `ls -rt *ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${WORKDIR}

exit 0
