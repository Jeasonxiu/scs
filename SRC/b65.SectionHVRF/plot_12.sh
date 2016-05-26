#!/bin/bash


ylabel="Misfit (ScS)"
xlabel="HVRF (/). dVs>${VFast}. (${D2}->${D1})"

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow


XMIN=0
XMAX=0.2
XNUM=0.05
XINC=0.01
YMIN=-1
YMAX=1
YNUM=0.5
YINC=0.1

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $3,$2}' tmpfile_cate_6_scs_misfit_extreme > tmpfile_$$
    psxy tmpfile_$$ ${REG} ${PROJ} -Sp0.05i -W${color[$count]} -O -K >> ${OUTFILE} << EOF
EOF

done



exit 0
