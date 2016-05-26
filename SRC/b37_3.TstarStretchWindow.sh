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
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

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
        echo "    ==> Stretch Plot: Run work_main.sh first for ${EQ}..."
        continue
    else
        echo "    ==> Plot Stretch result: ${EQ}."
    fi

    # Stretch Parameters.
    DATADIR_S=${WORKDIR_ESF}/${EQ}_${ReferencePhase}
    DATADIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}
    CateN=`grep "<CateN>"             ${INFILE} | awk '{print $2}'`
    nXStretch=`grep "<nXStretch>"       ${INFILE} | awk '{print $2}'`


	# Model Info.
	keys="<EQ> <Vs> <Rho> <LateralSize> <Thickness>"
# 	keys="<EQ> <Vs_Bot> <Rho_Bot> <Thickness>"
	INFO=`${BASHCODEDIR}/Findfield.sh ${SYNDATADIR}/index "${keys}" > tmpfile_$$`
	INFO=`grep ${EQ} tmpfile_$$ | awk '{print $0}'`

	Vs_Change=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
	Rho_Change=`echo "${INFO}" | awk '{printf "%.2lf",$3}'`
	LateralSize=`echo "${INFO}" | awk '{printf "%.2lf",$4}'`
	Thickness=`echo "${INFO}" | awk '{printf "%.2lf",$5}'`

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

    if [ -e ${WORKDIR_Stretch}/${EQ}/S_GET_Tstarred ]
	then
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/5}'` -1.2 10 0 0 LB @;255/0/0;Tstarred S@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*2/5}'` -1.2 10 0 0 LB @;0/255/0;ScS@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*3/5}'` -1.2 10 0 0 LB @;128/0/128;S@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*4/5}'` -1.2 10 0 0 LB Vs: ${Vs_Change}  H: ${Thickness} km. LS: ${LateralSize} km.  Rho: ${Rho_Change}.
EOF
	else
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/5}'` -1.2 10 0 0 LB @;0/255/0;Tstarred ScS@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*2/5}'` -1.2 10 0 0 LB @;128/0/128;ScS@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*3/5}'` -1.2 10 0 0 LB @;255/0/0;S@;;
EOF
		pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*4/5}'` -1.2 10 0 0 LB Vs: ${Vs_Change}  H: ${Thickness} km. LS: ${LateralSize} km.  Rho: ${Rho_Change}.
EOF
	fi



    for cate in `seq 1 ${CateN}`
    do

        if ! [ -e ${WORKDIR_Stretch}/${EQ}/*F${cate}.stretched ]
        then
            continue
        fi

        psbasemap -R -J -Ba5g5f1/a0.5g0.1f0.1WSne -Y-${MVY}i -O -K >> ${OUTFILE}

        # Plot stretch / shrink boundary.
        psxy ${WORKDIR_Stretch}/${EQ}/tmpfile_${cate}_1.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}
        psxy ${WORKDIR_Stretch}/${EQ}/tmpfile_${cate}_${nXStretch}.Tstarred -R -J -Wyellow -O -K >> ${OUTFILE}

        # Plot CC compare level.
        psxy -R -J -Wblue -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_S} ${AMPlevel_Default}
${PLOTTIMEMAX_S} ${AMPlevel_Default}
EOF


		# original S or ScS.
		awk '{print $1,$2}' ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_${ReferencePhase}_Shifted | psxy -W0.02i,purple,- -R -J -O -K >> ${OUTFILE}

		if [ -e ${WORKDIR_Stretch}/${EQ}/S_GET_Tstarred ]
		then

			# original ScS.
			psxy `ls ${DATADIR_ScS}/${cate}/fullstack` -W0.02i,green -R -J -O -K >> ${OUTFILE}

			# Plot stretched / shrinked S.
			dt=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $3}'`
			awk -v T=${dt} '{print $1-T,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched | psxy -W0.02i,red -R -J -O -K >> ${OUTFILE}

		else
			# Plot stretched / shrinked ScS.
			dt=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $3}'`
			awk -v T=${dt} '{print $1-T,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ScS.stretched | psxy -W0.02i,green -R -J -O -K >> ${OUTFILE}
			# original S.
			psxy `ls ${DATADIR_S}/${cate}/fullstack` -W0.02i,red -R -J -O -K >> ${OUTFILE}

		fi

        # Add Info.
        ratio=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $1}'`
        ccc=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $2}'`
        Diff=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $4}'`
        pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/100}'` -0.95 10 0 0 LB Tstar: ${ratio}
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*26/100}'` -0.95 10 0 0 LB CCC: ${ccc}
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*51/100}'` -0.95 10 0 0 LB Diff: ${Diff}
EOF

    done # done CateN loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # done EQ loop.

# Make PDFs.
Title=`basename $0`
cat `ls -rt *ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${CODEDIR}

exit 0
