#!/bin/bash

# ===========================================================
# Plot 1D Modeling space. 
#
# Shule Yu
# May 19 2015
# ===========================================================

if [ "${Method_1DMS}" = "Waterlevel" ]
then
    FRSDIR=${WORKDIR_WaterFRS}
elif [ "${Method_1DMS}" = "Ammon" ]
then
    FRSDIR=${WORKDIR_AmmonFRS}
elif [ "${Method_1DMS}" = "Subtract" ]
then
    FRSDIR=${WORKDIR_SubtractFRS}
else
    FRSDIR=${WORKDIR}/CompareFRS
fi


echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 2p
gmt gmtset MAP_FRAME_PEN 0.5p,black

# Plot parameters.
scaleX=`echo "${PLOTWIDTH_MS} ${X_MIN} ${X_MAX} ${X_INC} ${spaceX}" | awk '{print ($1-$5)/($3-$2+$4)}'`
scaleY=`echo "${PLOTHEIGHT_MS} ${Y_MIN} ${Y_MAX} ${Y_INC}" | awk '{print $1/($3-$2+$4)}'`

# Prepare selected model properties.

keys="<EQ> <${X_Name}> <${Y_Name}>"
${BASHCODEDIR}/Findfield.sh ${DATADIR}/index "${keys}" > model_x_y

rm -f selectedmodels_x_y
for Model in ${EQnames}
do
    grep ${Model} model_x_y >> selectedmodels_x_y
done

# Plot.

for GCARC in `seq ${GCARC1_1DMS} ${GCARCINC_1DMS} ${GCARC2_1DMS}`
do

    echo "    ==> Plotting 1D ModelSpace, Gcarc: ${GCARC}..."
    OUTFILE=${GCARC}.ps

	# Prepare plot trace info.
	mysql -N -u shule ${SYNDB} > filenames << EOF
select concat("${FRSDIR}/",pairname,".frs") from Master_a38 where wantit=1 and gcarc=${GCARC};
EOF

    ### plot titles and legends
	cat > tmpfile_$$ << EOF
0 105 FRS 1D ModelSpace, Gcarc ${GCARC}. ${Marker1_1D}, @;red;${Marker2_1D}@;;.
EOF

	gmt pstext tmpfile_$$ -JX10.0i/7.5i -R-100/100/-100/100 -F+jCB+f15p,1,black -Xf0.5i -Yf0.5i -N -K > ${OUTFILE}

	## go to the right position to plot basemap.
	rm -f tmpfile_$$
	for Y in `seq ${Y_MIN} ${Y_INC} ${Y_MAX}`
	do
		cat >> tmpfile_$$ << EOF
`echo "${X_MIN} ${spaceX} ${scaleX}"|awk '{print $1-$2/$3}'` ${Y}
EOF
	done

	for X in `seq ${X_MIN} ${X_INC} ${X_MAX}`
	do
		cat >> tmpfile_$$ << EOF
${X} `echo "${Y_MIN} ${Y_INC}"|awk '{print $1-$2/2}'`
EOF
	done

	gmt psxy tmpfile_$$ -Sc0.05i -Gblack -N -JX${PLOTWIDTH_MS}i/${PLOTHEIGHT_MS}i -R`echo "${X_MIN} ${spaceX} ${scaleX}" | awk '{print $1-$2/$3}'`/`echo "${X_MAX} ${X_INC}"|awk '{print $1+$2}'`/`echo "${Y_MIN} ${Y_INC}"|awk '{print $1-$2/2}'`/`echo "${Y_MAX} ${Y_INC}"|awk '{print $1+$2/2}'` -Ba${X_INC}f`echo ${X_INC} | awk '{print $1/2}'`:"${XLabel}":/a`echo ${Y_INC} | awk '{print $1/2}'`f`echo ${Y_INC} | awk '{print $1/2}'`:"${YLabel}":WS -Xf0.6i -Yf0.5i -O -K >> ${OUTFILE} << EOF
EOF

    ## go to the right position (preparing to plot seismograms)
    gmt psxy -JX`echo "0.9*${X_INC}*${scaleX}"|bc -l`i/`echo "0.9*${Y_INC}*${scaleY}"| bc -l`i -R${TIMEMIN_MS}/${TIMEMAX_MS}/-1/1 -X${spaceX}i -Y`echo "0.05 ${Y_INC} ${scaleY}"|awk '{print $1*$2*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    for Model in ${EQnames}
    do
		file=`grep ${Model} filenames`
		file2=${file##*/}
		file2=${CompareDIR}/${file2}

		if ! [ -e ${file} ]
		then
			continue
		fi

        ### get model parameters.
        INFO=`grep ${Model} selectedmodels_x_y`

        X=`echo "${INFO}" | awk '{print $2}'`
        Y=`echo "${INFO}" | awk '{print $3}'`

        # ===================================
        #        ! Plot !
        # ===================================

		MVX=`echo "${X} ${scaleX} ${X_MIN}" | awk '{print ($1-$3)*$2}'`
		MVY=`echo "${Y} ${scaleY} ${Y_MIN}" | awk '{print ($1-$3)*$2}'`

        ### go to the correct positoin.
		gmt psxy -J -R -X${MVX}i -Y${MVY}i -O -K >> ${OUTFILE} << EOF
EOF

		### plot time axis.
		gmt psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${TIMEMIN_MS} 0
${TIMEMAX_MS} 0
EOF
		for  time in `seq 0 20`
		do
			gmt psxy -J -R -Sy0.03i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_MS}" | bc -l` 0
EOF
		done

        ### plot FRS's.
		gmt psxy ${file} -J -R -W0.5p,black -O -K >> ${OUTFILE}

		if [ -e ${file2} ]
		then
			gmt psxy ${file2} -J -R -W0.5p,red -O -K >> ${OUTFILE}
		fi

        ### go back
		gmt psxy -J -R -X`echo ${MVX}| awk '{print -$1}'`i -Y`echo ${MVY}| awk '{print -$1}'`i -O -K >> ${OUTFILE} << EOF
EOF


    done # done Model loop.

    # Seal the last page.
gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # End of gcarc loop.

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

# Clean up.

cd ${CODEDIR}

exit 0
