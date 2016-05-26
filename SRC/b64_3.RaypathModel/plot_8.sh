#!/bin/bash


color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow


xlabel="Azimuth."
ylabel="LVRF (/), dVs<${VSlow}."
YMIN=0
YMAX=0.2
YNUM=0.05
YINC=0.01
XMIN=300
XMAX=380
XNUM=20
XINC=5

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_az_per > tmpfile_$$
    psxy tmpfile_$$ ${REG} ${PROJ} -Sp0.05i -W${color[$count]} -O -K >> ${OUTFILE} << EOF
EOF

done


exit 0
