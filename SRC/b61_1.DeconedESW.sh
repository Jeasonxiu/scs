#!/bin/bash

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

# Plot parameters.
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

tmppsfile=DeconESF.ps

for EQ in ${EQnames}
do

    echo "    ==> Ploting Decon ESF for ${EQ}..."

    keys="<EVLO> <EVLA> <EVDE> <MAG>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
    EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
    EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`

    Range=1
    TIMEMIN=-20
    TIMEMAX=25
    DISTMIN=60
    DISTMAX=80

    DISTMIN=`echo ${DISTMIN}-${Range}/2 | bc -l`
    DISTMAX=`echo ${DISTMAX}+${Range}/2 | bc -l`

    # ===============================================
    #     ! ScS Traces !
    # ===============================================

    for Cate in `seq 1 ${CateN}`
    do
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${EQ}.ESF_DT "<STNM>" > tmpfile_stnm
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${EQ}.ESF_DT "<STNM> <D_T> <Polarity>" > tmpfile_stnm_dt_p
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "<STNM> <GCARC>" > tmpfile_stnm_gcarc
        ${BASHCODEDIR}/Findrow.sh tmpfile_stnm_gcarc tmpfile_stnm > tmpfile_in1
        ${BASHCODEDIR}/Findrow.sh tmpfile_stnm_dt_p tmpfile_stnm | awk '{print $2,$3}' > tmpfile_in2
        paste tmpfile_in1 tmpfile_in2 > tmpfile_in

        # weight information.
        Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${EQ}.ESF_DT  "<STNM> <Weight>" | awk '{if ($2>0) print $1}' > tmpfile_contributing

        rm tmpfile_filelist* 2>/dev/null
        while read stnm gcarc dt polarity
        do
            grep ^${stnm}$ tmpfile_contributing > /dev/null 2>&1
            if [ $? -ne 0 ]
            then
                echo ${gcarc} ${dt} ${polarity} `ls ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${stnm}.waveform` >> tmpfile_filelist_no
            else
                echo ${gcarc} ${dt} ${polarity} `ls ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${stnm}.waveform` >> tmpfile_filelist
            fi
        done < tmpfile_in

        if [ -s tmpfile_filelist_no ]
        then
            ${EXECDIR}/seis2xy.out 0 2 3 << EOF
tmpfile_filelist_no
xy.seismograms_${Cate}_no
${Range}
${TIMEMIN}
${TIMEMAX}
EOF
        fi

        if [ -s tmpfile_filelist ]
        then
            ${EXECDIR}/seis2xy.out 0 2 3 << EOF
tmpfile_filelist
xy.seismograms_${Cate}
${Range}
${TIMEMIN}
${TIMEMAX}
EOF
        fi

    done # done ScS traces on category loop.

    XSIZE=1.5
    YSIZE=5.5

    BY=`echo $DISTMIN $DISTMAX | awk '{print (int(int(($2-$1)/10)/5)+1)*5 }' |  awk '{print $1, $1/5}'`
    BY1=`echo ${BY}| awk '{print $1}'`
    BY2=`echo ${BY}| awk '{print $2}'`
    SCALE=X"$XSIZE"i/-"$YSIZE"i
    RANGE=$TIMEMIN/$TIMEMAX/$DISTMIN/$DISTMAX/

    OUTFILE=${EQ}.ps

    # plot some text
    pstext -JX10i/6.6i -R0/10/0/10 -K -N -Y1.5i > $OUTFILE << END
5 10 15 0 0 CB $EQ  LAT=$EVLA LON=$EVLO Z=$EVDE Mb=$EVMA Phase=$MainPhase Comp=T
END

    # plot the records
    for Cate in `seq 1 ${CateN}`
    do

        if [ ${Cate} -eq 1 ]
        then
            BAXIS="a10f5:Sec.:/a${BY1}f${BY2}:Distance(deg):WS"
            BAXIS2="f5/a1f0.5WS"
        else
            BAXIS="a10f5/f${BY2}WS"
            BAXIS2="f5/f0.5WS"
        fi

        if [ -s xy.seismograms_${Cate}_no ]
        then
            psxy xy.seismograms_${Cate}_no -J$SCALE -R$RANGE -W0.3p,${color[${Cate}]} -B"$BAXIS"WSne -m -O -K >> $OUTFILE
        fi

        psxy xy.seismograms_${Cate} -J$SCALE -R$RANGE -W0.3p,black -B"$BAXIS"WSne -m -O -K >> $OUTFILE

        psxy -J -R -O -K -Y`echo "${YSIZE}*1.05" | bc -l`i >> $OUTFILE << EOF
EOF

        paste ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/fullstack ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/fullstack.std > tmpfile_$$

        awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1.2 -W0.3p,black -B${BAXIS2} -O -K >> $OUTFILE

        awk '{print $1,$2+$4}' tmpfile_$$ | psxy -JX -R -W0.3p,gray -O -K >> $OUTFILE
        awk '{print $1,$2-$4}' tmpfile_$$ | psxy -JX -R -W0.3p,gray -O -K >> $OUTFILE

        psxy -J -R -O -K -Y-`echo "${YSIZE}*1.05" | bc -l`i >> $OUTFILE << EOF
EOF

        psxy -J -R -O -K -X`echo "${XSIZE}*1.1" | bc -l`i >> $OUTFILE << EOF
EOF
    done # done plotting of ScS traces over category loop.

    # ===============================================
    #     ! Deconed ScS Traces !
    # ===============================================

    rm tmpfile* xy.seismograms* 2>/dev/null

    for Cate in `seq 1 ${CateN}`
    do
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${EQ}.ESF_DT "<STNM>" > tmpfile_stnm
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${EQ}.ESF_DT "<STNM> <Polarity>" > tmpfile_stnm_p
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "<STNM> <GCARC>" > tmpfile_stnm_gcarc
        ${BASHCODEDIR}/Findrow.sh tmpfile_stnm_gcarc tmpfile_stnm > tmpfile_in1
        ${BASHCODEDIR}/Findrow.sh tmpfile_stnm_p tmpfile_stnm | awk '{print $2,$3}' > tmpfile_in2
        ${BASHCODEDIR}/Findrow.sh ${WORKDIR_Decon}/${EQ}/deconesf.${Cate}.shift tmpfile_stnm | awk '{print $2}' > tmpfile_in3
        paste tmpfile_in1 tmpfile_in2 tmpfile_in3 > tmpfile_in

        # weight information.
        awk '{if ($2>0) print $1}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate}.weight > tmpfile_contributing

        rm tmpfile_filelist* 2>/dev/null
        while read stnm gcarc polarity shift
        do
            grep ^${stnm}$ tmpfile_contributing > /dev/null 2>&1
            if [ $? -ne 0 ]
            then
                echo ${gcarc} ${polarity} ${shift} ${WORKDIR_Decon}/${EQ}/${stnm}.trace >> tmpfile_filelist_no
            else
                echo ${gcarc} ${polarity} ${shift} ${WORKDIR_Decon}/${EQ}/${stnm}.trace >> tmpfile_filelist
            fi

        done < tmpfile_in

        if [ -s tmpfile_filelist_no ]
        then
            ${EXECDIR}/seis2xy_pp.out 0 2 3 << EOF
tmpfile_filelist_no
xy.seismograms_${Cate}_no
${Range}
${TIMEMIN}
${TIMEMAX}
EOF
        fi

        if [ -s tmpfile_filelist ]
        then
            ${EXECDIR}/seis2xy_pp.out 0 2 3 << EOF
tmpfile_filelist
xy.seismograms_${Cate}
${Range}
${TIMEMIN}
${TIMEMAX}
EOF
        fi

    done

    BY=`echo $DISTMIN $DISTMAX | awk '{print (int(int(($2-$1)/10)/5)+1)*5 }' |  awk '{print $1, $1/5}'`
    BY1=`echo ${BY}| awk '{print $1}'`
    BY2=`echo ${BY}| awk '{print $2}'`
    SCALE=X"$XSIZE"i/-"$YSIZE"i
    RANGE=$TIMEMIN/$TIMEMAX/$DISTMIN/$DISTMAX/

    # plot the records
    for Cate in `seq 1 ${CateN}`
    do
        BAXIS="a10f5/f${BY2}"

        if [ -s xy.seismograms_${Cate}_no ]
        then
            psxy xy.seismograms_${Cate}_no -J$SCALE -R$RANGE -W0.3p,${color[${Cate}]} -B"$BAXIS"WSne -m -O -K >> $OUTFILE
        fi

        psxy xy.seismograms_${Cate} -J$SCALE -R$RANGE -W0.3p,black -B"$BAXIS"WSne -m -O -K >> $OUTFILE

        psxy -J -R -O -K -Y`echo "${YSIZE}*1.05" | bc -l`i >> $OUTFILE << EOF
EOF

        awk '{print $1,$2}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate} | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1.2 -W0.3p,black -B${BAXIS2} -O -K >> $OUTFILE

        awk '{print $1,$2+$3}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate} | psxy -JX -R -W0.3p,gray -O -K >> $OUTFILE
        awk '{print $1,$2-$3}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate} | psxy -JX -R -W0.3p,gray -O -K >> $OUTFILE

        psxy -J -R -O -K -Y-`echo "${YSIZE}*1.05" | bc -l`i >> $OUTFILE << EOF
EOF

        psxy -J -R -O -K -X`echo "${XSIZE}*1.1" | bc -l`i >> $OUTFILE << EOF
EOF
    done

# ===============================================
#     ! Plot compare !
# ===============================================

    psxy -J -R -O -K -X-`echo "${XSIZE}*5.5" | bc -l`i -Y-1.1i >> $OUTFILE << EOF
EOF

    for Cate in `seq 1 ${CateN}`
    do
        # find the peak position of S stacks.
        awk '{if ($1>-20 && $1<20) print $1,$2}' ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${Cate}/fullstack > tmpfile_$$
        awk '{if ($1>-20 && $1<20) print $2}' ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${Cate}/fullstack > tmpfile1_$$
        AMP=`${BASHCODEDIR}/amplitude.sh tmpfile1_$$`
        Time=`awk -v A=${AMP} '{if ($2==A || $2==-A) print $1}' tmpfile_$$ | awk 'NR==1 {print $1}'`

        awk -v T=${Time} '{print $1-T,$2}' ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${Cate}/fullstack > tmpfile_$$

        if [ ${Cate} -eq 1 ]
        then
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -Ba10f5/a1f0.5WS -O -K >> $OUTFILE
            pstext -JX -R -O -K -N >> $OUTFILE << EOF
`echo "${TIMEMIN}+1" | bc -l` -0.9 8 0 0 LB S_ESF
EOF
        else
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -O -K >> $OUTFILE
        fi

    done

    psxy -J -R -O -K -X`echo "${XSIZE}*1.1" | bc -l`i >> $OUTFILE << EOF
EOF

    for Cate in `seq 1 ${CateN}`
    do
        # find the peak position of stretched S stacks.
        awk '{if ($1>-20 && $1<20) print $1,$2}' ${WORKDIR_Decon}/${EQ}/${Cate}.esf > tmpfile_$$
        awk '{if ($1>-20 && $1<20) print $2}' ${WORKDIR_Decon}/${EQ}/${Cate}.esf > tmpfile1_$$
        AMP=`${BASHCODEDIR}/amplitude.sh tmpfile1_$$`
        Time=`awk -v A=${AMP} '{if ($2==A || $2==-A) print $1}' tmpfile_$$ | awk 'NR==1 {print $1}'`

        awk -v T=${Time} '{print $1-T,$2}' ${WORKDIR_Decon}/${EQ}/${Cate}.esf > tmpfile_$$

        if [ ${Cate} -eq 1 ]
        then
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -Ba10f5/f0.5WS -O -K >> $OUTFILE
            pstext -JX -R -O -K -N >> $OUTFILE << EOF
`echo "${TIMEMIN}+1" | bc -l` -0.9 8 0 0 LB S*_ESF
EOF
        else
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -O -K >> $OUTFILE
        fi

    done

    psxy -J -R -O -K -X`echo "${XSIZE}*1.1" | bc -l`i >> $OUTFILE << EOF
EOF

    for Cate in `seq 1 ${CateN}`
    do
        # find the peak position of ScS stacks.
        awk '{if ($1>-20 && $1<20) print $1,$2}' ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/fullstack > tmpfile_$$
        awk '{if ($1>-20 && $1<20) print $2}' ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/fullstack > tmpfile1_$$
        AMP=`${BASHCODEDIR}/amplitude.sh tmpfile1_$$`
        Time=`awk -v A=${AMP} '{if ($2==A || $2==-A) print $1}' tmpfile_$$ | awk 'NR==1 {print $1}'`

        awk -v T=${Time} '{print $1-T,$2}' ${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/fullstack > tmpfile_$$

        if [ ${Cate} -eq 1 ]
        then
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -Ba10f5/f0.5WS -O -K >> $OUTFILE
            pstext -JX -R -O -K -N >> $OUTFILE << EOF
`echo "${TIMEMIN}+1" | bc -l` -0.9 8 0 0 LB ScS_ESF
EOF
        else
            awk '{print $1,$2}' tmpfile_$$ | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -O -K >> $OUTFILE
        fi

    done

    psxy -J -R -O -K -X`echo "${XSIZE}*1.1" | bc -l`i >> $OUTFILE << EOF
EOF

    for Cate in `seq 1 ${CateN}`
    do
        if [ ${Cate} -eq 1 ]
        then
            awk '{print $1,$2}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate} | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1 -W1.5p,${color[${Cate}]} -Ba10f5/f0.5WS -O -K >> $OUTFILE
            pstext -JX -R -O -K -N >> $OUTFILE << EOF
`echo "${TIMEMIN}+1" | bc -l` -0.9 8 0 0 LB Decon_ESF
EOF
        else
            awk '{print $1,$2}' ${WORKDIR_Decon}/${EQ}/deconesf.${Cate} | psxy -JX${XSIZE}i/`echo "${XSIZE}*0.5" | bc -l`i -R${TIMEMIN}/${TIMEMAX}/-1/1.2 -W1.5p,${color[${Cate}]} -O -K >> $OUTFILE
        fi
    done

    # close up plot
    pstext -J -R -O >> $OUTFILE << END
END

    cat ${OUTFILE} >> ${tmppsfile}

    rm tmpfile* xy.seismograms* 2>/dev/null

done # Done EQ loop.

ps2pdf ${tmppsfile} ${WORKDIR_Plot}/DeconESF.pdf

exit 0
