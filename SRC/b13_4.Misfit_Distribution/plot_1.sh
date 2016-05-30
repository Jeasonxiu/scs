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
YNUM=20

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}
gmt pscoast -JX${width}id/${height}id ${REG} -W0.5p,black -A2000 -Dh -O -K >> ${OUTFILE}

NR1=`wc -l < tmpfile_stlo_stla_MisfitS_Thin`
NR2=`wc -l < tmpfile_stlo_stla_MisfitS_Fat`

gmt psxy tmpfile_stlo_stla_MisfitS_Thin ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_stlo_stla_MisfitS_Fat ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} S Misfit, NR=$((NR1+NR2)).
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
