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
        echo "    ==> Stretch Plot: Run Stretch first for ${EQ}..."
        continue
    else
        echo "    ==> Plot Stretch result: ${EQ}."
    fi

    count=0

    for cate in `seq 1 ${CateN}`
    do
        CCC[${cate}]=0
    done
        
    for vstretch in `seq -0.1 0.01 0.15`
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


        REG="-R${V_TimeMin}/${V_TimeMax}/-1/1"
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
${V_TimeMin} -1.2 10 0 0 LB  EQ: ${EQ}
EOF
        pstext ${REG} ${PROJ} -Wred -O -N -K >> ${OUTFILE} << EOF
`echo "${V_TimeMin} ${V_TimeMax}" | awk '{print $1+($2-$1)/5}'` -1.2 10 0 0 LB Stretched S esf
EOF
        pstext ${REG} ${PROJ} -Wgreen -O -N -K >> ${OUTFILE} << EOF
`echo "${V_TimeMin} ${V_TimeMax}" | awk '{print $1+($2-$1)*2/5}'` -1.2 10 0 0 LB ScS esf
EOF
        pstext ${REG} ${PROJ} -O -N -K >> ${OUTFILE} << EOF
`echo "${V_TimeMin} ${V_TimeMax}" | awk '{print $1+($2-$1)*3.5/5}'` -1.2 10 0 0 LB V: ${vstretch}
EOF

        for cate in `seq 1 ${CateN}`
        do
            if ! [ -e ${WORKDIR_Stretch}/${EQ}/*F${cate}.stretched ]
            then
                continue
            fi

            Shift=`tail -n 1 ${WORKDIR_Stretch}/${EQ}/Stretch_Info.${cate} | awk '{print $3}'`

            psbasemap -R -J -Ba5g5f1/a0.5g0.1f0.1WSne -Y-${MVY}i -O -K >> ${OUTFILE}

            awk -v y=${vstretch} -v x=${Shift} '{print $1+x,($2+y)/(1+y)}' ${WORKDIR_Stretch}/${EQ}/${EQ}.ESF_F${cate}.stretched > tmpfile_stretched_S

            T1=-10
            T2=15
            psxy -Wblue -R -J -O -K -m >> ${OUTFILE} << EOF
${T1} 1
${T1} -1
>
${T2} 1
${T2} -1
EOF
            awk -v T1=${T1} -v T2=${T2} '{if (T1<$1 && $1<T2) print $1,$2}' tmpfile_stretched_S > tmpfile_S_compare
            awk -v T1=${T1} -v T2=${T2} '{if (T1<$1 && $1<T2) print $1,$2}' ${DATADIR_ScS}/${cate}/fullstack > tmpfile_ScS_compare

            # Plot original ScS.
            psxy ${DATADIR_ScS}/${cate}/fullstack -W0.02i,green -R -J -O -K >> ${OUTFILE}

            # Plot vertically stretched / shrinked S.
            psxy tmpfile_stretched_S -W0.02i,red -R -J -O -K >> ${OUTFILE}

            ${EXECDIR}/X_Corr.out 0 2 2 > tmpfile_Cout << EOF
tmpfile_S_compare
tmpfile_ScS_compare
5.0
${DELTA}
EOF
            CCC_previous[${cate}]=${CCC[${cate}]}
            CCC[${cate}]=`awk '{print $1}' tmpfile_Cout`

            if [ `echo "${CCC_previous[${cate}]}<${CCC[${cate}]}" | bc` -eq 1 ]
            then
                pstext -R -J -O -N -K -Wgreen >> ${OUTFILE} << EOF
0.1 -0.9 10 0 0 LB ${CCC[${cate}]}
EOF
            else
                pstext -R -J -O -N -K -Wred >> ${OUTFILE} << EOF
0.1 -0.9 10 0 0 LB ${CCC[${cate}]}
EOF
            fi


        done # done CateN loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF
    done # done dvstretch loop.

    # Make PDFs.
    cat `ls *ps | sort -n` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_VStretches.pdf

    rm *ps 2>/dev/null

done # done EQ loop.

cd ${CODEDIR}

exit 0
