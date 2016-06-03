#!/bin/bash


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

gmt psxy tmpfile_az_takeoff_MisfitS_Thin ${REG} ${PROJ} -Sx -Wdarkblue -N -O -K >> ${OUTFILE}
gmt psxy tmpfile_az_takeoff_MisfitS_Fat ${REG} ${PROJ} -Sc -Wdarkred -N -O -K >> ${OUTFILE}

exit 0
