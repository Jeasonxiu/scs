#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot CC histogram result.
#
# Shule Yu
# Sept 23 2015
# ===========================================================

PLOTVERTIC="8"
PLOTHORIZ="10"
VERTICNUM=2
HORIZNUM=1
VERTICPER="0.8"
HORIZPER="0.8"
PLOTORIENT=""

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

hskip=`echo "${PLOTVERTIC}/${VERTICNUM}" | bc -l`
wskip=`echo "${PLOTHORIZ}/($((HORIZNUM-1))+${HORIZPER})" | bc -l`
height=`echo "${hskip}*${VERTICPER}" | bc -l`
width=`echo "${wskip}*${HORIZPER}" | bc -l`

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

for Dist in `seq ${D1_CC} ${DInc_CC} ${D2_CC}`
do
    # Check calculation (counting) result.
    if ! [ -e ${WORKDIR_Resolution}/ScS_${Dist} ]
    then
        echo "    !=> Can't find IncreasedCC ScS file on ${Dist}..."
		continue
    fi

    if ! [ -e ${WORKDIR_Resolution}/FRS_${Dist} ]
    then
        echo "    !=> Can't find IncreasedCC FRS file on ${Dist}..."
		continue
    fi

    echo "    ==> Plot CC result on gcarc: ${Dist}."

	# Plot I/O's.
	cp ${WORKDIR_Resolution}/ScS_${Dist} tmpfile_ScS
	cp ${WORKDIR_Resolution}/FRS_${Dist} tmpfile_FRS
	cp ${WORKDIR_Resolution}/ScS_Norm2_${Dist} tmpfile_ScS_Norm
	cp ${WORKDIR_Resolution}/FRS_Norm2_${Dist} tmpfile_FRS_Norm

	# Plot Begin.
	OUTFILE=${Dist}.ps
	rm -f ${OUTFILE}

	# Title.
	title="Distance: ${Dist}. Model Space CC resolution."

	PROJ="-JX${PLOTHORIZ}i/0.3i"
	REG="-R-1/1/-1/1"
	pstext ${REG} ${PROJ} -X0.65i -Y8.1i ${PLOTORIENT} -N -K > ${OUTFILE} << EOF
0 0 10 0 0 CB ${title}
EOF
	psxy -J -R -Y-8.1i -O -K >> ${OUTFILE} << EOF
EOF

	# SubPlots.
	psxy -J -R -Y${PLOTVERTIC}i -O -K >> ${OUTFILE} << EOF
EOF

	psxy -J -R -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

	for count2 in `seq 1 $((VERTICNUM*HORIZNUM))`
	do
		if [ -e ${PLOTSRCDIR}/plot_${count2}.sh ]
		then
			${PLOTSRCDIR}/plot_${count2}.sh
		fi

		if [ $((count2%HORIZNUM)) -eq 0 ]
		then
			psxy -J -R -X`echo "-$((HORIZNUM-1))*${wskip}" | bc -l`i -Y-${hskip}i -O -K >> ${OUTFILE} << EOF
EOF
		else
			psxy -J -R -X${wskip}i -O -K >> ${OUTFILE} << EOF
EOF
		fi

	done

	# Seal it.
	psxy -J -R -O >> ${OUTFILE} << EOF
EOF


done # Done Dist loop.

# Make PDF.
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/IncreasedCC.pdf


cd ${CODEDIR}

exit 0
