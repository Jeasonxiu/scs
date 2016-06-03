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

NR1=`wc -l < tmpfile_stlo_stla_MisfitScS_Thin`
NR2=`wc -l < tmpfile_stlo_stla_MisfitScS_Fat`

gmt psxy tmpfile_stlo_stla_MisfitScS_Thin ${REG} ${PROJ} -Sx -Wblue -O -K >> ${OUTFILE}
gmt psxy tmpfile_stlo_stla_MisfitScS_Fat ${REG} ${PROJ} -Sc -Wred -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} ScS Misfit4, Thin(@;blue;${NR1}@;;) + Fat(@;red;${NR2}@;;).
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

# Plot scale.

gmt psxy ${REG} ${PROJ} -Sc -W0.8p,red -N -O -K >> ${OUTFILE} << EOF
-125 54.9 0.2
-115 54.9 0.4
-105 54.9 0.6
-95  54.9 0.8
-85  54.9 1.0
-75  54.9 1.2
-65  54.9 1.4
EOF

gmt psxy ${REG} ${PROJ} -Sx -W0.8p,blue -N -O -K >> ${OUTFILE} << EOF
-125 54.9 0.2
-115 54.9 0.4
-105 54.9 0.6
-95  54.9 0.8
-85  54.9 1.0
-75  54.9 1.2
-65  54.9 1.4
EOF

cat > tmpfile_$$ << EOF
-125 52 0.2
-115 52 0.4
-105 52 0.6
-95  52 0.8
-85  52 1.0
-75  52 1.2
-65  52 1.4
EOF
gmt pstext tmpfile_$$ -F+jCB+f10p -J -R -N -O -K >> ${OUTFILE}


exit 0
