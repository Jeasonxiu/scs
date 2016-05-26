#!/bin/bash

# ===========================================================
# Plot Catalog for DeconedScS.
#
# Shule Yu
# Nov 19 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_Catalog}/${PLOTPERPAGE_Catalog}| bc -l`
halfh=`echo ${height}/2 | bc -l`

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
    #     ! Check calculation result !
    # =========================================
    if ! [ -e ${WORKDIR_Decon}/ESW/${EQ}/*DT ]
    then
        echo "    ==> `basename $0`: Run a60 first on ${EQ}..."
        continue
    else
        echo "    ==> Plot DeconedScS catalog: ${EQ}."
    fi

    # ESF Parameters.
    E1=-15
    E2=15

    # Time tick file.
    rm tmptime1_$$ tmptime2_$$ 2>/dev/null
    for time in `seq -50 50`
    do
        echo " `echo "${time} * ${Tick_Catalog}" | bc -l` 0 " >> tmptime1_$$
        echo " `echo "${time} * ${Tick_Catalog} *10" | bc -l` 0 " >> tmptime2_$$
    done

    # EQ info.
    keys="<EVLO> <EVLA> <EVDE> <MAG>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
    EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
    EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`

    # ================================================
    #         ! Make Plot Data !
    # ================================================

    rm *.lst 2>/dev/null
    for cate in `seq 1 ${CateN}`
    do
        keys="<STNM>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Decon}/ESW/${EQ}/${EQ}.DeconedESW.DT "${keys}" > tmpfile_station_list
        awk -v D="${WORKDIR_Decon}/ESW/${EQ}" '{print D"/"$1".waveform"}' tmpfile_station_list > tmpfile1_$$

        keys="<STNM> <NETWK> <GCARC> <AZ> <BAZ> <STLO> <STLA>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_station_list | awk '{$1=""; print $0}' > tmpfile2_$$

        keys="<STNM> <D_T> <CCC> <SNR> <Weight> <Misfit> <Peak> <Polarity> <Rad_Pat> <Norm2> <N_T1> <N_T2> <S_T1> <S_T2>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Decon}/ESW/${EQ}/${EQ}.DeconedESW.DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_station_list | awk '{$1=""; print $0}' > tmpfile3_$$

        paste tmpfile_station_list tmpfile1_$$ tmpfile2_$$ tmpfile3_$$ | awk -v C=${cate} '{$(NF+1)=C; print $0}' > ${cate}.lst

    done

    cat `ls *.lst | sort -n ` > sorted.lst

    # Sort traces ...
    if [ "${Normalize}" -ne 1 ]
    then
        sort -g -k 22,22 sorted.lst > tmpfile_$$
        mv tmpfile_$$ sorted.lst
    else
        awk '{if ($12> 0) print $0}' sorted.lst > tmpfile1_$$
        awk '{if ($12==0) print $0}' sorted.lst > tmpfile2_$$
        sort -g -k 22,22 tmpfile1_$$ > sorted.lst
        sort -g -k 22,22 tmpfile2_$$ >> sorted.lst
    fi

#     sort -g -k 4,4 sorted.lst > tmpfile_$$
#     mv tmpfile_$$ sorted.lst

    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sorted.lst`

    page=0
    plot=$(($PLOTPERPAGE_Catalog+1))
    while read STNM file NETNM Gcarc AZ BAZ STLO STLA D_T CCC SNR Weight Misfit Peak Polarity Rad_Pat Norm2 N_T1 N_T2 S_T1 S_T2 cate
    do
        ## 4.2 check if need to plot on a new page.
        if [ ${plot} -eq $(($PLOTPERPAGE_Catalog+1)) ]
        then

            ### 4.2.1. if this isn't first page, seal the last page.
            if [ ${page} -gt 0 ]
            then
                psxy -J -R -O >> ${OUTFILE} << EOF
EOF
            fi

            ### 4.2.2 plot titles and legends
            plot=1
            page=$(($page+1))
            OUTFILE=${page}.ps
            title1="${MM}/${DD}/${YYYY}  DATA_CENTER: Merged PHASE: ${ReferencePhase} COMP: ${COMP}  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE} km. Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_Catalog} sec."
            title4="CCC SNR Weight"
            title5="NETNM STNM Misfit Norm2"
            title6="Gcarc D_T Rad_Pat"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
            pstext -J -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB $title2
EOF
            pstext -J -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB mul 1
EOF
            psxy -J -R -Y0.3i -O -K >> ${OUTFILE} << EOF
EOF
            #### 4.2.3 add legends of station info.
            pstext -JX${TEXTWIDTH_Catalog}i/${height}i -R-1/1/-1/1 -X${PLOTWIDTH_Catalog}i -Y-${height}i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB $title3
0 0 8 0 0 CB $title4
0 -0.5 8 0 0 CB $title5
0 -1 8 0 0 CB $title6
EOF
        fi # end new page test.

        ## go to the right position to plot seismograms.
        psxy -JX${PLOTWIDTH_Catalog}i/${height}i -R${PLOTTIMEMIN_Catalog}/${PLOTTIMEMAX_Catalog}/-1/1 -X-${PLOTWIDTH_Catalog}i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        ### plot shifted ESF window.
        psxy -J -R -W200/200/200 -G200/200/200 -L -O -K >> ${OUTFILE} << EOF
`echo "${D_T} + ${E1} " | bc -l` -1
`echo "${D_T} + ${E1} " | bc -l` 1
`echo "${D_T} + ${E2} " | bc -l` 1
`echo "${D_T} + ${E2} " | bc -l` -1
`echo "${D_T} + ${E1} " | bc -l` -1
EOF
        ### SNR window
        psxy -J -R -W100/100/200 -G100/100/200 -L -O -K >> ${OUTFILE} << EOF
${N_T1} -1
${N_T1} 1
${N_T2} 1
${N_T2} -1
${N_T1} -1
EOF
        psxy -J -R -W100/200/100 -G100/200/100 -L -O -K >> ${OUTFILE} << EOF
${S_T1} -1
${S_T1} 1
${S_T2} 1
${S_T2} -1
${S_T1} -1
EOF

        ### plot zero line with time marker.
        psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 0
${PLOTTIMEMAX_Catalog} 0
EOF
        psxy tmptime1_$$ -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE}
        psxy tmptime2_$$ -J -R -Sy0.05i -Gblack -O -K >> ${OUTFILE}

        ### PREM arrival. (t=zero)
        psvelo -J -R -Wblack -Gpurple -Se${halfh}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
0 -0.5 0 0.5
EOF
        ### picked arrival.
        psvelo -J -R -Wblack -Gred -Se${halfh}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
${D_T} 0.5 0 -0.5
EOF
        ### flip mark.
        if [ "${Polarity}" -eq 1 ]
        then
            psxy -J -R -Sc0.08i -Gred -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 1
EOF
            pstext -J -R -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 1 8 0 0 CM +
EOF
        else
            psxy -J -R -Sc0.08i -Gblue -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 1
EOF
            pstext -J -R -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 1 8 0 0 CM _
EOF
        fi

        AMP=1
        ### data. (flipped and normalize within plot window).
        if [ "${Normalize}" -ne 1 ]
        then
            awk -v T1=${PLOTTIMEMIN_Catalog} -v T2=${PLOTTIMEMAX_Catalog} '{if (  $1>T1 && $1<T2 ) print $2}' ${file} > tmpfile_$$
            AMP=`${BASHCODEDIR}/amplitude.sh tmpfile_$$`
        fi

        #### peak position.
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
${Peak} `echo "1.0/${AMP}" | bc -l`
EOF
        #### shifted empirical source. (normalize to AMP)
        awk -v S=${D_T} -v A=${AMP} '{print $1+S,$2/A}' ${WORKDIR_Decon}/ESW/${EQ}/${EQ}.ESF_F |  psxy -J -R -W0.3p,${color[${cate}]},- -O -K >> ${OUTFILE}
        #### waveform
        awk -v T1=${PLOTTIMEMIN_Catalog} -v T2=${PLOTTIMEMAX_Catalog} -v C=${Polarity} -v A=${AMP} '{ if (  $1>T1 && $1<T2 ) print $1,$2*C/A}' ${file} | psxy -J -R -W0.5p -O -K >> ${OUTFILE}

        ### plot indicator of weight < 0.
        if [ `echo "${Weight}>0" |bc` -ne 1 ]
        then
            psxy -J -R -Sx0.2i -Wthick,red -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Catalog} 0
EOF
        fi

        ## station info.
        pstext -JX${TEXTWIDTH_Catalog}i/${height}i -R/-1/1/-1/1 -X${PLOTWIDTH_Catalog}i -N -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${CCC}  ${SNR}   ${Weight}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 -0.5 10 0 0 CB ${NETNM}  ${STNM}  ${Misfit}  ${Norm2}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 -1 10 0 0 CB ${Gcarc}  ${D_T} sec. ${Rad_Pat}
EOF

        plot=$(($plot+1))

    done < sorted.lst # end of plot loop.

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF
    cat `ls *.ps | sort -n` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_DeconedESW.pdf

    rm -f ${WORKDIR_Plot}/tmpdir_$$/*

done # done EQ loop.

cd ${CODEDIR}

exit 0
