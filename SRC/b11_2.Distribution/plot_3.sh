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

ylabel="ScS_Misfit"
xlabel="S_Misfit"
XINC=1
XNUM=1
YINC=1
YNUM=1

PROJ=-JX${width}i/${height}i
REG="-R-1/2/-1/2"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_Smisfit_ScSmisfit > tmpfile_$$
    gmt psxy tmpfile_$$ ${REG} ${PROJ} -Si0.1i -G${color[${count}]} -O -K >> ${OUTFILE}

done

exit 0
