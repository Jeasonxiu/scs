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

ylabel="Azimuth."
xlabel="Gcarc."
XINC=1
XNUM=5
YMIN=290
YMAX=370
YINC=5
YNUM=10

PROJ=-JX${width}i/${height}i
REG="-R${DISTMIN}/${DISTMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_gcarc_az > tmpfile_$$
    gmt psxy tmpfile_$$ ${REG} ${PROJ} -St0.1i -G${color[${count}]} -N -O -K >> ${OUTFILE}

done

exit 0
