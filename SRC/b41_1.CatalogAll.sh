#!/bin/bash

# ================================================================
# SYNTHESIS
# Plot All waveforms. ScS + Stretched S; S + S esf; ScS + ScS esf;
# deconed ScS; FRS; map.
#
# Shule Yu
# Oct 27 2014
# ================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onethirdwidth=`echo ${PLOTWIDTH_ALL} / 3 | bc -l`
onesixthwidth=`echo ${onethirdwidth} / 2 | bc -l`

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

# ================================================
#         ! Check calculation result !
# ================================================

for EQ in ${EQnames}
do
    echo "    ==> Plotting All waveforms of ${EQ}."

    # =========================================
    #     ! Check the calculation result !
    # =========================================
    WORKDIR_S=${WORKDIR_ESF}/${EQ}_${ReferencePhase}
    WORKDIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}

    # EQ info.
	mysql -N -u shule ${SYNDB} > tmpfile_$$ << EOF
select evlo,evla,evde,mag from Master_a41 where eq=${EQ} limit 1;
EOF
	read EVLO EVLA EVDE EVMA < tmpfile_$$
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`


    # ================================================
    #         ! Make Plot Data !
    # ================================================

	mysql -N -u shule ${SYNDB} > sort.lst << EOF
select STNM,NETWK,round(Weight_Final,2),GCARC,Category,D_T_S,CCC_S,Polarity_S,D_T_ScS,CCC_ScS,CCC_D,Polarity_ScS,Peak_S,Peak_ScS,Shift_D from Master_a41 where eq=${EQ} and wantit=1 order by Misfit_ScS;
EOF


    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sort.lst`

    PROJ="-JX`echo "${onethirdwidth}*0.95"| bc -l`i/${halfh}i"
    REGESF="-R-50/50/-1/1"
    PROJFRS="-JX${onesixthwidth}i/${halfh}i"
    REGFRS="-R0/${Time}/-1/1"

    page=0
    plot=$(($PLOTPERPAGE_ALL+1))
    while read STNM NETNM Weight Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS Peak_S Peak_ScS Shift_St
    do
		Good=1
        Gcarc=`printf "%.2lf" ${Gcarc}`
        Sfile=${WORKDIR_S}/${Cate}/${STNM}.waveform
        ScSfile=${WORKDIR_ScS}/${Cate}/${STNM}.waveform
        Sesf=${WORKDIR_S}/${Cate}/${EQ}.ESF_F
        ScSesf=${WORKDIR_ScS}/${Cate}/${EQ}.ESF_F
        Sesf_stretched=${WORKDIR_Decon}/${EQ}/${Cate}.esf
        deconfile=${WORKDIR_Decon}/${EQ}/${STNM}.trace
        frsfile=${WORKDIR_FRS}/${EQ}_${STNM}.frs

        awk '{if ($1 > -10 && $1 < 20) print $2}' ${Sfile} > tmp.xy
        AMP_S=`${BASHCODEDIR}/amplitude.sh tmp.xy`
        awk -v A=${AMP_S} '{print $1,$2/A}' ${Sfile} > S.xy

        awk '{if ($1 > -10 && $1 < 20) print $2}' ${ScSfile} > tmp.xy
        AMP_ScS=`${BASHCODEDIR}/amplitude.sh tmp.xy`
        awk -v A=${AMP_ScS} '{print $1,$2/A}' ${ScSfile} > ScS.xy

        ## 6.1 check if need to plot on a new page.
        if [ $plot -eq $(($PLOTPERPAGE_ALL+1)) ]
        then

            ### 6.2.1 if this isn't first page, seal it (without -K option).
            if [ ${page} -gt 0 ]
            then
                psxy -J -R -O >> ${OUTFILE} << EOF
EOF
            fi

            ### 6.2.2. plot titles and legends
            plot=1
            page=$(($page+1))
            OUTFILE="${page}.ps"
            title1="${MM}/${DD}/${YYYY} All waveforms for ScS-Stripping Project.  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE} km. Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_A} sec."
            title4="Weight  STNM  Gcarc"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB $title1
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB $title2
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF

            pstext ${PROJ} -R-1/1/-1/1 -X`echo ${onethirdwidth}*2 | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB $title3
0 0 8 0 0 CB $title4
EOF

            psxy -J -R -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
        fi # end the test whether it's a new page.

    	### 6.6. plot ScS waveform and Stretched S esf.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
        done

        pstext ${PROJ} ${REGESF} -O -K >> ${OUTFILE} << EOF
-50 1 6 0 0 LT ScS
-50 0.7 6 0 0 LT stretched S (${CCC_St})
EOF
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
${Peak_ScS} 1.0
EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ScS.xy | psxy ${PROJ} ${REGESF} -O -K >> ${OUTFILE}
        awk -v DT1=${Shift_St} -v DT2=${Peak_ScS} '{print $1+DT1+DT2,$2}' ${Sesf_stretched} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]} -O -K >> ${OUTFILE}

        ### 6.6. plot S waveform with S esf.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onethirdwidth}i -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
        done

        pstext ${PROJ} ${REGESF} -O -K >> ${OUTFILE} << EOF
-50 1 6 0 0 LT S(${CCC_S})
EOF
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
${Peak_S} 1.0
EOF
        awk -v C=${Polarity_S} '{print $1,$2*C}' S.xy | psxy ${PROJ} ${REGESF} -O -K >> ${OUTFILE}
        awk -v DT=${D_T_S} '{print $1+DT,$2}' ${Sesf} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]} -O -K >> ${OUTFILE}

    ### 6.6. plot FRS waveform.
        psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -X${onethirdwidth}i -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
>
0 -1
0 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
0 `echo "${time} * 0.25" | bc -l`
EOF
        done

        pstext ${PROJFRS} ${REGFRS} -O -K >> ${OUTFILE} << EOF
`echo "${Time} * 0.05" | bc -l` 1 6 0 0 LT FRS
EOF
        psxy ${PROJFRS} ${REGFRS} ${frsfile} -O -K >> ${OUTFILE}

        ## 6.4 go to the right position prepare to plot seismograms.
        psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF

        ### 6.6. plot Decon waveform.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
        done

        psvelo -J -R -Wblack -Ggreen -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
0 -0.5 0 0.5
EOF
        psvelo -J -R -Wblack -Gred -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
${Time} 0.5 0 -0.5
-${Time} 0.5 0 -0.5
EOF
        pstext ${PROJ} ${REGESF} -O -K >> ${OUTFILE} << EOF
-50 1 6 0 0 LT Decon (${Gcarc})
EOF
        awk 'NR>1 {print $0}' ${deconfile} | psxy ${PROJ} ${REGESF} -Wpurple -O -K >> ${OUTFILE}

        ### 6.6. plot ScS with ScS esf.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onethirdwidth}i -m -O -K >> ${OUTFILE} << EOF
-50 0
50 0
>
-50 -1
-50 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-50 `echo "${time} * 0.5" | bc -l`
EOF
        done

        pstext ${PROJ} ${REGESF} -O -K >> ${OUTFILE} << EOF
-50 1 6 0 0 LT ScS(${CCC_ScS})
EOF
        psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
${Peak_ScS} 1.0
EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ScS.xy | psxy ${PROJ} ${REGESF} -O -K >> ${OUTFILE}
        awk -v DT=${D_T_ScS}  '{print $1+DT,$2}' ${ScSesf} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]} -O -K >> ${OUTFILE}

        ### 6.6. Info.
        pstext ${PROJFRS} ${REGFRS} -X${onethirdwidth}i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT ${Weight}  ${STNM}  ${Gcarc}
EOF

        psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
        plot=$((plot+1))

    done < sort.lst # end of plot loop.

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

	Title=`basename $0`
    cat `ls -rt *.ps` > tmp.ps
	mkdir -p ${WORKDIR_Plot}/${Title%.sh}
    ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}/${EQ}.pdf
    rm -f ${WORKDIR_Plot}/tmpdir_$$/*

done # done EQ loop.

exit 0
