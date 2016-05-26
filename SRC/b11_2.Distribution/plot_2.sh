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

${EXECDIR}/radiation.out 0 1 3 << EOF
tmpfile_$$
${strike}
${dip}
${rake}
EOF


REG="-R0/360/0/60"
if [ `echo "${height} < ${width}" | bc` -eq 1 ]
then
    PROJ="-JPa${height}i"
else
    PROJ="-JPa${width}i"
fi

gmt makecpt -Cpolar -T-1/1/0.02 -I -Z > RAD.cpt
gmt xyz2grd tmpfile_$$ ${REG} -Gtmpgrd.grd -Az -I1/1

gmt psbasemap  ${REG} ${PROJ} -Ba60f10 -O -K >> ${OUTFILE}
gmt grdimage tmpgrd.grd ${REG} ${PROJ} -CRAD.cpt -O -K >> ${OUTFILE}

gmt psxy ${REG} ${PROJ} -Wblack,- -N -O -K >> ${OUTFILE} << EOF
210 0
210 60
EOF

cat > tmpfile_$$ << EOF
205 30 60 @~\260@~
EOF
gmt pstext tmpfile_$$ -J -R -F+jLB+f10p -N -O -K >> ${OUTFILE}

for count in `seq 1 ${CateN}`
do
    awk -v C=${count} '{if ($1==C && $4>0) print $2,$3,$4}' tmpfile_cate_az_ScStakeoff_misfit > tmpfile1_$$
    awk -v C=${count} '{if ($1==C && $4<0) print $2,$3,-$4}' tmpfile_cate_az_ScStakeoff_misfit > tmpfile2_$$
    gmt psxy tmpfile1_$$ ${REG} ${PROJ} -Sx -W${color[${count}]} -N -O -K >> ${OUTFILE}
    gmt psxy tmpfile2_$$ ${REG} ${PROJ} -Sc -W${color[${count}]} -N -O -K >> ${OUTFILE}

done

cat > tmpfile_$$ << EOF
180 80 ScS az-takeoff-misfit
180 85 circle: thin. cross: fat.
EOF
gmt pstext -J -R tmpfile_$$ -F+jCB+f10p -N -O -K >> ${OUTFILE}

exit 0
