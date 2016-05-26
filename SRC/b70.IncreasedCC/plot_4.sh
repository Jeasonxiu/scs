#!/bin/bash

ylabel="Freq."
xlabel="Norm_2 (FRS)"
YMIN=0
XMIN=-1
XMAX=1
XINC="0.025"
XNUM="0.1"

#==========  x axis ==========
binN=`echo "( ${XMAX} - ${XMIN} ) / ${XINC} " | bc`
XMAX=`echo "${XMIN} + ${XINC} * ${binN}" | bc -l`

#==========  y axis ==========
YMAX=0
pshistogram tmpfile_FRS_Norm -W${XINC} -IO > tmpfile_$$
YMAX=`minmax -C tmpfile_$$ | awk '{print 1.2*$4+10 }'`
YMAX=`echo "${YMAX}/10*10" | bc `
YNUM=`echo "${YMAX}/5" | bc `
YINC=`echo "${YNUM}/2" | bc `

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

pshistogram tmpfile_FRS_Norm ${REG} ${PROJ} -W${XINC} -L0.5p -Gblue -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

exit 0
