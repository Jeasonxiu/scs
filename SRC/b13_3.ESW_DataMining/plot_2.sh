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

ylabel="ScS Misfit (AfterCast)."
xlabel="S Misfit (AfterCast)."
XMIN=-1
XMAX=1
XINC=0.2
XNUM=1
YMIN=-1
YMAX=2
YINC=0.2
YNUM=1

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

gmt psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}g${XNUM}:"${xlabel}":/a${YNUM}f${YINC}g${YNUM}:"${ylabel}":WS -O -K >> ${OUTFILE}

for cate in `seq 1 ${CateN}`
do
	NR[${cate}]=`awk -v C=${cate} '{ if ($1==C) print $1 }' tmpfile_master11_info | wc -l`
done

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_master11_info > tmpfile_$$
    gmt psxy tmpfile_$$ ${REG} ${PROJ} -St0.1i -G${color[${count}]} -N -O -K >> ${OUTFILE}

done

cat > tmpfile_$$ << EOF
${XMAX} ${YMAX} @;${color[1]};${NR[1]}@;; @;${color[2]};${NR[2]}@;; @;${color[3]};${NR[3]}@;;
EOF

gmt pstext tmpfile_$$ -F+jRT+f8p -J -R -N -O -K >> ${OUTFILE}

exit 0
