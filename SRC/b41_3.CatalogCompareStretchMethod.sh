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
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onefourthwidth=`echo ${PLOTWIDTH_ALL} / 4 | bc -l`
onesixthwidth=`echo ${PLOTWIDTH_ALL} / 6 | bc -l`

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


	# Modified this three directories:
	WORKDIR_Method1=${WORKDIR}/Noise3Decon
	WORKDIR_FRSMethod1=${WORKDIR}/Noise3FRS

	WORKDIR_Method2=${WORKDIR}/Noise1Decon
	WORKDIR_FRSMethod2=${WORKDIR}/Noise1FRS

	WORKDIR_Method3=${WORKDIR}/Noise2Decon
	WORKDIR_FRSMethod3=${WORKDIR}/Noise2FRS

	if ! [ -d ${WORKDIR_Method1}/${EQ} ] || ! [ -d ${WORKDIR_Method2}/${EQ} ] || ! [ -d ${WORKDIR_Method3}/${EQ} ]
	then
		echo "    !=> Run all decon method on ${EQ} first !"
	fi


    # EQ info.
    keys="<EVLO> <EVLA> <EVDE> <MAG>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
    EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
    EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`

    # ================================================
    #         ! Make Plot Data !
    # ================================================

	mysql -N -u > tmpfile_info shule ${SYNDB} << EOF
select STNM,NETWK,Weight_Final,GCARC,Category,D_T_S,CCC_S,Polarity_S,D_T_ScS,CCC_ScS,CCC_D,Polarity_ScS,Peak_S,Peak_ScS,Shift_D from Master_a41 where eq=${EQ} and wantit=1;
EOF

    # sort.
    while read STNM NETNM Weight Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS Peak_S Peak_ScS Shift_St
    do
        echo ${STNM} ${NETNM} ${Weight} ${Gcarc} ${Cate} ${D_T_S} ${CCC_S} ${Polarity_S} ${D_T_ScS} ${CCC_ScS} ${CCC_St} ${Polarity_ScS} ${Peak_S} ${Peak_ScS} ${Shift_St} 1 >> tmpfile_$$

    done < tmpfile_info


    sort -g -r -k 4,4 tmpfile_$$ > sort.lst

    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sort.lst`

    PROJ="-JX`echo "${onefourthwidth}*0.95"| bc -l`i/${halfh}i"
#     REGESF="-R-50/50/-5/5"
    REGESF="-R-50/50/-1/1"
    PROJFRS="-JX${onesixthwidth}i/${halfh}i"
    REGFRS="-R0/${Time}/-1/1"

    page=0
    plot=$(($PLOTPERPAGE_ALL+1))
    while read STNM NETNM Weight Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS Peak_S Peak_ScS Shift_St Good
    do

        Gcarc=`printf "%.2lf" ${Gcarc}`
        Sfile=${WORKDIR_S}/${Cate}/${STNM}.waveform
        ScSfile=${WORKDIR_ScS}/${Cate}/${STNM}.waveform

        ScSfile1=/home/shule/PROJ/t041.Noisy3.ULVZ_Flat/ESF/${EQ}_${MainPhase}/${Cate}/${STNM}.waveform
        ScSfile2=/home/shule/PROJ/t041.Noisy1.ULVZ_Flat/ESF/${EQ}_${MainPhase}/${Cate}/${STNM}.waveform
        ScSfile3=/home/shule/PROJ/t041.Noisy2.ULVZ_Flat/ESF/${EQ}_${MainPhase}/${Cate}/${STNM}.waveform

        Sesf=${WORKDIR_S}/${Cate}/${EQ}.ESF_F
        ScSesf=${WORKDIR_ScS}/${Cate}/${EQ}.ESF_F
        Sesf_stretched_Water=${WORKDIR_Method1}/${EQ}/${Cate}.esf
        deconfile_Water=${WORKDIR_Method1}/${EQ}/${STNM}.trace
        Sesf_stretched_Subtract=${WORKDIR_Method2}/${EQ}/${Cate}.esf
        deconfile_Subtract=${WORKDIR_Method2}/${EQ}/${STNM}.trace
        Sesf_stretched_Raw=${WORKDIR_Method3}/${EQ}/${Cate}.esf
        deconfile_Raw=${WORKDIR_Method3}/${EQ}/${STNM}.trace

        frsfile_Water=${WORKDIR_FRSMethod1}/${EQ}_${STNM}.frs
        frsfile_Subtract=${WORKDIR_FRSMethod2}/${EQ}_${STNM}.frs
        frsfile_Raw=${WORKDIR_FRSMethod3}/${EQ}_${STNM}.frs

		${EXECDIR}/X_Diff.out 0 3 1 << EOF
${frsfile_Water}
${frsfile_Raw}
tmpfile_measurements1
${DELTA}
EOF

		${EXECDIR}/X_Diff.out 0 3 1 << EOF
${frsfile_Subtract}
${frsfile_Raw}
tmpfile_measurements2
${DELTA}
EOF

        awk '{if ($1 > -10 && $1 < 20) print $2}' ${Sfile} > tmp.xy
        AMP_S=`${BASHCODEDIR}/amplitude.sh tmp.xy`
        awk -v A=${AMP_S} '{print $1,$2/A}' ${Sfile} > S.xy

#         awk '{if ($1 > -10 && $1 < 20) print $2}' ${ScSfile} > tmp.xy
#         AMP_ScS=`${BASHCODEDIR}/amplitude.sh tmp.xy`
#         AMP_ScS=`awk -v P=${Peak_ScS} '{if ($1==P) printf "%.6lf",$2}' ${ScSfile}`
#         cp ${ScSfile} ScS.xy
#         awk -v A=${AMP_ScS} '{print $1,$2/A}' ${ScSfile} > ScS.xy

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
            title1="${EQ} All waveforms for ScS-Stripping Project.  Page: ${page}"
            title2="ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE} km. Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_A} sec."

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB $title1
EOF
            pstext -JX -R -Y-0.4i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB $title2
EOF

            pstext ${PROJ} -R-1/1/-1/1 -X`echo ${onefourthwidth}*3 | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 LB $title3
EOF

            psxy -J -R -X-`echo ${onefourthwidth}*3 | bc -l`i -Y-${quarth}i -O -K >> ${OUTFILE} << EOF
EOF

            pstext ${PROJ} -R-1/1/-1/1 -X${onefourthwidth}i -N -O -K >> ${OUTFILE} << EOF
-0.9 1 9 0 1 LT LowNoise
EOF
            pstext ${PROJ} -R-1/1/-1/1 -X${onefourthwidth}i -N -O -K >> ${OUTFILE} << EOF
-0.9 1 9 0 1 LT MedNoise
EOF
            pstext ${PROJ} -R-1/1/-1/1 -X${onefourthwidth}i -N -O -K >> ${OUTFILE} << EOF
-0.9 1 9 0 1 LT HighNoise
EOF


            psxy -J -R -X-`echo ${onefourthwidth}*3 | bc -l`i -Y-${quarth}i -O -K >> ${OUTFILE} << EOF
EOF


        fi # end the test whether it's a new page.

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

        if [ "${Good}" -eq 0 ]
        then
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
        else
            cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/V /${EQ}_${STNM}
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
        fi

        ### 6.6. plot S waveform with S esf.
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
-48 1 6 0 0 LT S (${STNM},${Gcarc})
-48 0.7 6 0 0 LT ESW
EOF
#         psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
# ${Peak_S} `echo "1.0/${AMP_S}" | bc -l`
# EOF
        awk -v C=${Polarity_S} '{print $1,$2*C}' S.xy | psxy ${PROJ} ${REGESF} -O -K >> ${OUTFILE}
        awk -v DT=${D_T_S} '{print $1+DT,$2}' ${Sesf} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]} -O -K >> ${OUTFILE}



		### 6.6. plot ScS waveform and Stretched Water S esf and Deconed ScS.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onefourthwidth}i -m -O -K >> ${OUTFILE} << EOF
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
-48 1 6 0 0 LT ScS
-48 0.7 6 0 0 LT ESW'
EOF
#         psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
# ${Peak_ScS} ${AMP_ScS}
# EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ${ScSfile1} | psxy ${PROJ} ${REGESF} -Wblack,- -O -K >> ${OUTFILE}
        awk -v DT1=${Shift_St} -v DT2=${Peak_ScS} '{print $1+DT1+DT2,$2}' ${Sesf_stretched_Water} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]},- -O -K >> ${OUTFILE}
        awk -v DT2=${Peak_ScS} '{print $1+DT2,$2}' ${deconfile_Water} | psxy ${PROJ} ${REGESF} -Wpurple -O -K >> ${OUTFILE}


		### 6.6. plot ScS waveform and Stretched Subtract S esf and Subtracted ScS.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onefourthwidth}i -m -O -K >> ${OUTFILE} << EOF
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
-48 1 6 0 0 LT ScS
-48 0.7 6 0 0 LT ESW'
EOF
#         psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
# ${Peak_ScS} ${AMP_ScS}
# EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ${ScSfile2} | psxy ${PROJ} ${REGESF} -Wblack,- -O -K >> ${OUTFILE}
        awk -v DT1=${Shift_St} -v DT2=${Peak_ScS} '{print $1+DT1+DT2,$2}' ${Sesf_stretched_Subtract} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]},- -O -K >> ${OUTFILE}
        awk -v DT2=${Peak_ScS} '{print $1+DT2,$2}' ${deconfile_Subtract} | psxy ${PROJ} ${REGESF} -Wpurple -O -K >> ${OUTFILE}


		### 6.6. plot ScS waveform and Stretched Raw S esf and Raw ScS.
        psxy ${PROJ} ${REGESF} -W0.3p,black,. -X${onefourthwidth}i -m -O -K >> ${OUTFILE} << EOF
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
-48 1 6 0 0 LT ScS
-48 0.7 6 0 0 LT ESW'
EOF
#         psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
# ${Peak_ScS} ${AMP_ScS}
# EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ${ScSfile3} | psxy ${PROJ} ${REGESF} -Wblack,- -O -K >> ${OUTFILE}
        awk -v DT1=${Shift_St} -v DT2=${Peak_ScS} '{print $1+DT1+DT2,$2}' ${Sesf_stretched_Raw} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]},- -O -K >> ${OUTFILE}
        awk -v DT2=${Peak_ScS} '{print $1+DT2,$2}' ${deconfile_Raw} | psxy ${PROJ} ${REGESF} -Wpurple -O -K >> ${OUTFILE}


		## Go back and shift down.
        psxy ${PROJ} ${REGESF} -X-`echo ${onefourthwidth}*3 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF

        ### 6.6. plot ScS waveform with ScS ESW.
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
-48 1 6 0 0 LT ScS
-48 0.7 6 0 0 LT ESW
EOF
#         psxy -J -R -Sa0.06i -Gblue -N -O -K >> ${OUTFILE} << EOF
# ${Peak_ScS} `echo "1.0/${AMP_ScS}" | bc -l`
# EOF
        awk -v C=${Polarity_ScS} '{print $1,$2*C}' ${ScSfile} | psxy ${PROJ} ${REGESF} -O -K >> ${OUTFILE}
        awk -v DT=${D_T_ScS} '{print $1+DT,$2}' ${ScSesf} | psxy ${PROJ} ${REGESF} -W${color[${Cate}]} -O -K >> ${OUTFILE}


		### 6.6. plot FRS waveform from WaterDecon.
        psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -X${onefourthwidth}i -O -K >> ${OUTFILE} << EOF
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
`echo "${Time} * 0.05" | bc -l` 1 6 0 0 LT FRS `cat tmpfile_measurements1 | awk '{printf "%.3f %.3f",$1,$2}'`
EOF
        psxy ${PROJFRS} ${REGFRS} ${frsfile_Water} -O -K >> ${OUTFILE}


		### 6.6. plot FRS waveform from Subtraction.
        psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -X${onefourthwidth}i -O -K >> ${OUTFILE} << EOF
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
`echo "${Time} * 0.05" | bc -l` 1 6 0 0 LT FRS `cat tmpfile_measurements2 | awk '{printf "%.3f %.3f",$1,$2}'`
EOF
        psxy ${PROJFRS} ${REGFRS} ${frsfile_Subtract} -O -K >> ${OUTFILE}


		### 6.6. plot FRS waveform from Raw.
        psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -X${onefourthwidth}i -O -K >> ${OUTFILE} << EOF
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
        psxy ${PROJFRS} ${REGFRS} ${frsfile_Raw} -O -K >> ${OUTFILE}


        psxy ${PROJ} ${REGESF} -X-`echo ${onefourthwidth}*3 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
        plot=$((plot+1))

    done < sort.lst # end of plot loop.

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF
    cat `ls *.ps | sort -n` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ}_StretchMethodCompare.pdf

    rm -f ${WORKDIR_Plot}/tmpdir_$$/*

done # done EQ loop.

exit 0
