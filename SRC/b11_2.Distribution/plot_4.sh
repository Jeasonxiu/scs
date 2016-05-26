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
XMIN=-131
XMAX=-50
XINC=10
XNUM=20
YMIN=10
YMAX=65
YINC=10
YNUM=20

PROJ=-JX${width}i/${height}i
xscale=`echo "${width}/(${XMAX} - ${XMIN})" | bc -l`
yscale=`echo "${height}/(${YMAX} - ${YMIN})" | bc -l`
PROJ1="-Jx${xscale}id/${yscale}id"

REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt pscoast ${REG} ${PROJ1} -Dl -A40000 -W0.5p,black -O -K >> ${OUTFILE}
gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}g${XNUM}f${XINC}:"Longitude":/a${YNUM}g${YNUM}f${YINC}:"Latitude":WS -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_stlo_stla > tmpfile_$$
    gmt psxy tmpfile_$$ ${REG} ${PROJ} -Si0.1i -G${color[${count}]} -N -O -K >> ${OUTFILE}

done

exit 0
