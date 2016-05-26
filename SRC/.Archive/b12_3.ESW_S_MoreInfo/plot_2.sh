#!/bin/bash


color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

ylabel="${MainPhase} Amplitude."
xlabel="GCP (deg)."
XMIN=55
XMAX=80
XNUM=5
XINC=1
YMIN=0
YMAX=1
YNUM=`echo ${YMAX} | awk '{print $1/5}'`
YINC=`echo ${YNUM} | awk '{print $1/5}'`

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

for cate in `seq 1 ${CateN}`
do
	psxy tmpfile${cate}_gcarc_${MainPhase}amp ${REG} ${PROJ} -Sc0.05i -G${color[$cate]} -Wfaint,black -N -O -K >> ${OUTFILE}

done

exit 0
