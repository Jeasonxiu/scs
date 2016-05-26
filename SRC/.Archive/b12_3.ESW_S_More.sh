#!/bin/bash

# ===========================================================
# Plot ESF with STD / Station Distribution / Histograms.
#
# Shule Yu
# Oct 20 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

height_esf=`echo "${PLOTHEIGHT_ESF_STD}*6/7/${CateN}"| bc -l`
skip_esf=`echo "${PLOTHEIGHT_ESF_STD}/${CateN}"| bc -l`
hskip=`echo "${PLOTHEIGHT_Hist}/3" | bc -l`
wskip=`echo "${PLOTWIDTH_Hist}/4" | bc -l`
height=`echo "${hskip}*0.8" | bc -l`
width=`echo "${wskip}*0.75" | bc -l`

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

for EQ in ${EQnames}
do
    # =========================================
    #     ! Check the calculation result !
    # =========================================
    INFILE=${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/INFILE

    if ! [ -e ${INFILE} ]
    then
        echo "    ==> a54.plot_s_more.sh: Run a04.s.sh first on ${EQ}..."
        continue
    else
        echo "    ==> Plot ESF_STD / Hist. / Distribution of ${EQ}."
    fi

    DATAFILE=`ls ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/*DT`

    # Plot Parameters.
    OUTFILE=tmp.ps
    CateN=`grep "<CateN>"                                ${INFILE} | awk '{print $2}'` 
    E1=`grep "<${ReferencePhase}_E>"                     ${INFILE} | awk '{print $2}'`
    E2=`grep "<${ReferencePhase}_E>"                     ${INFILE} | awk '{print $3}'`
    CCCOFF=`grep "<CCCOFF>"                              ${INFILE} | awk '{print $2}'`
    SNRLOW=`grep "<SNRLOW>"                              ${INFILE} | awk '{print $2}'`
    SNRHIGH=`grep "<SNRHIGH>"                            ${INFILE} | awk '{print $2}'`

    # ================================================
    #         ! Make Plot Data !
    # ================================================

    # All. 
    keys="<EVLO> <EVLA> <EVMA>"
    ${BASHCODEDIR}/Findfield.sh ${DATAFILE} "${keys}" > tmpfile_$$
    EVLO=`head -n 1 tmpfile_$$ | awk '{print $1}'`
    EVLA=`head -n 1 tmpfile_$$ | awk '{print $2}'`
    EVMA=`head -n 1 tmpfile_$$ | awk '{print $3}'`

    # ESF_STD
    rm esf_std_infile.lst 2>/dev/null
    for count in `seq 1 ${CateN}`
    do
        paste `ls ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/*F${count}` `ls ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_T/*F${count}.std` > tmpfile1_$$
        awk '{print $1,+$4}' tmpfile1_$$ > tmpfile_std${count}
        awk '{print $1,-$4}' tmpfile1_$$ | tac >> tmpfile_std${count}
        NR_used=`grep "<Nrecord${count}_Used>" ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/STDOUT | awk '{print $2}'`
        Nrecord=`grep "<Nrecord${count}_All>" ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/STDOUT | awk '{print $2}'`
        echo ${count} `ls ${WORKDIR_ESF}/${EQ}_${ReferencePhase}_${COMP}/*F${count}` tmpfile_std${count} ${NR_used} ${Nrecord} >> esf_std_infile.lst
    done

    # Histograms.
    keys=`awk '{printf "<%s> ",$1}' ${WORKDIR}/${ReferencePhase}_file_${RunNumber}`
    ${BASHCODEDIR}/Findfield.sh ${DATAFILE} "${keys}" > tmpfile_$$
    awk '{ if ($11>0) $11=0 ; if ( $7!=0 ) print $0 }' tmpfile_$$ > tmpfile_mast
    cp tmpfile_$$ tmpfile_mast_1
    NR=`wc -l < tmpfile_mast`

    # Distribution.
    keys="<Cate> <STLO> <STLA> <Gcarc> <AZ>"
    ${BASHCODEDIR}/Findfield.sh ${DATAFILE} "${keys}" > tmpfile_$$
    NR_Dist=`wc -l < tmpfile_$$`
    RLOMIN=`minmax -C tmpfile_$$ | awk '{if ($3<0) print $3*1.05; else print $3*0.95}'`
    RLOMAX=`minmax -C tmpfile_$$ | awk '{if ($4<0) print $4*0.95; else print $4*1.05}'`
    RLAMIN=`minmax -C tmpfile_$$ | awk '{if ($5<0) print $5*1.05; else print $5*0.95}'`
    RLAMAX=`minmax -C tmpfile_$$ | awk '{if ($6<0) print $6*0.95; else print $6*1.05}'`
    for count in `seq 1 ${CateN}`
    do
        awk -v A=${count} '{ if ($1==A) print $2,$3}' tmpfile_$$ > tmpfile_stations_${count}
        awk -v A=${count} '{ if ($1==A) print $4,$5}' tmpfile_$$ > tmpfile_gcarc_az_${count}
    done

    # ===========================
    #         ! Plot !
    # ===========================

    # 1. ESF_STD.

    rm ${OUTFILE} 2>/dev/null
    REG="-R${E1}/${E2}/-1/1.2"
    PROJ="-JX${PLOTWIDTH_ESF_STD}i/${height_esf}i"
    PROJ_text="-JX${TEXTWIDTH_ESF_STD}i/${height_esf}i"

    pstext ${REG} ${PROJ} -Y11i -P -N -K > ${OUTFILE} << EOF
${E1} -1.2 10 0 0 LB  EQ: ${EQ} for ${ReferencePhase}. X-Y: time(sec.) - amp
EOF

    while read cate esffile stdfile NR_used Nrecord
    do
        # plot std and esf.
        psxy ${stdfile} ${REG} ${PROJ} -Ggray -L -Y-${skip_esf}i -Bg5/g0.5WSne -O -K >> ${OUTFILE}
        psxy ${esffile} ${REG} ${PROJ} -Ba5f1/a0.5f0.1WSne -O -K >> ${OUTFILE}

        # plot onset on esf (t=zero).
        psxy ${REG} ${PROJ} -Wblack -Gred -St0.2i -N -O -K >> ${OUTFILE} << EOF
0 0
EOF
        # info.
        pstext ${PROJ_text} -R-1/1/-1/1.2 -X${PLOTWIDTH_ESF_STD}i -N -O -K >> ${OUTFILE} << EOF
0 0.5 14 0 0 CB Category: ${cate}
0 0 14 0 0 CB #: ${NR_used} / ${Nrecord}
EOF
        pstext -J -R -X-${PLOTWIDTH_ESF_STD}i -O -K >> ${OUTFILE} << EOF
EOF

    done < esf_std_infile.lst # end of plot loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_ESF_STD_${ReferencePhase}.pdf


    # 2. Histograms. 

    rm ${OUTFILE} 2>/dev/null
    title="${EQ} Histogram Results. ( Phase: ${ReferencePhase}, Weight>0 , NR:${NR} , CCClow: ${CCCOFF}, SNRLow: ${SNRLOW}, SNRhigh: ${SNRHIGH} )"
    pstext -R-1/1/-1/1 -JX${PLOTWIDTH_Hist}i/1i -Y7.6i -N -K > ${OUTFILE} << EOF
0 0 14 0 0 CB ${title}
EOF
    pstext -R -J -Y`echo "0.6-${hskip}"| bc -l`i -O -K >> ${OUTFILE} << EOF
EOF
    count=0
    ylabel="Freq."
    YMIN=0
    while read xlabel XMIN XMAX XINC XNUM
    do
        count=$((count+1))
        if [ "${count}" -eq 7 ] || [ "${count}" -eq 8 ]
        then
            Mast="tmpfile_mast_1"
        else
            Mast="tmpfile_mast"
        fi

        awk -v C=${count} '{print $C}' ${Mast} > histo.dat

        #==========  x axis ==========
        binN=`echo "( $XMAX - $XMIN ) / $XINC " | bc`
        XMAX=`echo "$XMIN + $XINC * $binN" | bc -l`

        #==========  y axis ==========
        pshistogram histo.dat -W${XINC} -IO > tmpfile_$$
        YMAX=`minmax -C tmpfile_$$ | awk '{print 1.2*$4+10 }'`
        YMAX=`echo "${YMAX}/10*10" | bc `
        YNUM=`echo "${YMAX}/5" | bc `
        YINC=`echo "${YNUM}/2" | bc `

        #==========  plot histogram ==========
        xmove=`echo "${count}-$((count-1))/4*4-1" | bc`
        ymove=`echo "$((count-1))/4" | bc`
        xmove=`echo "${xmove}*${wskip}" | bc -l`
        ymove=`echo "${ymove}*${hskip}" | bc -l`

        pshistogram histo.dat -R$XMIN/$XMAX/$YMIN/$YMAX -JX${width}i/${height}i -W$XINC -L0.5p -G${color[${CateN}]} -X${xmove}i -Y-${ymove}i -O -K >> ${OUTFILE}

        for count2 in `seq 2 $((CateN-1))| sort -r`
        do
            awk -v A=${count2} -v C=${count} '{ if ($1<=A) print $C}' ${Mast} > tmpfile_plot
            pshistogram tmpfile_plot -R -J -W${XINC} -L0.5p -G${color[${count2}]} -O -K >> ${OUTFILE}
        done

        awk -v C=${count} '{ if ($1==1) print $C}' ${Mast} > tmpfile_plot1
        if [ "${count}" -eq 1 ] || [ "${count}" -eq 5 ] || [ "${count}" -eq 9 ] 
        then
            pshistogram tmpfile_plot1 -R$XMIN/$XMAX/$YMIN/$YMAX -JX${width}i/${height}i -W$XINC -L0.5p -G${color[1]} \
                -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}
        else
            pshistogram tmpfile_plot1 -R$XMIN/$XMAX/$YMIN/$YMAX -JX${width}i/${height}i -W$XINC -L0.5p -G${color[1]} \
                -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}WS -O -K >> ${OUTFILE}
        fi

        psxy -J -R -X-${xmove}i -Y${ymove}i -O -K >> ${OUTFILE} << EOF
EOF
    done < ${WORKDIR}/${ReferencePhase}_file_${RunNumber}

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF
    ps2pdf ${OUTFILE} ${WORKDIR_Plot}/${EQ}_ESF_Hist_${ReferencePhase}.pdf

    # 3. Distribution.

    rm ${OUTFILE} 2>/dev/null
    title="Station Distribution of ${EQ}. NSTA: ${NR_Dist}"
    pstext -R-1/1/-1/1 -JX${PLOTWIDTH_Dist}i/1i -Y10i -N -P -K > ${OUTFILE} << EOF
0 0 14 0 0 CB ${title}
EOF

    # figure1.
    xscale=`echo "${PLOTWIDTH_Dist}/(${RLOMAX} - ${RLOMIN})" | bc -l`
    yscale=`echo "${PLOTHEIGHT_Dist}/(${RLAMAX} - ${RLAMIN})" | bc -l`
    PROJ="-Jx${xscale}id/${yscale}id"
    PROJ1="-JX${PLOTWIDTH_Dist}i/${PLOTHEIGHT_Dist}i"
    REG="-R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX}"

    psbasemap ${REG} ${PROJ1} -Ba5g5f1:"Longitude":/a10g10f5:"Latitude":WSne -X-0.1i -Y-4i -O -K >> ${OUTFILE}
    pscoast ${REG} ${PROJ} -Dl -A40000 -Wgray -O -K >> ${OUTFILE}
    for count in `seq 1 ${CateN}`
    do
        if [ -s tmpfile_stations_${count} ]
        then
            psxy tmpfile_stations_${count} ${PROJ} ${REG} -St`echo "0.02/${xscale}" | bc -l`i -G${color[${count}]} -O -K >> ${OUTFILE}
        fi
    done

    # figure2.
    cat tmpfile_gcarc_az* | awk '{ if ($2<180) print $1,$2+360; else print $1,$2}' > tmpfile_gcarc_az
    INFO=`minmax -C tmpfile_gcarc_az`
    GMIN=`echo "${INFO}" | awk '{print $1-2}'`
    GMAX=`echo "${INFO}" | awk '{print $2+2}'`
    AZMIN=`echo "${INFO}" | awk '{print $3-1}'`
    AZMAX=`echo "${INFO}" | awk '{print $4+1}'`
    PROJ="-JX${PLOTWIDTH_Dist}i/${PLOTHEIGHT_Dist}i"
    REG="-R${GMIN}/${GMAX}/${AZMIN}/${AZMAX}"
    psbasemap ${REG} ${PROJ} -Ba5f1:"Gcp distance (deg.)":/a10f5:"Azimuth (deg.)":WSne -X-0.1i -Y-5.2i -O -K >> ${OUTFILE}
    for count in `seq 1 ${CateN}`
    do
        if [ -s tmpfile_gcarc_az_${count} ]
        then
            psxy tmpfile_gcarc_az_${count} ${PROJ} ${REG} -St0.1i -G${color[${count}]} -N -O -K >> ${OUTFILE}
        fi
    done # done cate loop.

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF
    ps2pdf ${OUTFILE} ${WORKDIR_Plot}/${EQ}_ESF_Distri.pdf

done # done EQ loop.

exit 0
