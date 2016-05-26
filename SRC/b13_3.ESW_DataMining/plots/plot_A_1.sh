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

ylabel="ScS Misfit (All)."
xlabel="S Misfit (All)."
XMIN=-1
XMAX=1
XINC=0.2
XNUM=1
YMIN=-1
YMAX=2
YINC=0.2
YNUM=1

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

NR=`wc -l < tmpfile_master10_info`

awk '{print $1,$2}' tmpfile_master10_info | gmt psxy ${REG} ${PROJ} -St0.1i -Gblack -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMAX} ${YMAX} ${NR}
EOF

gmt pstext tmpfile_$$ -F+jRT+f8p -J -R -N -O -K >> ${OUTFILE}

exit 0
