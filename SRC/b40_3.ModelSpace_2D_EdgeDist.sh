#!/bin/bash

# ===========================================================
# Plot 2D Modeling space.
#
# Shule Yu
# May 19 2015
# ===========================================================

if [ "${Method_MS}" = "Waterlevel" ]
then
    FRSDIR=${WORKDIR_WaterFRS}
elif [ "${Method_MS}" = "Ammon" ]
then
    FRSDIR=${WORKDIR_AmmonFRS}
elif [ "${Method_MS}" = "Subtract" ]
then
    FRSDIR=${WORKDIR_SubtractFRS}
else
    FRSDIR=${WORKDIR}/CompareFRS
fi

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple

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
scaleX=`echo "${PLOTWIDTH_MS} ${PropertyX_MIN} ${PropertyX_MAX} ${PropertyX_INC}" | awk '{print $1/($3-$2+$4)}'`
scaleY=`echo "${PLOTHEIGHT_MS} ${PropertyY_MIN} ${PropertyY_MAX} ${PropertyY_INC}" | awk '{print $1/($3-$2+$4)}'`

# Prepare selected model properties.

keys="<EQ> <${PropertyX_MS}> <${PropertyY_MS}> <${PropertyZ_MS}>"
${BASHCODEDIR}/Findfield.sh ${DATADIR}/index "${keys}" | awk -v A=${PropertyX_MIN} -v B=${PropertyX_MAX} -v C=${PropertyY_MIN} -v D=${PropertyY_MAX} -v E=${PropertyZ_MIN} -v F=${PropertyZ_MAX} '{if ((A<=$2 && $2<=B) && (C<=$3 && $3<=D) && (E<=$4 && $4<=F)) print $0}' > model_x_y_z

keys="<EQ> <CenterPosition> <LateralSize>"
${BASHCODEDIR}/Findfield.sh ${DATADIR}/index "${keys}" > model_C_L

# Prepare plot trace info.
mysql -N -u shule ${SYNDB} > model_stnm_gcarc << EOF
select eq,stnm,gcarc from Master_a38 where wantit=1;
EOF

${EXECDIR}/EdgeDist.out 0 3 0 << EOF
${SRCDIR}/500_table.txt
model_stnm_gcarc
model_stnm_gcarc_hitloc
EOF

# Prepare amplitude ratio data.
rm -f model_stnm_amp
for EQ in ${EQnames}
do
	# Normalize to S.
	mysql -N -u shule ${SYNDB} >> model_stnm_amp << EOF
select eq,stnm,Amp_ScS/Amp_S from Master_a38 where wantit=1 and eq=${EQ};
EOF
	# Normalize to ScS.
# 	mysql -N -u shule ${SYNDB} >> model_stnm_amp << EOF
# select eq,stnm,1.0 from Master_a38 where wantit=1 and eq=${EQ};
# EOF
done

rm -f selectedmodels_x_y_z
for Model in ${EQnames}
do
    grep ${Model} model_x_y_z >> selectedmodels_x_y_z
done

# Plot.

for EdgeDist in `seq ${EdgeDist1_MS} ${EdgeDistINC_MS} ${EdgeDist2_MS}`
do

    echo "    ==> Plotting 2D ModelSpace, EdgeDist=${EdgeDist}."
    OUTFILE_All=tmpprefix_${EdgeDist}.plotfile


	Page=1
	for D4 in `seq ${Property4D_MIN} ${Property4D_INC} ${Property4D_MAX}`
	do

		# select models for D4.
		keys="<EQ> <${Property4D_MS}>"
		${BASHCODEDIR}/Findfield.sh ${DATADIR}/index "${keys}" | awk -v D4=${D4} '{if ($2==D4) print $1}'> tmpfile_$$
		rm -f tmpfile_4D_models
		for EQ in ${EQnames}
		do
			grep ${EQ} tmpfile_$$ >> tmpfile_4D_models 2>/dev/null
		done

		OUTFILE=${Page}.ps

		### plot titles and legends
		cat > tmpfile_$$ << EOF
0 105 ${Marker_MS} ModelSpace, EdgeDist ${EdgeDist}, ${Property4D_MS} = ${D4} ${Property4D_Label}
EOF

		gmt pstext tmpfile_$$ -JX10.0i/7.5i -R-100/100/-100/100 -F+jCB+f15p,1,black -Xf0.5i -Yf0.5i -N -K > ${OUTFILE}

		## go to the right position to plot basemap.
		rm -f tmpfile_$$
		for Y in `seq ${PropertyY_MIN} ${PropertyY_INC} ${PropertyY_MAX}`
		do
			cat >> tmpfile_$$ << EOF
`echo "${PropertyX_MIN} ${scaleX}"|awk '{print $1-0.1/$2}'` ${Y}
EOF
		done

		for X in `seq ${PropertyX_MIN} ${PropertyX_INC} ${PropertyX_MAX}`
		do
			cat >> tmpfile_$$ << EOF
${X} `echo "${PropertyY_MIN} ${PropertyY_INC}"|awk '{print $1-$2/2}'`
EOF
		done

		gmt psxy tmpfile_$$ -Sc0.05i -Gblack -N -JX`echo ${PLOTWIDTH_MS} | awk '{print $1+0.1}'`i/${PLOTHEIGHT_MS}i -R`echo "${PropertyX_MIN} ${scaleX}"|awk '{print $1-0.1/$2}'`/`echo "${PropertyX_MAX} ${PropertyX_INC}"|awk '{print $1+$2}'`/`echo "${PropertyY_MIN} ${PropertyY_INC}"|awk '{print $1-$2/2}'`/`echo "${PropertyY_MAX} ${PropertyY_INC}"|awk '{print $1+$2/2}'` -Ba${PropertyX_INC}f`echo ${PropertyX_INC} | awk '{print $1/2}'`:"${PropertyX_Label}":/a`echo ${PropertyY_INC} | awk '{print $1/2}'`f`echo ${PropertyY_INC} | awk '{print $1/2}'`:"${PropertyY_Label}":WS -Xf0.6i -Yf0.5i -O -K >> ${OUTFILE} << EOF
EOF

		## go to the right position (preparing to plot seismograms)
		gmt psxy -JX`echo "0.9*${PropertyX_INC}*${scaleX}"|bc -l`i/`echo "0.6*${PropertyY_INC}*${scaleY}"| bc -l`i -R${TIMEMIN_MS}/${TIMEMAX_MS}/-1/1 -X0.1i -Y`echo "0.1 ${PropertyY_INC} ${scaleY}"|awk '{print $1*$2*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

		while read Model
		do

			INFO=`grep ${Model} model_C_L`
			C=`echo "${INFO}" | awk '{print $2}'`
			L=`echo "${INFO}" | awk '{print $3/60.737458}'`

			grep ${Model} model_stnm_gcarc_hitloc | awk -v D=${FRSDIR} '{print $4" "D"/"$1"_"$2".frs "$3}' | sort -g -k 1,1 > tmpfile_$$


			gcarc="-1"
			while read hitloc filename Gcp
			do
				if [ `echo "${hitloc} ${C} ${L} ${EdgeDist}" | awk '{if ($1-$2+$3/2-$4>0) print 1; else print 0}'` -eq 1 ]
				then
					file=${filename}
					gcarc=${Gcp}
					break
				fi
			done < tmpfile_$$


			# Check if the need trace is not included within the slected plot range.
			if [ `echo "${gcarc} ${DISTMIN}" | awk '{if ($1-$2<=0) print 1; else print 0}'` -eq 1 ]
			then
				continue
			fi

			stnm=`echo "${file}" | awk 'BEGIN {FS="_"} {print $3}' | awk 'BEGIN {FS="."} {print $1}'`
			AMP=`grep ${Model} model_stnm_amp | grep ${stnm} | awk '{print $3}'`

			if ! [ -e ${file} ]
			then
				continue
			fi

			### get model parameters.
			INFO=`grep ${Model} selectedmodels_x_y_z`

			X=`echo "${INFO}" | awk '{print $2}'`
			Y=`echo "${INFO}" | awk '{print $3}'`
			Z=`echo "${INFO}" | awk '{print $4}'`

			# ===================================
			#        ! Plot !
			# ===================================

			MVX=`echo "${X} ${scaleX} ${PropertyX_MIN}" | awk '{printf "%.3f",($1-$3)*$2}'`
			MVY=`echo "${Y} ${scaleY} ${PropertyY_MIN} ${Z} ${PropertyZ_MIN} ${PropertyZ_INC}" | awk '{printf "%.3f",($1-$3)*$2+(($4-$5)/$6-1.5)*0.4}'`

			### go to the correct positoin.
			gmt psxy -J -R -X${MVX}i -Y${MVY}i -O -K >> ${OUTFILE} << EOF
EOF
			if [ `echo "${Z}>${PropertyZ_MIN}" | bc ` -ne 1 ]
			then

				#### plot time axis.
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

				### Add a text of gcarc.
				cat > tmpfile_$$ << EOF
`echo "${TIMEMIN_MS}" | awk '{print $1+0.1}'` -0.1 GCP: ${gcarc}
EOF
				gmt pstext tmpfile_$$ -J -R -F+jLT+f5p,0,black -N -O -K >> ${OUTFILE}
			fi

			### plot FRS's.
			Num=`echo "(${Z}-${PropertyZ_MIN})/${PropertyZ_INC}"|bc`
			awk -v A=${AMP} '{print $1,$2*A}' ${file} | gmt psxy -J -R -W0.5p,${color[$((Num+1))]} -N -O -K >> ${OUTFILE}

			### plot text.
			cat > tmpfile_$$ << EOF
${TIMEMAX_MS} 0.1 `echo ${Z} | awk '{print $1*100}'`${PropertyZ_Label}
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

	cat `ls -rt *.ps` > ${OUTFILE_All}
	rm -f *.ps

done # End of Edge distance loop.

# Make PDF.
Title=`basename $0`
cat `ls -rt tmpprefix_*.plotfile` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

# Clean up.

cd ${CODEDIR}

exit 0
