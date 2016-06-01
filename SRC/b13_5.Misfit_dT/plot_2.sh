#!/bin/bash

ylabel="dT (ScS)"
xlabel="Misfit (ScS)"
XMIN=-2
XMAX=2
XINC=0.5
XNUM=0.5

cat tmpfile_MisfitScS_DTScS_Thin tmpfile_MisfitScS_DTScS_Fat | awk '{print $2}' > tmpfile_$$ 
${EXECDIR}/GetAve.out 0 2 0 << EOF
tmpfile_$$
tmpfile_Out_$$
EOF
read YAVE < tmpfile_Out_$$
YMIN=`echo "${YAVE}-10" | bc`
YMAX=`echo "${YAVE}+10" | bc`
YINC=2
YNUM=2

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

NR1=`wc -l < tmpfile_MisfitScS_DTScS_Thin`
NR2=`wc -l < tmpfile_MisfitScS_DTScS_Fat`

gmt psxy tmpfile_MisfitScS_DTScS_Thin ${REG} ${PROJ} -Sx0.1i -Wblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_MisfitScS_DTScS_Fat ${REG} ${PROJ} -Sc0.1i -Wred -N -O -K >> ${OUTFILE}

cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} Thin(@;blue;${NR1}@;;) + Fat(@;red;${NR2}@;;).
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p -J -R -N -O -K >> ${OUTFILE}

rm -f tmpfile*$$

exit 0
