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
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

for EQ in ${EQnames}
do

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

    Vlevel=`grep ${EQ} ${WORKDIR}/EQ_Stretch_${RunNumber} | awk 'NR==1 {print $5,$6,$7}'`
    Vlevel=`echo ${Vlevel}`
    if [ -z "${Vlevel}" ]
    then
        Vlevel="0 0 0"
    fi

    count=0
    for hstretch in `seq -0.35 0.02 0.20`
    do
        count=$((count+1))

        # Stretch Parameters.
        DATADIR_S=${WORKDIR_ESF}/${EQ}_${ReferencePhase}
        DATADIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}
        CateN=`grep "<CateN>"             ${INFILE} | awk '{print $2}'`
        nStretch=`grep "<nStretch>"       ${INFILE} | awk '{print $2}'`

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
        pstext ${REG} ${PROJ} -Wred -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)/5}'` -1.2 10 0 0 LB Stretched S esf
EOF
        pstext ${REG} ${PROJ} -Wgreen -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*2/5}'` -1.2 10 0 0 LB ScS esf
EOF
        pstext ${REG} ${PROJ} -Wpurple -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*3/5}'` -1.2 10 0 0 LB S esf
EOF
        pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*3.5/5}'` -1.2 10 0 0 LB H: ${hstretch}
EOF
        pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${PLOTTIMEMIN_S} ${PLOTTIMEMAX_S}" | awk '{print $1+($2-$1)*4/5}'` -1.2 10 0 0 LB V: ${Vlevel}
EOF

        for cate in `seq 1 ${CateN}`
        do
            if ! [ -e ${WORKDIR_Stretch}/${EQ}/*F${cate}.stretched ]
            then
                continue
            fi

            psbasemap -R -J -Ba5g5f1/a0.5g0.1f0.1WSne -Y-${MVY}i -O -K >> ${OUTFILE}

            # Plot CC compare level.
            psxy -R -J -Wblue -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_S} ${hstretch} 
${PLOTTIMEMAX_S} ${hstretch}
EOF

            # Plot original S.
#             psxy ${WORKDIR_Stretch}/${EQ}/plotfile_${cate}_${ReferencePhase}_Shifted -W0.02i,purple -R -J -O -K >> ${OUTFILE}
            vstretch=`echo ${Vlevel} | awk -v C=${count} '{print $C}'`

            # Plot original ScS.
            psxy `ls ${DATADIR_ScS}/${cate}/fullstack` -W0.02i,green -R -J -O -K >> ${OUTFILE}

            dt=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $3}'`
            # Plot stretched / shrinked S.
            awk -v T=${dt} '{print $1+T,$2}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched | psxy -W0.02i,red -R -J -O -K >> ${OUTFILE}

        done # done CateN loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF
    done # done dvstretch loop.

    # Make PDFs.
    cat `ls *ps | sort -n` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_HStretches.pdf

    rm *ps 2>/dev/null

done # done EQ loop.

cd ${CODEDIR}

exit 0
