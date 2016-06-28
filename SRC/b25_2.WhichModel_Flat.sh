#!/bin/bash

# ===========================================================
# Plot Modeling result.
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
if ! [ -e ${WORKDIR_Model}/CompareCCC ] ||  ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> Run WhichModel first ..."
    exit 1
else
    echo "    ==> Plotting ModelSpace of 2.5D ULVZ Flat."
fi

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 2p
gmt gmtset MAP_FRAME_PEN 0.5p,black


PenSyn=0.5p,red
PenData=1p,black

# Plot parameters.
scaleX=`echo "${PLOTWIDTH_WM} ${PropertyX_MIN_WM} ${PropertyX_MAX_WM} ${PropertyX_INC_WM}" | awk '{print $1/($3-$2+$4)}'`
scaleY=`echo "${PLOTHEIGHT_WM} ${PropertyY_MIN_WM} ${PropertyY_MAX_WM} ${PropertyY_INC_WM}" | awk '{print $1/($3-$2+$4)}'`

# Prepare plot data.

keys="<EQ> <${PropertyX_WM}> <${PropertyY_WM}> <${PropertyZ_WM}>"
${BASHCODEDIR}/Findfield.sh ${SYNDATADIR}/index "${keys}" | awk -v A=${PropertyX_MIN_WM} -v B=${PropertyX_MAX_WM} -v C=${PropertyY_MIN_WM} -v D=${PropertyY_MAX_WM} -v E=${PropertyZ_MIN_WM} -v F=${PropertyZ_MAX_WM} '{if ((A<=$2 && $2<=B) && (C<=$3 && $3<=D) && (E<=$4 && $4<=F)) print $0}' > model_x_y_z

keys="<Model> <BinN> <${CompareKey}>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_Model}/CompareCCC "${keys}" > model_bin_c
if [ ${CompareKey} = "CCC" ] || [ ${CompareKey} = "CCC_Amp" ]
then
    CompareString="-g -r -k 2,2"
else
    CompareString="-g -k 2,2"
fi



rm -f selectedmodels_x_y_z
for Model in ${Modelnames}
do
    grep ${Model} model_x_y_z >> selectedmodels_x_y_z
done

# Plot.

for Bin in `seq ${Bin1_WM} ${BinINC_WM} ${Bin2_WM}`
do

    awk -v B=${Bin} '{if ($2==B) print $1"_"$2".frstack" }' model_bin_c > filenames
    awk -v B=${Bin} '{if ($2==B) print $1,$3}' model_bin_c > values
    awk -v B=${Bin} '{if ($2==B) print $1,$3}' model_bin_c | sort ${CompareString} | head -n 5 | awk '{print $1}' > tmpfile_bestfit

	file2=${WORKDIR_Geo}/${Bin}.frstack

    OUTFILE_All=Bin${Bin}.ps
	Page=1
	for D4 in `seq ${Property4D_MIN_WM} ${Property4D_INC_WM} ${Property4D_MAX_WM}`
	do

		# select models for D4.
		keys="<EQ> <${Property4D_WM}>"
		${BASHCODEDIR}/Findfield.sh ${SYNDATADIR}/index "${keys}" | awk -v D4=${D4} '{if ($2==D4) print $1}'> tmpfile_$$
		rm -f tmpfile_4D_models
		for EQ in ${Modelnames}
		do
			grep ${EQ} tmpfile_$$ >> tmpfile_4D_models 2>/dev/null
		done


		OUTFILE=${Page}.ps

		### plot titles and legends
		cat > tmpfile_$$ << EOF
0 105 ${Marker_WM} Modeling, Bin ${Bin}, ${Property4D_WM} = ${D4} ${Property4D_Label}
EOF

		gmt pstext tmpfile_$$ -JX10.0i/7.5i -R-100/100/-100/100 -F+jCB+f15p,1,black -Xf0.5i -Yf0.5i -N -K > ${OUTFILE}

		## go to the right position (plot basemap).
		rm -f tmpfile_$$
		for Y in `seq ${PropertyY_MIN_WM} ${PropertyY_INC_WM} ${PropertyY_MAX_WM}`
		do
			cat >> tmpfile_$$ << EOF
`echo "${PropertyX_MIN_WM} ${scaleX}"|awk '{print $1-0.1/$2}'` ${Y}
EOF
		done
		for X in `seq ${PropertyX_MIN_WM} ${PropertyX_INC_WM} ${PropertyX_MAX_WM}`
		do
			cat >> tmpfile_$$ << EOF
${X} `echo "${PropertyY_MIN_WM} ${PropertyY_INC_WM}"|awk '{print $1-$2/2}'`
EOF
		done

		gmt psxy tmpfile_$$ -Sc0.05i -Gblack -N -JX`echo ${PLOTWIDTH_WM} | awk '{print $1+0.1}'`i/${PLOTHEIGHT_WM}i -R`echo "${PropertyX_MIN_WM} ${scaleX}"|awk '{print $1-0.1/$2}'`/`echo "${PropertyX_MAX_WM} ${PropertyX_INC_WM}"|awk '{print $1+$2}'`/`echo "${PropertyY_MIN_WM} ${PropertyY_INC_WM}"|awk '{print $1-$2/2}'`/`echo "${PropertyY_MAX_WM} ${PropertyY_INC_WM}"|awk '{print $1+$2/2}'` -Ba${PropertyX_INC_WM}f`echo ${PropertyX_INC_WM} | awk '{print $1/2}'`:"${PropertyX_Label}":/a`echo ${PropertyY_INC_WM} | awk '{print $1/2}'`f`echo ${PropertyY_INC_WM} | awk '{print $1/2}'`:"${PropertyY_Label}":WS -Xf0.6i -Yf0.5i -O -K >> ${OUTFILE} << EOF
EOF

# -Ba10g10/a10g10WSNE
		## go to the right position (preparing to plot seismograms)
		gmt psxy -JX`echo "0.9*${PropertyX_INC_WM}*${scaleX}"|bc -l`i/`echo "0.8*${PropertyY_INC_WM}*${scaleY}"| bc -l`i -R${TIMEMIN_WM}/${TIMEMAX_WM}/-1/1 -X0.1i -Y`echo "0.1 ${PropertyY_INC_WM} ${scaleY}"|awk '{print $1*$2*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

		while read Model
		do
			file=${WORKDIR_Model}/`grep ${Model} filenames`
			value=`grep ${Model} values | awk '{print $2}'`

			if ! [ -e ${file} ]
			then
				continue
			fi

			# get model parameters.
			INFO=`grep ${Model} selectedmodels_x_y_z`

			X=`echo "${INFO}" | awk '{print $2}'`
			Y=`echo "${INFO}" | awk '{print $3}'`
			Z=`echo "${INFO}" | awk '{print $4}'`

			# ===================================
			#        ! Plot !
			# ===================================

			MVX=`echo "${X} ${scaleX} ${PropertyX_MIN_WM}" | awk '{printf "%.3f",($1-$3)*$2}'`
			MVY=`echo "${Y} ${scaleY} ${PropertyY_MIN_WM} ${Z} ${PropertyZ_MIN_WM} ${PropertyZ_INC_WM}" | awk '{printf "%.3f",($1-$3)*$2+(($4-$5)/$6-1.5)*0.4}'`

			### go to the correct positoin.
			gmt psxy -J -R -X${MVX}i -Y${MVY}i -O -K >> ${OUTFILE} << EOF
EOF
			if [ `echo "${Z}>${PropertyZ_MIN_WM}" | bc ` -ne 1 ]
			then

				### plot zero line
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
			fi

			### plot FRS.
			awk '{print $1,$2}' ${file} | gmt psxy -J -R -W${PenSyn} -N -O -K >> ${OUTFILE}

			### plot DataStack.
			awk '{print $1,$2}' ${file2} | gmt psxy -J -R -W${PenData} -N -O -K >> ${OUTFILE}

			### plot indicator.
			if ! [ "`grep ${Model} tmpfile_bestfit`" = "" ]
			then
				gmt psxy -J -R -Sa0.1i -Ggreen -N -O -K >> ${OUTFILE} << EOF
0 0
EOF
			fi


			### plot test.
			cat > tmpfile_$$ << EOF
${TIMEMAX_WM} 0.1 `echo ${Z} | awk '{print $1*100}'`${PropertyZ_Label}
${TIMEMAX_WM} -0.1 ${value}
EOF
			gmt pstext tmpfile_$$ -J -R -F+jRB+f5p,0,black -N -O -K >> ${OUTFILE}

			### go back
			gmt psxy -J -R -X`echo ${MVX}| awk '{print -$1}'`i -Y`echo ${MVY}| awk '{print -$1}'`i -O -K >> ${OUTFILE} << EOF
EOF

		done < tmpfile_4D_models # done Model loop.

		# Seal the page.
		gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

		Page=$((Page+1))
	done # done 4D loop.

	cat `ls -rt ?.ps` > ${OUTFILE_All}
	rm -f ?.ps

done # End of bin loop.

# Make PDF.
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${OUTFILE_WM}

# Clean up.

cd ${CODEDIR}

exit 0
