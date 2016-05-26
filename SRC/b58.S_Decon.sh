#!/bin/bash

# ===========================================================
# Plot Decon results.
#
# Shule Yu
# May 20 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_D}/${PLOTPERPAGE_D}/2 | bc -l`
doubleh=`echo ${height}*2 | bc -l`
halfh=`echo ${height}/2 | bc -l`
quarth=`echo ${height}/4 | bc -l`

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
    INFILE=${WORKDIR_DeconS}/${EQ}/INFILE

    if ! [ -e ${INFILE} ]
    then
        echo "    ==> `basename $0`: Run a95.decon.sh first for ${EQ}..."
        continue
    else
        echo "    ==> Plotting S Deconvolution result: ${EQ}."

    fi

    # Decon Parameters.
    F1=`grep ${EQ}                              ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ}                              ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`
    order=`grep "<order>"                       ${INFILE} | awk '{print $2}'`
    passes=`grep "<passes>"                     ${INFILE} | awk '{print $2}'`
    N1_D=`grep "<N1_D>"                         ${INFILE} | awk '{print $2}'`
    N2_D=`grep "<N2_D>"                         ${INFILE} | awk '{print $2}'`
    S1_D=`grep "<S1_D>"                         ${INFILE} | awk '{print $2}'`
    S2_D=`grep "<S2_D>"                         ${INFILE} | awk '{print $2}'`
    AN=`grep "<AN>"                             ${INFILE} | awk '{print $2}'`
    Time=`grep "<Time>"                         ${INFILE} | awk '{print $2}'`

    keys="<EVLO> <EVLA> <EVDE> <MAG>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
    EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
    EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`

    RLOMIN=`grep "<RLOMIN>"                     ${INFILE} | awk '{print $2}'`
    RLOMAX=`grep "<RLOMAX>"                     ${INFILE} | awk '{print $2}'`
    RLAMIN=`grep "<RLAMIN>"                     ${INFILE} | awk '{print $2}'`
    RLAMAX=`grep "<RLAMAX>"                     ${INFILE} | awk '{print $2}'`

    xscale=`echo "${doubleh}/(${RLOMAX} - ${RLOMIN})" | bc -l`
    yscale=`echo "${doubleh}/(${RLAMAX} - ${RLAMIN})" | bc -l`

    # ================================================
    #         ! Make Plot Data !
    # ================================================

    keys="<STNM>"
    ${BASHCODEDIR}/Findfield.sh `ls ${WORKDIR_DeconS}/${EQ}/*Info` "${keys}" > tmpfile_stnm

    keys="<STNM> <SNR_1> <SNR_2> <SNR> <Shift_St> <CCC_St> <Misfit_St> <Cate> <N1Time> <S1Time> <N2Time> <N3Time>"
    ${BASHCODEDIR}/Findfield.sh `ls ${WORKDIR_DeconS}/${EQ}/*Info` "${keys}" | awk '{if ($6<0) $6=-$6; print $0}'> tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm > tmpfile_paste_1
    awk '{print $3*$4/($3+$4)}' tmpfile_paste_1 > tmpfile_$$
    ${BASHCODEDIR}/normalize.sh tmpfile_$$ | awk '{printf "%.2f\n",$1}' > tmpfile_paste_2

    keys="<STNM> <GCARC> <NETWK>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Basicinfo}/${EQ}.BasicInfo "${keys}" > tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0}' >> tmpfile_paste_3

    keys="<STNM> <Weight> <Peak> <Polarity>"
    rm tmpfile_paste_4 2>/dev/null
    for cate in `seq 1 ${CateN}`
    do
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0}' >> tmpfile_paste_4
    done


    keys="<STNM> <HITLO> <HITLA>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Sampling}/${EQ}.Hitlocation "${keys}" > tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0}' > tmpfile_paste_5

    paste tmpfile_paste_1 tmpfile_paste_2 tmpfile_paste_3 tmpfile_paste_4 tmpfile_paste_5 > sorted.lst

    # Sort traces.
    sort -g -r -k 6,6 sorted.lst > tmpfile_$$
    mv tmpfile_$$ sorted.lst


    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sorted.lst`

    page=0
    plot=$((PLOTPERPAGE_D+1))
    while read STNM SNR_1 SNR_2 SNR Shift_St CCC_St Misfit_St Cate N1Time S1Time N2Time N3Time WeightN1N2 Gcarc NETWK Weight_S peak_S Polarity HITLO HITLA
    do

        file=${WORKDIR_DeconS}/${EQ}/${STNM}.trace
        if ! [ -e ${file} ]
        then
            continue
        fi

        ## 4.2 check if need to plot on a new page.
        if [ ${plot} -eq $((PLOTPERPAGE_D+1)) ]
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
            title1="Decon plot ${MM}/${DD}/${YYYY}. PHASE: ${ReferencePhase} COMP: T  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE}  Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_D} sec."
            title4="SNR_1 SNR_2 SNR"
            title5="CCC_St Misfit_St WeightN1N2"
            title6="Gcarc NETWK STNM"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB $title1
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB $title2
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF
            psxy -J -R -Y0.3i -O -K >> ${OUTFILE} << EOF
EOF
            #### 4.2.3 add legends of station info.
            pstext -JX${TEXTWIDTH_D}i/${height}i -R-1/1/-1/1 -X${PLOTWIDTH_D}i -Y-${height}i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB $title3
0 0 8 0 0 CB $title4
0 -0.5 8 0 0 CB $title5
0 -1 8 0 0 CB $title6
EOF
        fi # end test if it's a new page.

        ## 4.3 go to the right position (preparing to plot seismograms)
        psxy -JX${PLOTWIDTH_D}i/${height}i -R${PLOTTIMEMIN_D}/${PLOTTIMEMAX_D}/-1/1 -X-${PLOTWIDTH_D}i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF


        ### 4.4.0 plot Checkbox.
        if [ ${page} -eq 1 ] && [ ${plot} -eq 1 ]
        then
            cat >> ${OUTFILE} << EOF
[ /_objdef {ZaDb} /type /dict /OBJ pdfmark
[ {ZaDb} <<
/Type /Font
/Subtype /Type1
/Name /ZaDb
/BaseFont /ZapfDingbats
>> /PUT pdfmark
[ /_objdef {Helv} /type /dict /OBJ pdfmark
[ {Helv} <<
/Type /Font
/Subtype /Type1
/Name /Helv
/BaseFont /Helvetica
>> /PUT pdfmark
[ /_objdef {aform} /type /dict /OBJ pdfmark
[ /_objdef {afields} /type /array /OBJ pdfmark
[ {aform} <<
/Fields {afields}
/DR << /Font << /ZaDb {ZaDb} /Helv {Helv} >> >>
/DA (/Helv 0 Tf 0 g)
/NeedAppearances true
>> /PUT pdfmark
[ {Catalog} << /AcroForm {aform} >> /PUT pdfmark
EOF
        fi

        cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/FT /Btn
/Rect [-180 -65 -50 65]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (4) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 0.196 0.80 0.196 rg)
/AP << /N << /${EQ}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF

        ### 4.4.1 plot zero line
        psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} 0
${PLOTTIMEMAX_D} 0
EOF
        for  time in `seq -50 50`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_D}" | bc -l` 0
EOF
        done

        ### 4.4.4. plot PREM arrival (t=zero).
        psvelo -J -R -Wblack -Gpurple -Se${halfh}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
0 0.5 0 -0.5
EOF

        ### plot esf.
        awk -v S=${Shift_St} '{print $1+S,$2}' ${WORKDIR_DeconS}/${EQ}/${Cate}.esf \
        | psxy -J -R -W0.3p,${color[$Cate]} -O -K >> ${OUTFILE}

#         ### picked arrival.
#         psvelo -J -R -Wblack -Gred -Se${halfh}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
# ${D_T} 0.5 0 -0.5
# EOF
        ### peak position.
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
0 1
EOF
        ### flip mark.
        if [ "${Polarity}" -eq 1 ]
        then
            psxy -J -R -Sc0.08i -Gred -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} -1
EOF
            pstext -J -R -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} -1 8 0 0 CM +
EOF
        else
            psxy -J -R -Sc0.08i -Gblue -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} -1
EOF
            pstext -J -R -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} -1 8 0 0 CM _
EOF
        fi

        ### waveform (flipped).
        awk -v P=${peak_S} -v C=${Polarity} -v T1=${PLOTTIMEMIN_D} -v T2=${PLOTTIMEMAX_D} '{ if (  ($1-P)>T1 && ($1-P)<T2 ) print $1-P,$2*C}' ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${Cate}/${STNM}.waveform \
        | psxy -J -R -W0.5p -O -K >> ${OUTFILE}

        ## add decon result.

        ## 4.6.0 add frs window.
        psxy -J -R -W100/100/100 -G100/100/100 -L -Y-${height}i -O -K >> ${OUTFILE} << EOF
`echo "${Time}"| bc -l` -1
`echo "${Time}"| bc -l` 1
`echo "-${Time}"| bc -l` 1
`echo "-${Time}"| bc -l` -1
`echo "${Time}"| bc -l` -1
EOF
        ### 4.6.2 Add SNR window.
        psxy -J -R -W50/50/200 -G50/50/200 -m -L -O -K >> ${OUTFILE} << EOF
${N1Time} -1
${N1Time} 1
`echo "${N1Time} + ${N2_D} - ${N1_D}" | bc -l` 1
`echo "${N1Time} + ${N2_D} - ${N1_D}" | bc -l` -1
${N1Time} -1
>
${N2Time} -1
${N2Time} 1
`echo "${N2Time} + ${AN}" | bc -l` 1
`echo "${N2Time} + ${AN}" | bc -l` -1
${N2Time} -1
>
${N3Time} -1
${N3Time} 1
`echo "${N3Time} + ${AN}" | bc -l` 1
`echo "${N3Time} + ${AN}" | bc -l` -1
${N3Time} -1
EOF

        psxy -J -R -W50/200/50 -G50/200/50 -L -O -K >> ${OUTFILE} << EOF
${S1Time} -1
${S1Time} 1
`echo "${S1Time} + ${S2_D} - ${S1_D}" | bc -l` 1
`echo "${S1Time} + ${S2_D} - ${S1_D}" | bc -l` -1
${S1Time} -1
EOF

        ### 4.6.1 plot zero line with time marker.
        psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} 0
${PLOTTIMEMAX_D} 0
EOF
        for  time in `seq -50 50`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_D}" | bc -l` 0
EOF
        done


        AMP=1
        ### data. (flipped and normalize within plot window).
        if [ "${Normalize_D}" -ne 1 ]
        then
            awk -v T1=${PLOTTIMEMIN_D} -v T2=${PLOTTIMEMAX_D} 'NR>1 {if (  $1>T1 && $1<T2 ) print $2}' ${file} > tmpfile_$$
            AMP=`${BASHCODEDIR}/amplitude.sh tmpfile_$$`
        fi

        #### peak position.
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
0.0 `echo "1.0/${AMP}" | bc -l`
EOF

        ### 4.6.2 plot Decon.
        awk -v T1=${PLOTTIMEMIN_D} -v T2=${PLOTTIMEMAX_D} -v A=${AMP} 'NR>1 { if (  $1>T1 && $1<T2 ) print $1,$2/A}' ${file} | psxy -J -R -W0.5p,purple -O -K >> ${OUTFILE}

        ### plot indicator of weight < 0.
        if [ `echo "${WeightN1N2}>0" |bc` -ne 1 ]
        then
            psxy -J -R -Sx0.2i -Wthick,red -N -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_D} 0
EOF
        fi

        ## station info.
        pstext -JX${TEXTWIDTH_D}i/${height}i -R/-1/1/-1/1 -X${PLOTWIDTH_D}i -N -O -K >> ${OUTFILE} << EOF
0 1 10 0 0 CB ${SNR_1}  ${SNR_2} ${SNR}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 0.5 10 0 0 CB ${CCC_St} ${Misfit_St} ${WeightN1N2}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${Gcarc} ${NETWK} ${STNM}
EOF
        # Plot a little map.
        pscoast -Jx${xscale}id/${yscale}id -R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX} -Dl -A40000 -W3,gray,faint -X${TEXTWIDTH_D}i -O -K >> ${OUTFILE}
        psxy -J -R -Sa0.05i -Gblue -O -K >> ${OUTFILE} << EOF
${HITLO} ${HITLA}
EOF
        psxy -J -R -X-${TEXTWIDTH_D}i -O -K >> ${OUTFILE} << EOF
EOF

        plot=$(($plot+1))

    done < sorted.lst

    ## Make PDF file
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF
    cat `ls *.ps | sort -n` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_DeconS.pdf

    rm ${WORKDIR_Plot}/tmpdir_$$/* 2>/dev/null

done # done EQ loop.

cd ${CODEDIR}

exit 0
