#!/bin/bash

# ===========================================================
# Plot 1D Modeling result.
#
# Shule Yu
# May 19 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# =========================================
#     ! Check the calculation result !
# =========================================
if ! [ -e ${WORKDIR_Model}/CompareCCC ]
then
    echo "    !=> `basename $0`: Run modeling first ..."
	exit 1
else
    echo "    ==> Plotting modeling result."
fi


# Plot parameters.

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 2p
gmt gmtset MAP_FRAME_PEN 0.5p,black

scaleX=`echo "${PLOTWIDTH_WM} ${X_MIN} ${X_MAX} ${X_INC} ${spaceX}" | awk '{print ($1-$5)/($3-$2+$4)}'`
scaleY=`echo "${PLOTHEIGHT_WM} ${Y_MIN} ${Y_MAX} ${Y_INC}" | awk '{print $1/($3-$2+$4)}'`

# Prepare selected model properties.

keys="<EQ> <${X_Name}> <${Y_Name}>"
${BASHCODEDIR}/Findfield.sh ${SYNDATADIR}/index "${keys}" > model_x_y

rm -f selectedmodels_x_y
for Model in ${Modelnames}
do
    grep ${Model} model_x_y >> selectedmodels_x_y
done


# Estimation info.
if [ ${CompareKey} = "CCC" ] || [ ${CompareKey} = "CCC_Amp" ]
then
    CompareString="-g -r -k 3,3"
else
    CompareString="-g -k 3,3"
fi

# sort the model of this bin according to the compare key:
#     keys="<BinN> <Model> <CCC> <Norm2> <Norm1> <CCC_Amp>"
keys="<BinN> <Model> <${CompareKey}>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_Model}/CompareCCC "${keys}" > tmpfile_bin_model_key

rm -f tmpfile_selectedmodels
for Model in ${Modelnames}
do
    grep ${Model} tmpfile_bin_model_key >> tmpfile_selectedmodels
done

sort ${CompareString} tmpfile_selectedmodels | awk '{print $1,$2}' > tmpfile_sorted

Nbins=`ls ${WORKDIR_Geo}/*.grid | wc -l`

# Plot.
for binN in `seq 1 ${Nbins}`
do

    echo "    ==> Plotting 1D Modeling result, bin : ${binN}..."
    OUTFILE=${binN}.ps

	# Prepare plot trace info.
    NRecord=`wc -l < ${WORKDIR_Geo}/${binN}.grid`
	NRecord=$((NRecord-1))

    BestFit=`awk -v B=${binN} '{if ($1==B) print $2}' tmpfile_sorted | head -n 5`
    LeastFit=`awk -v B=${binN} '{if ($1==B) print $2}' tmpfile_sorted | tail -n 5`


    ### plot titles and legends
	cat > tmpfile_$$ << EOF
0 105 FRS 1D Modeling result, bin ${binN} (${NRecord}), Data/@;red;Model@;;, CompareMethod: ${CompareKey}
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

	gmt psxy tmpfile_$$ -Sc0.05i -Gblack -N -JX${PLOTWIDTH_WM}i/${PLOTHEIGHT_WM}i -R`echo "${X_MIN} ${spaceX} ${scaleX}" | awk '{print $1-$2/$3}'`/`echo "${X_MAX} ${X_INC}"|awk '{print $1+$2}'`/`echo "${Y_MIN} ${Y_INC}"|awk '{print $1-$2/2}'`/`echo "${Y_MAX} ${Y_INC}"|awk '{print $1+$2/2}'` -Ba${X_INC}f`echo ${X_INC} | awk '{print $1/2}'`:"${XLabel}":/a`echo ${Y_INC} | awk '{print $1/2}'`f`echo ${Y_INC} | awk '{print $1/2}'`:"${YLabel}":WS -Xf0.6i -Yf0.5i -O -K >> ${OUTFILE} << EOF
EOF

    ## go to the right position (preparing to plot seismograms)
    gmt psxy -JX`echo "0.9*${X_INC}*${scaleX}"|bc -l`i/`echo "0.9*${Y_INC}*${scaleY}"| bc -l`i -R${TIMEMIN_WM}/${TIMEMAX_WM}/-1/1 -X${spaceX}i -Y`echo "0.05 ${Y_INC} ${scaleY}"|awk '{print $1*$2*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    for Model in ${Modelnames}
    do

		file1="${WORKDIR_Geo}/${binN}.frstack"
		file2="${WORKDIR_Model}/${Model}_${binN}.frstack"

		if ! [ -e ${file1} ] || ! [ -e ${file2} ]
		then
			continue
		fi

        ### get model parameters.
        INFO=`grep ${Model} selectedmodels_x_y`

        X=`echo "${INFO}" | awk '{print $2}'`
        Y=`echo "${INFO}" | awk '{print $3}'`
        Estimation=`awk -v M=${Model} -v B=${binN} '{if ($1==B && $2==M) print $3}' tmpfile_selectedmodels`

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
${TIMEMIN_WM} 0
${TIMEMAX_WM} 0
EOF
		for  time in `seq 0 20`
		do
			gmt psxy -J -R -Sy0.03i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_WM}" | bc -l` 0
EOF
		done

        ### plot data frs bin stack.
		awk '{print $1,$2}' ${file1} | gmt psxy -J -R -W0.5p,black -O -K >> ${OUTFILE}

        ### plot Synthesis frs bin stack.
		awk '{print $1,$2}' ${file2} | gmt psxy -J -R -W0.5p,red -O -K >> ${OUTFILE}

		### Text indicate Estimations.

        if [[ "${BestFit}" == *"${Model}"* ]]
        then
			echo "${TIMEMIN_WM} 0.5 @;red;${Estimation}@;;" > tmpfile_$$
        elif [[ "${LeastFit}" == *"${Model}"* ]]
        then
			echo "${TIMEMIN_WM} 0.5 @;blue;${Estimation}@;;" > tmpfile_$$
        else
			echo "${TIMEMIN_WM} 0.5 ${Estimation}" > tmpfile_$$
        fi
		gmt pstext tmpfile_$$ -J -R -F+jLB+f8p,1 -N -O -K >> ${OUTFILE}

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
