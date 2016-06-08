#!/bin/bash

ylabel="Take-off Angle (deg)"
xlabel="Azimuth (deg)"
XMIN=-60
XMAX=10
XINC=10
XNUM=10
YMIN=0
YMAX=30
YINC=5
YNUM=5

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

${EXECDIR}/Az2180.out 0 2 0 << EOF
tmpfile_az_takeoff_dTScS_Fast
tmpfile_1_$$
EOF

${EXECDIR}/Az2180.out 0 2 0 << EOF
tmpfile_az_takeoff_dTScS_Slow
tmpfile_2_$$
EOF

NR1=`wc -l < tmpfile_1_$$`
NR2=`wc -l < tmpfile_2_$$`

gmt psxy tmpfile_1_$$ ${REG} ${PROJ} -Sx -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_2_$$ ${REG} ${PROJ} -Sc -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} ScS dT @;blue;Fast@;; @;red;Slow@;;
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

exit 0
