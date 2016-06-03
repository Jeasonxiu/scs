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
tmpfile_az_takeoff_MisfitS_Thin
tmpfile_1_$$
EOF

${EXECDIR}/Az2180.out 0 2 0 << EOF
tmpfile_az_takeoff_MisfitS_Fat
tmpfile_2_$$
EOF

NR1=`wc -l < tmpfile_1_$$`
NR2=`wc -l < tmpfile_2_$$`

gmt psxy tmpfile_1_$$ ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_2_$$ ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} S Misfit4, Thin(@;blue;${NR1}@;;) + Fat(@;red;${NR2}@;;).
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

# Add scale.
gmt psxy ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE} << EOF
-20 13 0.5
-10 13 1
0   13 1.5
EOF

gmt psxy ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE} << EOF
-30 13 0.5
-40 13 1
-50 13 1.5
EOF

cat > tmpfile_$$ << EOF
-20 10 0.5
-10 10 1
0   10 1.5
-30 10 -0.5
-40 10 -1
-50 10 -1.5
EOF
gmt pstext tmpfile_$$ -F+jCT+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
