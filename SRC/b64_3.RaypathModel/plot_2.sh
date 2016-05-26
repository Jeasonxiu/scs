#!/bin/bash

ylabel="Freq."
xlabel="ELV (dVs.)"
YMIN=0
XMIN=-0.2
XMAX=0
XINC=0.01
XNUM=0.05

#==========  x axis ==========
binN=`echo "( ${XMAX} - ${XMIN} ) / ${XINC} " | bc`
XMAX=`echo "${XMIN} + ${XINC} * ${binN}" | bc -l`

#==========  y axis ==========
YMAX=0
for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2}' tmpfile_cate_ext > histo.dat_${count}

    AMP=`${BASHCODEDIR}/amplitude.sh histo.dat_${count}`
    if [ `echo "${AMP}>0" | bc ` -ne 1 ]
    then
        continue
    fi

    pshistogram histo.dat_${count} -W${XINC} -IO > tmpfile_$$

    YMAX_tmp=`minmax -C tmpfile_$$ | awk '{print 1.2*$4+10 }'`
    if [ `echo "${YMAX_tmp}>${YMAX}" | bc`  -eq 1 ]
    then
        YMAX=${YMAX_tmp}
    fi
done
YMAX=`echo "${YMAX}/10*10" | bc `
YNUM=`echo "${YMAX}/5" | bc `
YINC=`echo "${YNUM}/2" | bc `

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

pshistogram histo.dat_1 ${REG} ${PROJ} -W${XINC} -L0.5p -Gred -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

exit 0
