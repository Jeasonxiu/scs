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

XMAX=1
XMIN=0
XINC="0.025"

#==========  x axis ==========
binN=`echo "(${XMAX}-${XMIN})/${XINC}" | bc`
XMAX=`echo "${XMIN} ${XINC} ${binN}" | awk '{print $1+$2*$3}'`

#==========  y axis ==========
awk '{print $3}' tmpfile_master10_info > histo.dat
gmt pshistogram histo.dat -R${XMIN}/${XMAX}/0/1 -W${XINC} -IO > tmpfile_$$
YMAX=`minmax -C tmpfile_$$ | awk '{print 1.2*$4+10 }'`
YMAX=`echo "${YMAX}/10*10" | bc`
YNUM=`echo "${YMAX}/5" | bc`
YINC=`echo "${YNUM}/2" | bc`

#==========  plot histogram ==========
AXIS="-Ba`echo ${XINC} | awk '{print $1*4}'`:S_All_Weights:/a${YINC}g${YINC}:Freq:WS"
PROJ="-JX${width}i/${height}i"

gmt psbasemap ${PROJ} -R${XMIN}/`echo ${XMAX} ${XINC} | awk '{print $1+$2}'`/0/${YMAX} ${AXIS} -O -K >> ${OUTFILE}
gmt pshistogram histo.dat -R -J -W${XINC} -L0.5p -Gblue -O -K >> ${OUTFILE}

exit 0
