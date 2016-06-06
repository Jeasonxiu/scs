#!/bin/bash

Num=`basename $0`
Num=${Num#plot_}
Num=${Num%.sh}


ylabel=""
xlabel=""
XMIN=-125.5
XMAX=-59.5
XINC=20
XNUM=10
YMIN=-29.5
YMAX=50.5
YINC=10
YNUM=10

if [ ${Num} -eq 28 ]
then
	YPOSI="-0.23"
	BAXIS=-Ba${XINC}g${XNUM}/a${XINC}g${YNUM}WS
else
	YPOSI="-0.05"
	BAXIS="-Bg${XNUM}/g${YNUM}WS"
fi

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

scale=`minmax -C tmpfile_S_Grid_${Num} | awk '{if (-$5>$6) print -$5; else print $6}'`
if [ ${scale} -eq 0 ]
then
	exit 0
fi
if [ ${scale} -eq 1 ]
then
	scale="2"
fi

gmt xyz2grd tmpfile_S_Grid_${Num} -Gtmp.grd ${REG} -I1/1
gmt makecpt -Cpolar -T-${scale}/${scale}/`echo "${scale}" |awk '{print 2*$1/50}'` > tmpfile.cpt
gmt grdimage ${REG} ${PROJ} tmp.grd -Ctmpfile.cpt -O -K >> ${OUTFILE}
gmt psscale -Ctmpfile.cpt -D`echo "${width}" | awk '{print $1/2}'`i/${YPOSI}i/${width}i/0.05ih -B`echo "${scale}"| awk '{printf "%d",$1/2}'` -O -K >> ${OUTFILE}
gmt pscoast -JX${width}id/${height}id ${REG} -W0.2p,black -A2000 -Dh -O -K >> ${OUTFILE}

gmt psbasemap ${REG} ${PROJ} ${BAXIS} -O -K >> ${OUTFILE}

D1=`awk -v N=${Num} 'NR==N {print $0}' tmpfile_depth`
D2=`awk -v N=$((Num+1)) 'NR==N {print $0}' tmpfile_depth`
cat > tmpfile_$$ << EOF
${XMIN} ${YMIN} ${D1} ~ ${D2} km.
EOF
gmt pstext tmpfile_$$ -F+jLB+f10p ${PROJ} ${REG} -N -O -K >> ${OUTFILE}

exit 0
