#!/bin/bash

# ===========================================================
# Plot Stretching result.
#
# Shule Yu
# Oct 27 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 10p
gmtset LABEL_OFFSET = 0.05c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200,.

count=0
for EQ in ${EQnames}
do
    count=$((count+1))

    # =========================================
    #     ! Check the calculation result !
    # =========================================
    INFILE=${WORKDIR_Stretch}/${EQ}/INFILE

    if ! [ -e ${INFILE} ]
    then
		echo "    ~=> Run a16. first for ${EQ}..." 
        continue
    else
        echo "    ==> Plot Stretch result: ${EQ}."
    fi

    # Stretch Parameters.
    DATADIR_S=${WORKDIR_ESF}/${EQ}_${ReferencePhase}
    DATADIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}
    CateN=`grep "<CateN>" ${INFILE} | awk '{print $2}'`

    # ===========================
    #         ! Plot !
    # ===========================

    REG="-R${PLOTTIMEMIN_S}/${PLOTTIMEMAX_S}/-1/1"
	if [ ${CateN} -ge 3 ]
	then
		PROJ="-JX7i/`echo "10.5 *6 / 7 / ${CateN}" | bc -l`i"
		MVY=`echo ${CateN} | awk '{print 10.5/$1}'`
	else
		PROJ="-JX7i/`echo "10.5 *6 / 7 / 3" | bc -l`i"
		MVY=`echo 3 | awk '{print 10.5/3}'`
	fi
    OUTFILE=${count}.ps

    # Plot fancy title.
    pstext ${REG} ${PROJ} -Y11i -P -N -K > ${OUTFILE} << EOF
${PLOTTIMEMIN_S} -1.2 10 0 0 LB  EQ: ${EQ}
EOF
	pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/5}'` -1.2 10 0 0 LB @;255/0/0;Stretched S(S)@;;
EOF
	pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*2/5}'` -1.2 10 0 0 LB @;0/255/0;ScS(Stretch ScS)@;;
EOF
	pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*3/5}'` -1.2 10 0 0 LB @;128/0/128;S(ScS)@;;
EOF

    for cate in `seq 1 ${CateN}`
    do

        if ! [ -e ${WORKDIR_Stretch}/${EQ}/*F${cate}.stretched ]
        then
            continue
        fi

		# Measurements.
		H=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate} | awk '{print $1}'`
		V=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate} | awk '{print $2}'`
		ccc=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate} | awk '{print $3}'`
		dt=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate} | awk '{print $4}'`
		Diff=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.Best.${cate} | awk '{print $5}'`

        psbasemap -R -J -Ba5g5f1/a0.5g0.1f0.1WSne -Y-${MVY}i -O -K >> ${OUTFILE}

        # Plot stretch / shrink boundary.
        psxy ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_1_1.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}
        psxy ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_1_${nXStretch}.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}
        psxy ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_${nYStretch}_1.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}
        psxy ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_${nYStretch}_${nXStretch}.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}

        # Plot CC compare level.
        psxy -R -J -Wblue -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_S} ${AMPlevel_Default}
${PLOTTIMEMAX_S} ${AMPlevel_Default}
EOF


		if [ `echo "${H}>=0" | bc` -eq 1 ]
		then

			# Plot original S.
			awk '{print $1,$2}' ${WORKDIR_Stretch}/${EQ}/plotfile_shifted_original_${cate} | psxy -W0.02i,purple,- -R -J -O -K >> ${OUTFILE}

			# Plot original ScS.
			psxy `ls ${DATADIR_ScS}/${cate}/fullstack` -W0.02i,green -R -J -O -K >> ${OUTFILE}

			# Plot stretched / shrinked S.
			awk -v T=${dt} '{print $1-T,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched | psxy -W0.02i,red -R -J -O -K >> ${OUTFILE}

		else

			# Plot original ScS.
			awk '{print $1,$2}' ${WORKDIR_Stretch}/${EQ}/plotfile_shifted_original_${cate} | psxy -W0.02i,purple,- -R -J -O -K >> ${OUTFILE}

			# Plot original S.
			psxy `ls ${DATADIR_S}/${cate}/fullstack` -W0.02i,red -R -J -O -K >> ${OUTFILE}
# 			awk '{print $1+3,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched | psxy -W0.02i,cyan -R -J -O -K >> ${OUTFILE}

			# Plot stretched / shrinked ScS.
			awk -v T=${dt} '{print $1-T,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.newScS | psxy -W0.02i,green -R -J -O -K >> ${OUTFILE}

		fi

        # Add Info.

        pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/100}'` -0.95 10 0 0 LB Tstar: ${H}
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*26/100}'` -0.95 10 0 0 LB VStretch: ${V}
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*51/100}'` -0.95 10 0 0 LB CCC: ${ccc}
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*76/100}'` -0.95 10 0 0 LB Diff: ${Diff}
EOF

    done # done CateN loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # done EQ loop.

# Make PDFs.
Title=`basename $0`
cat `ls -rt *ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${WORKDIR}

exit 0
