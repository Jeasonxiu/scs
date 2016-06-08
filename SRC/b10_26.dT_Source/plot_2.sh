#!/bin/bash

ylabel="Take-off Angle (deg)"
xlabel="Azimuth (deg)"
XMIN=-60
XMAX=10
XINC=10
XNUM=10
YMIN=20
YMAX=50
YINC=5
YNUM=5

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

${EXECDIR}/Az2180.out 0 2 0 << EOF
tmpfile_az_takeoff_dTS_Fast
tmpfile_1_$$
EOF

${EXECDIR}/Az2180.out 0 2 0 << EOF
tmpfile_az_takeoff_dTS_Slow
tmpfile_2_$$
EOF

NR1=`wc -l < tmpfile_1_$$`
NR2=`wc -l < tmpfile_2_$$`

gmt psxy tmpfile_1_$$ ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_2_$$ ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} S dT @;blue;Fast@;; @;red;Slow@;;
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

# Add scale.
gmt psxy ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE} << EOF
-20 13 `echo "1" | awk '{print $1/6}'`
-10 13 `echo "3" | awk '{print $1/6}'`
0   13 `echo "5" | awk '{print $1/6}'`
EOF

gmt psxy ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE} << EOF
-30 13 `echo "1/6" | bc -l`
-40 13 `echo "3/6" | bc -l`
-50 13 `echo "5/6" | bc -l`
EOF

cat > tmpfile_$$ << EOF
-50 10 -5
-40 10 -3
-30 10 -1
-20 10 1
-10 10 3
0   10 5
EOF
gmt pstext tmpfile_$$ -F+jCT+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
