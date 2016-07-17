#!/bin/bash

# ===========================================================
# Plot ScS/S Amp Ratio, Data verses Radiation predicton.
#
# Shule Yu
# Jul 14 2016
# ===========================================================


echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

YMOVE="8.1"
PLOTVERTIC="7.5"
PLOTHORIZ="10"
height=`echo "${PLOTVERTIC}*0.95" | bc -l`
width=`echo "${PLOTHORIZ}*0.95" | bc -l`

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 10p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.25p,gray,-

xlabel="Radiation pattern predicted ScS/S"
XMIN=0
XMAX=2
XINC="0.25"
XNUM="0.25"
ylabel="Data ScS/S"
YMIN=0
YMAX=2
YINC="0.25"
YNUM="0.25"

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

for EQ in ${EQnames}
do
    # CMT info.
    CMT=`grep ${EQ} ${CMTINFO} | awk 'NR==1 {print $0}'`
	strike=`echo "${CMT}" | awk '{print $3}'`
	dip=`echo "${CMT}" | awk '{print $4}'`
	rake=`echo "${CMT}" | awk '{print $5}'`

    # Gather information.
	mysql -N -u shule ${DB} > tmpfile_rad_data << EOF
select Rad_Pat_ScS/Rad_Pat_S,Amp_ScS/Amp_S from Master_a21 where eq=${EQ} and wantit=1;
EOF

    # Plot Begin.
	OUTFILE=${EQ}.ps

	title="${EQ} ScS/S Amplitude. Data v.s. Prediction."
	cat > tmpfile_$$ << EOF
0 0 ${title}
EOF
	gmt pstext tmpfile_$$ -F+jCB+f16p -JX${PLOTHORIZ}i/0.3i -R-1/1/-1/1 -Xf0.65i -Yf${YMOVE}i -N -K > ${OUTFILE}



	gmt psxy -J -R -Xf0.75i -Y-${PLOTVERTIC}i -O -K >> ${OUTFILE} << EOF
EOF
	gmt psxy tmpfile_rad_data ${REG} ${PROJ} -Ba${XNUM}g${XINC}:"${xlabel}":/a${YNUM}g${YINC}:"${ylabel}":WS -Sc0.05i -Gblack -N -O -K >> ${OUTFILE}

	# Seal it.
	rm -f tmpfile*
	gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # done EQ loop.

# Make PDF.
Title=${0}
Title=${Title%/plot.sh}
Title=${Title##*/}
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title}.pdf

cd ${WORKDIR}

exit 0
