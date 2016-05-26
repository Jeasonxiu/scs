#!/bin/bash

# ===========================================================
# Plot Modeling result. Overlaping for comparison.
#
# Shule Yu
# May 19 2015
# ===========================================================

if [ "${Method1_MS}" = "Waterlevel" ]
then
    FRSDIR1=${WORKDIR_WaterFRS}
elif [ "${Method1_MS}" = "Ammon" ]
then
    FRSDIR1=${WORKDIR_AmmonFRS}
elif [ "${Method1_MS}" = "Subtract" ]
then
    FRSDIR1=${WORKDIR_SubtractFRS}
else
    FRSDIR1=${WORKDIR}/CompareFRS
fi

if [ "${Method2_MS}" = "Waterlevel" ]
then
    FRSDIR2=${WORKDIR_WaterFRS}
elif [ "${Method2_MS}" = "Ammon" ]
then
    FRSDIR2=${WORKDIR_AmmonFRS}
elif [ "${Method2_MS}" = "Subtract" ]
then
    FRSDIR2=${WORKDIR_SubtractFRS}
else
    FRSDIR2=${WORKDIR}/CompareFRS
fi

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT


# =========================================
#     ! Check the calculation result !
# =========================================

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c


# Plot parameters.
scaleX=`echo "${PLOTWIDTH_MS} ${X_MIN} ${X_MAX} ${X_INC} ${spaceX}" | awk '{print $1/($3-$2+$4+$5)}'`
scaleY=`echo "${PLOTHEIGHT_MS} ${Y_MIN} ${Y_MAX} ${Y_INC}" | awk '{print $1/($3-$2+$4)}'`

# Prepare plot data.

keys="<EQ> <${X_Name}> <${Y_Name}>"
${BASHCODEDIR}/Findfield.sh ${DATADIR}/index "${keys}" > model_vs_thickness

keys="<EQ> <STNM> <GCARC>"
${BASHCODEDIR}/Findfield.sh ${FRSDIR1}/INFO_All "${keys}" > model_stnm_gcarc
${BASHCODEDIR}/Findfield.sh ${FRSDIR2}/INFO_All "${keys}" > model_stnm_gcarc_2


rm -f selectedmodels_vs_thickness
for Model in ${EQnames}
do
    grep ${Model} model_vs_thickness >> selectedmodels_vs_thickness
done

# Plot.

for GCARC in `seq ${GCARC1_MS} ${GCARCINC_MS} ${GCARC2_MS}`
do

    OUTFILE=${GCARC}.ps

    awk -v gcarc=${GCARC} '{if ($3==gcarc) print $1"_"$2".frs" }' model_stnm_gcarc > filenames
    awk -v gcarc=${GCARC} '{if ($3==gcarc) print $1"_"$2".frs" }' model_stnm_gcarc_2 > filenames2

    ### plot titles and legends
    title="FRS ModelSpace, Gcarc: ${GCARC}, @;255/0/0;${Marker1_MS}@;; , @;0/0/255;${Marker2_MS}@;;"

	pstext -JX10.5i/0.7i -R-1/1/-1/1 -X0.7i -Y8i -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title}
EOF

    ## go to the right position (plot basemap).
    psxy -JX${PLOTWIDTH_MS}i/${PLOTHEIGHT_MS}i -R`echo "${X_MIN} ${spaceX}"|awk '{print $1-$2}'`/`echo "${X_MAX} ${X_INC}"|awk '{print $1+$2}'`/`echo "${Y_MIN} ${Y_INC}"|awk '{print $1-$2/2}'`/`echo "${Y_MAX} ${Y_INC}"|awk '{print $1+$2/2}'` -Ba30f10:"${PropertyX_Label}":/a0.5f0.1:"${PropertyY_Label}":WS -Y-${PLOTHEIGHT_MS}i -O -K >> ${OUTFILE} << EOF
EOF

    ## go to the right position (preparing to plot seismograms)
    psxy -JX`echo "0.9*${X_INC}*${scaleX}"|bc -l`i/`echo "0.9*${Y_INC}*${scaleY}"| bc -l`i -R${TIMEMIN_MS}/${TIMEMAX_MS}/-1/1 -X`echo "${spaceX} ${scaleX} " | awk '{print $1*$2}'`i -Y`echo "0.05 ${Y_INC} ${scaleY}"|awk '{print $1*$2*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    plot=1
    for Model in ${EQnames}
    do

        file=${FRSDIR1}/`grep ${Model} filenames`
        file2=${FRSDIR2}/`grep ${Model} filenames2`


        # get model parameters.
        INFO=`grep ${Model} selectedmodels_vs_thickness`

        Vs=`echo "${INFO}" | awk '{print $2}'`
        Thickness=`echo "${INFO}" | awk '{print $3}'`

        # ===================================
        #        ! Plot !
        # ===================================

		MVX=`echo "${Vs} ${scaleX} ${X_MIN}" | awk '{if (0<$1 && $1<2) print ((1-$1)*100-$3)*$2 ; else print ($1-$3)*$2}'`
		MVY=`echo "${Thickness} ${scaleY} ${Y_MIN}" | awk '{if (0<$1 && $1<2) print ((1-$1)*100-$3)*$2 ; else print ($1-$3)*$2}'`
# 		MVY=`echo "${Thickness} ${scaleY} ${Y_MIN}" | awk '{print ($1-$3)*$2}'`

        ### go to the correct positoin.
		psxy -J -R -X${MVX}i -Y${MVY}i -O -K >> ${OUTFILE} << EOF
EOF
			### plot zero line
			psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${TIMEMIN_MS} 0
${TIMEMAX_MS} 0
EOF
			for  time in `seq 0 20`
			do
				psxy -J -R -Sy0.03i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_MS}" | bc -l` 0
EOF
			done

        ### plot FRS.
		if [ -e ${file} ]
		then
			psxy ${file} -J -R -W0.5p,red -O -K >> ${OUTFILE}
		fi

		if [ -e ${file2} ]
		then
			psxy ${file2} -J -R -W0.5p,blue -O -K >> ${OUTFILE}
		fi

        ### go back
		psxy -J -R -X`echo ${MVX}| awk '{print -$1}'`i -Y`echo ${MVY}| awk '{print -$1}'`i -O -K >> ${OUTFILE} << EOF
EOF

        plot=$((plot+1))

    done # done Model loop.

    # Seal the last page.
psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # End of gcarc loop.

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}_${Marker1_MS}_${Marker2_MS}.pdf

# Clean up.

cd ${CODEDIR}

exit 0
