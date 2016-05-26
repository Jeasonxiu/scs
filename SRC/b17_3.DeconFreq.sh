#!/bin/bash

# ===========================================================
# Plot Decon results, with frequency domain changes.
#
# Shule Yu
# May 18 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
PLOTPERPAGE_F="5"
height=`echo ${PLOTHEIGHT_D}/${PLOTPERPAGE_F}/2 | bc -l`
doubleh=`echo ${height}*2 | bc -l`
halfh=`echo ${height}/2 | bc -l`
quarth=`echo ${height}/4 | bc -l`
PLOTWIDTH_F=8
width=`echo ${PLOTWIDTH_F}/4 | bc -l`
PLOTFREQMIN_D="0"
PLOTFREQMAX_D="0.5"
PLOTTIMEMIN_F="-25"
PLOTTIMEMAX_F="25"
Tick_F=0.1

xscale=`echo "${doubleh}/(${RLOMAX} - ${RLOMIN})" | bc -l`
yscale=`echo "${doubleh}/(${RLAMAX} - ${RLAMIN})" | bc -l`

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

    INFILE=${WORKDIR_Decon}/${EQ}/INFILE

    if ! [ -e ${INFILE} ]
    then
        echo "    !=> `basename $0`: Run a17.decon.sh first for ${EQ} ..."
        continue
    else
        echo "    ==> Plotting Deconvolution details for ${EQ}."

    fi

    MoreInfo=`grep "<MoreInfo>" ${INFILE} | awk '{print $2}'`

    if [ ${MoreInfo} -eq 0 ]
    then
        echo "    !=> `basename $0`: Run a17.decon.sh with MoreInfo=1 for ${EQ} ..."
		continue
	fi

    # Decon Parameters.
    F1=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`
    order=`grep "<order>" ${INFILE} | awk '{print $2}'`
    passes=`grep "<passes>" ${INFILE} | awk '{print $2}'`
    N1_D=`grep "<N1_D>" ${INFILE} | awk '{print $2}'`
    N2_D=`grep "<N2_D>" ${INFILE} | awk '{print $2}'`
    S1_D=`grep "<S1_D>" ${INFILE} | awk '{print $2}'`
    S2_D=`grep "<S2_D>" ${INFILE} | awk '{print $2}'`
    AN=`grep "<AN>"     ${INFILE} | awk '{print $2}'`
    Time=`grep "<Time>" ${INFILE} | awk '{print $2}'`

    # EQ info.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select evlo,evla,evde,mag from Master_a17 where eq=${EQ} limit 1;
EOF
	read EVLO EVLA EVDE EVMA < tmpfile_$$
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`

    # ================================================
    #         ! Make Plot Data !
    # ================================================

	mysql -N -u shule ${DB} > sorted.lst << EOF
select stnm,SNR_W1,SNR_W2,SNR_D,Shift_D,CCC_D,Misfit_D,category,N1_Time,S1_Time,N2_Time,N3_Time,round((SNR_W1*SNR_W2/(SNR_W1+SNR_W2)),3),gcarc,netwk,Weight_ScS,Peak_ScS,Polarity_ScS,hitlo,hitla from Master_a17 where eq=${EQ} and wantit=1 order by gcarc;
EOF

    # ===================================
    #        ! Plot !
    # ===================================

    page=0
    plot=$((PLOTPERPAGE_F+1))
    while read STNM SNR_1 SNR_2 SNR Shift_St CCC_St Misfit_St Cate N1Time S1Time N2Time N3Time WeightN1N2 Gcarc NETWK Weight_ScS peak_ScS Polarity HITLO HITLA
    do

        ScSTrace=${WORKDIR_ESF}/${EQ}_${MainPhase}/${Cate}/${STNM}.waveform
        Deconvolution=${WORKDIR_Decon}/${EQ}/${STNM}.trace
        ScSPhaseFile=${WORKDIR_Decon}/${EQ}/${STNM}.scs_fft_phase
        DeconPhaseFile=${WORKDIR_Decon}/${EQ}/${STNM}.scs_divide_phase

        ScSAmpFile=${WORKDIR_Decon}/${EQ}/${STNM}.scs_fft_amp
        awk '{print $1}' ${ScSAmpFile} > tmpfile1_$$
        awk '{print $2}' ${ScSAmpFile} > tmpfile2_$$
        ${BASHCODEDIR}/normalize.sh tmpfile2_$$ > tmpfile3_$$
        paste tmpfile1_$$ tmpfile3_$$ > tmpfile_ScSAmpFile

        DeconAmpFile=${WORKDIR_Decon}/${EQ}/${STNM}.scs_divide_amp
        awk '{print $1}' ${DeconAmpFile} > tmpfile1_$$
        awk '{print $2}' ${DeconAmpFile} > tmpfile2_$$
        ${BASHCODEDIR}/normalize.sh tmpfile2_$$ > tmpfile3_$$
        paste tmpfile1_$$ tmpfile3_$$ > tmpfile_DeconAmpFile


        if ! [ -e ${ScSTrace} ]
        then
            continue
        fi

        ## 4.2 check if need to plot on a new page.
        if [ ${plot} -eq $((PLOTPERPAGE_F+1)) ]
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
            title1="Decon plot ${MM}/${DD}/${YYYY}. PHASE: ScS COMP: T  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE}  Mag: ${EVMA}  NSTA: `wc -l < sorted.lst`"
            title3=""
            title4="SNR_1 SNR_2 SNR"
            title5="CCC_St Misfit_St WeightN1N2"
            title6="Gcarc NETWK STNM"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.5i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB $title1
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB $title2
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}. Time interval: ${Tick_D} sec. Freq interval: ${Tick_F} Hz.
EOF
            #### 4.2.3 add legends of station info.
            pstext -JX${TEXTWIDTH_D}i/${height}i -R-1/1/-1/1 -X`echo "3*${width}" | bc -l`i -Y-0.3i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB $title4
0 0 8 0 0 CB $title5
0 -0.5 8 0 0 CB $title6
EOF
        fi # end test if it's a new page.

        ## 4.3 go to the right position (preparing to plot seismograms)
        psxy -JX${width}i/${height}i -R${PLOTTIMEMIN_F}/${PLOTTIMEMAX_F}/-1/1 -X-`echo "3*${width}" | bc -l`i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        ### Figure 1,1. plot zero line
        psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_F} 0
${PLOTTIMEMAX_F} 0
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
        ### waveform (flipped).
        awk -v P=${peak_ScS} -v C=${Polarity} -v T1=${PLOTTIMEMIN_F} -v T2=${PLOTTIMEMAX_F} '{ if (  ($1-P)>T1 && ($1-P)<T2 ) print $1-P,$2*C}' ${ScSTrace} \
        | psxy -J -R -W0.5p -O -K >> ${OUTFILE}


        ### Figure 1,2. plot zero line
        psxy -J -R${PLOTFREQMIN_D}/${PLOTFREQMAX_D}/-0.1/1.05 -W0.3p,. -X${width}i -O -K >> ${OUTFILE} << EOF
${PLOTFREQMIN_D} 0
${PLOTFREQMAX_D} 0
EOF
        for  time in `seq 0 20`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_F} " | bc -l` 0
EOF
        done

        ### ScS freq amp.
        psxy tmpfile_ScSAmpFile -J -R -W0.5p -O -K >> ${OUTFILE}

        ### Figure 1,3. plot zero line
        psxy -J -R${PLOTFREQMIN_D}/${PLOTFREQMAX_D}/-3.1416/3.1416 -W0.3p,. -X${width}i -O -K >> ${OUTFILE} << EOF
${PLOTFREQMIN_D} 0
${PLOTFREQMAX_D} 0
EOF
        for  time in `seq 0 20`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * 1 " | bc -l` 0
EOF
        done

        ### ScS freq phase.
        psxy ${ScSPhaseFile} -J -R -W0.5p -O -K >> ${OUTFILE}



        ## Figure 1,4. station info.
        pstext -JX${TEXTWIDTH_D}i/${height}i -R/-1/1/-1/1 -X${width}i -N -O -K >> ${OUTFILE} << EOF
0 1 10 0 0 CB ${SNR_1}  ${SNR_2} ${SNR}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 0.5 10 0 0 CB ${CCC_St} ${Misfit_St} ${WeightN1N2}
EOF
        pstext -J -R/-1/1/-1/1 -N -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${Gcarc} ${NETWK} ${STNM}
EOF

        ### Figure 2,1. plot zero line with time marker.
        psxy -JX${width}i/${height}i -R${PLOTTIMEMIN_F}/${PLOTTIMEMAX_F}/-1/1 -W0.3p,. -X-`echo "3*${width}" | bc -l`i -Y-${height}i -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_F} 0
${PLOTTIMEMAX_F} 0
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
            awk -v T1=${PLOTTIMEMIN_F} -v T2=${PLOTTIMEMAX_F} 'NR>1 {if (  $1>T1 && $1<T2 ) print $2}' ${Deconvolution} > tmpfile_$$
            AMP=`${BASHCODEDIR}/amplitude.sh tmpfile_$$`
        fi

        ### 4.6.2 plot Decon.
        awk -v T1=${PLOTTIMEMIN_F} -v T2=${PLOTTIMEMAX_F} -v A=${AMP} 'NR>1 { if (  $1>T1 && $1<T2 ) print $1,$2/A}' ${Deconvolution} | psxy -J -R -W0.5p,purple -O -K >> ${OUTFILE}

        ### Figure 2,2. plot zero line
        psxy -J -R${PLOTFREQMIN_D}/${PLOTFREQMAX_D}/-0.1/1.05 -W0.3p,. -X${width}i -O -K >> ${OUTFILE} << EOF
${PLOTFREQMIN_D} 0
${PLOTFREQMAX_D} 0
EOF
        for  time in `seq 0 20`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * 1 " | bc -l` 0
EOF
        done

        ### Deconed freq amp.
        psxy tmpfile_DeconAmpFile -J -R -W0.5p -O -K >> ${OUTFILE}

        ### Figure 2,3. plot zero line
        psxy -J -R${PLOTFREQMIN_D}/${PLOTFREQMAX_D}/-3.1416/3.1416 -W0.3p,. -X${width}i -O -K >> ${OUTFILE} << EOF
${PLOTFREQMIN_D} 0
${PLOTFREQMAX_D} 0
EOF
        for  time in `seq 0 20`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * 1 " | bc -l` 0
EOF
        done

        ### Deconed freq phase.
        psxy ${DeconPhaseFile} -J -R -W0.5p -O -K >> ${OUTFILE}


        # 2,4 Plot a little map.
        pscoast -Jx${xscale}id/${yscale}id -R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX} -Dl -A40000 -W3,gray,faint -X${width}i -O -K >> ${OUTFILE}
        psxy -J -R -Sa0.05i -Gblue -O -K >> ${OUTFILE} << EOF
${HITLO} ${HITLA}
EOF

        plot=$((plot+1))

    done < sorted.lst

    ## Make PDF file
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

	Title=`basename $0`
    cat `ls -rt *.ps` > tmp.ps
	mkdir -p ${WORKDIR_Plot}/${Title%.sh}
    ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}/${EQ}.pdf
    rm -f ${WORKDIR_Plot}/tmpdir_$$/*

done # done EQ loop.

cd ${CODEDIR}

exit 0
