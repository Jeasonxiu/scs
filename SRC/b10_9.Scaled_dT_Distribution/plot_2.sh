#!/bin/bash

ylabel="LAT"
xlabel="LON"
XMIN=-130
XMAX=-60
XINC=20
XNUM=10
YMIN=20
YMAX=50
YINC=10
YNUM=10

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}
gmt pscoast -JX${width}id/${height}id ${REG} -W0.5p,black -A2000 -Dh -O -K >> ${OUTFILE}

NR1=`wc -l < tmpfile_stlo_stla_dTScS_Lesser`
NR2=`wc -l < tmpfile_stlo_stla_dTScS_Greater`

gmt psxy tmpfile_stlo_stla_dTScS_Lesser ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_stlo_stla_dTScS_Greater ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} Scaled ScS dT, Fast(@;blue;${NR1}@;;) + Slow(@;red;${NR2}@;;).
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
