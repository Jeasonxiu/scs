#!/bin/bash

# ================================================================
# Compare Plot: source equalized ScS and its FRS from two selcted
# methods, for same EQ. Loop through given EQs.
#
# Shule Yu
# Oct 27 2014
# ================================================================

if [ "${Method1}" = "Waterlevel" ]
then
    DeconDIR1=${WORKDIR_WaterDecon}
    FRSDIR1=${WORKDIR_WaterFRS}
elif [ "${Method1}" = "Ammon" ]
then
    DeconDIR1=${WORKDIR_AmmonDecon}
    FRSDIR1=${WORKDIR_AmmonFRS}
elif [ "${Method1}" = "Subtract" ]
then
    DeconDIR1=${WORKDIR_SubtractDecon}
    FRSDIR1=${WORKDIR_SubtractFRS}
else
    DeconDIR1=${WORKDIR}/CompareDecon
    FRSDIR1=${WORKDIR}/CompareFRS
fi

if [ "${Method2}" = "Waterlevel" ]
then
    DeconDIR2=${WORKDIR_WaterDecon}
    FRSDIR2=${WORKDIR_WaterFRS}
elif [ "${Method2}" = "Ammon" ]
then
    DeconDIR2=${WORKDIR_AmmonDecon}
    FRSDIR2=${WORKDIR_AmmonFRS}
elif [ "${Method2}" = "Subtract" ]
then
    DeconDIR2=${WORKDIR_SubtractDecon}
    FRSDIR2=${WORKDIR_SubtractFRS}
else
    DeconDIR2=${WORKDIR}/CompareDecon
    FRSDIR2=${WORKDIR}/CompareFRS
fi

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onethirdwidth=`echo ${PLOTWIDTH_ALL} / 2.5 | bc -l`
onesixthwidth=`echo ${PLOTWIDTH_ALL} / 6 | bc -l`

color[1]=red
color[2]=blue

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

# ================================================
#         ! Check calculation result !
# ================================================

if ! [ -e ${FRSDIR1}/INFILE ] || ! [ -e ${FRSDIR2}/INFILE ]
then
    echo "    ==> `basename $0`: Run FRS first ..."
    exit 1
fi

for EQ in ${EQnames}
do
    echo "    ==> Plotting All waveforms of ${EQ}."

    # =========================================
    #     ! Check the calculation result !
    # =========================================
    INFILE=${FRSDIR1}/INFILE

    # All Parameters.
    F1=`grep ${EQ}                              ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ}                              ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`
    order=`grep "<order>"                       ${INFILE} | awk '{print $2}'`
    passes=`grep "<passes>"                     ${INFILE} | awk '{print $2}'`
    Time=`grep "<Time>"                         ${INFILE} | awk '{print $2}'`

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

	mysql -N -u shule ${DB} > tmpfile_info << EOF
select stnm,netwk,gcarc,category,D_T_S,CCC_S,Polarity_S,D_T_ScS,CCC_ScS,CCC_D,Polarity_ScS,hitlo,hitla,Peak_S,Peak_ScS,Shift_D from Master_a17 where eq=${EQ} and wantit=1 order by gcarc;
EOF

    # Hand Select result.
	rm -f sort.lst
    while read STNM NETNM Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS HITLO HITLA Peak_S Peak_ScS Shift_St
    do

		if [ ${flag_goodfile} -eq 1 ]
		then
			grep "${EQ}_${STNM}$" ${GoodDecon} >/dev/null 2>&1

			if [ $? -ne 0 ]
			then
				Good=0
			else
				Good=1
			fi
		else
			Good=1
		fi

        echo ${STNM} ${NETNM} ${Gcarc} ${Cate} ${D_T_S} ${CCC_S} ${Polarity_S} ${D_T_ScS} ${CCC_ScS} ${CCC_St} ${Polarity_ScS} ${HITLO} ${HITLA} ${Peak_S} ${Peak_ScS} ${Shift_St} ${Good} >> sort.lst

    done < tmpfile_info

    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sort.lst`

    PROJ="-JX`echo "${onethirdwidth}*0.95"| bc -l`i/${halfh}i"
    REGESF="-R-50/50/-1/1"
    PROJ2="-JX`echo "${onethirdwidth}*2*0.95"| bc -l`i/${halfh}i"
    REGESF2="-R-100/100/-1/1"
    PROJFRS="-JX${onesixthwidth}i/${halfh}i"
    REGFRS="-R0/${Time}/-1/1"

    page=0
    plot=$(($PLOTPERPAGE_ALL+1))
    while read STNM NETNM Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS HITLO HITLA Peak_S Peak_ScS Shift_St Good
    do

        Gcarc=`printf "%.2lf" ${Gcarc}`
        Decon1file=${DeconDIR1}/${EQ}/${STNM}.trace
        Decon2file=${DeconDIR2}/${EQ}/${STNM}.trace
        frs1file=${FRSDIR1}/${EQ}_${STNM}.frs
        frs2file=${FRSDIR2}/${EQ}_${STNM}.frs

		if ! [ -s ${Decon2file} ] || ! [ -s ${frs2file} ]
		then
			continue
		fi

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
            title1="ScS Deconvolution / FRS Comparison. @;${color[1]};${Marker1}@;; @;${color[2]};${Marker2}@;;  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE} km. Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_A} sec."
            title4="STNM  Gcarc"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${title2}
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF

            pstext ${PROJ} -R-1/1/-1/1 -X`echo ${onethirdwidth}*2 | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB ${title3}
0 0 8 0 0 CB ${title4}
EOF

            psxy -J -R -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
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

    ### 6.6. plot Decon1file waveform and Stretched S esf.
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

        psxy ${Decon1file} ${PROJ} ${REGESF} -W${color[1]} -O -K >> ${OUTFILE}

        ### 6.6. plot Decon2file waveform with S esf.
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

        psxy ${Decon2file} ${PROJ} ${REGESF} -W${color[2]} -O -K >> ${OUTFILE}

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
        psxy ${PROJFRS} ${REGFRS} ${frs1file} -W${color[1]} -O -K >> ${OUTFILE}
        psxy ${PROJFRS} ${REGFRS} ${frs2file} -W${color[2]} -O -K >> ${OUTFILE}

        ## 6.4 go to the right position prepare to plot seismograms.
        psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF

        ### 6.6. plot Decon waveform.
        psxy ${PROJ2} ${REGESF2} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
-100 0
100 0
>
-100 -1
-100 1
EOF
        for time in `seq -10 10`
        do
            psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
            psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
-100 `echo "${time} * 0.5" | bc -l`
EOF
        done

        psvelo -J -R -Wblack -Ggreen -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
0 -0.5 0 0.5
EOF
        psvelo -J -R -Wblack -Gred -Se${quarth}i/0.2/18 -N -O -K >> ${OUTFILE} << EOF
${Time} 0.5 0 -0.5
-${Time} 0.5 0 -0.5
EOF
        pstext ${PROJ2} ${REGESF2} -O -K >> ${OUTFILE} << EOF
-100 1 6 0 0 LT Overlap (${Gcarc})
EOF
        psxy ${Decon1file} ${PROJ2} ${REGESF2} -W${color[1]} -O -K >> ${OUTFILE}
        psxy ${Decon2file} ${PROJ2} ${REGESF2} -W${color[2]} -O -K >> ${OUTFILE}

        ### 6.6. Info.
        pstext ${PROJFRS} ${REGFRS} -X`echo "2*${onethirdwidth}" | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT ${STNM}  ${Gcarc}
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
