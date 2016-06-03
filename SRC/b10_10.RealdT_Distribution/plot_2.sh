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

gmt psxy tmpfile_stlo_stla_dTScS_dot ${REG} ${PROJ} -Sc0.05 -Gblack -Wblack -O -K >> ${OUTFILE}
gmt psxy tmpfile_stlo_stla_dTScS_Linear_Fast ${REG} ${PROJ} -Sc -W0.8p,blue -O -K >> ${OUTFILE}
gmt psxy tmpfile_stlo_stla_dTScS_Linear_Slow ${REG} ${PROJ} -Sc -W0.8p,red -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} ScS dT, @;blue;Fast@;;, @;red;Slow@;;.
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

# Plot scale.

gmt psxy ${REG} ${PROJ} -Sc -W0.8p,black -N -O -K >> ${OUTFILE} << EOF
-115 54.9 `echo "1/6" | bc -l`
-105 54.9 `echo "3/6" | bc -l`
-95  54.9 `echo "5/6" | bc -l`
-85  54.9 `echo "7/6" | bc -l`
-75  54.9 `echo "9/6" | bc -l`
EOF
gmt psxy ${REG} ${PROJ} -Sc -Gblack -Wblack -N -O -K >> ${OUTFILE} << EOF
-125 54.9 `echo "0.5/6" | bc -l`
EOF

cat > tmpfile_$$ << EOF
-125 52 <0.5
-115 52 1
-105 52 3
-95  52 5
-85  52 7
-75  52 9
-65  52 sec.
EOF
gmt pstext tmpfile_$$ -F+jCB+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
