#!/bin/bash

# ================================================================
# Plot FRS stacks from each bins. Add their info.
#
# Shule Yu
# Jul 03 2015
# ================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
PLOTPERPAGE_ALL=20
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onethirdwidth=`echo ${PLOTWIDTH_ALL} / 3 | bc -l`
onesixthwidth=`echo ${onethirdwidth} / 2 | bc -l`

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

# ================================================
#         ! Check calculation result !
# ================================================

if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> `basename $0`: Run GeoBin first ..."
    exit 1
fi

# Parameters.
Time=`grep "<Time>" ${WORKDIR_FRS}/INFILE | awk '{print $2}'`


# ================================================
#         ! Make Plot Data !
# ================================================


for binN in `seq ${StartBin} ${FinalBin}`
do
	file=${WORKDIR_Geo}/${binN}.grid
	if ! [ -s ${file} ]
	then
		continue
	fi

    frsstackfile=${WORKDIR_Geo}/${binN}.frstack

    echo "    ==> Ploting FRS stacks from Bin ${binN}..."

    # Get stations in this bin.
    keys="<binLon> <binLat> <binR>"
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    binLon=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    binLat=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    binR=`echo "${INFO}" | awk '{printf "%.1lf",$3}'`

	# Information Gathering.
	mysql -N -u shule ${DB} > tmpfile_info << EOF
select eq,stnm,netwk,round(weight_final,3),shift_gcarc,category,CCC_S,SNR_S,Weight_S,CCC_ScS,SNR_ScS,Weight_ScS,CCC_D from Master_a21 where wantit=1 order by weight_final;
EOF

    # Get stations in this bin.
    keys="<EQ> <STNM> <Weight_Smooth>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_eq_stnm_weight

    # Generate the info  for this bin.

    while read eq stnm weight_smooth
    do
        INFO=`grep ${eq} tmpfile_info | grep -w ${stnm}`

        if [ "${flag_goodfile}" -eq 1 ]
        then
            grep "${eq}_${stnm}$" ${GoodDecon} >/dev/null 2>&1
            if [ $? -ne 0 ]
            then
                Good=0
            else
                Good=1
            fi
        else
            Good=1
        fi

        echo ${INFO} ${weight_smooth} ${Good} >> tmpfile_binInfo
    done < tmpfile_eq_stnm_weight

    # sort.
    sort -g -r -k 4,4 tmpfile_binInfo > sort.lst

    # ===================================
    #        ! Plot !
    # ===================================

    NSTA=`wc -l < sort.lst`

    PROJ="-JX`echo "${onethirdwidth}*0.95"| bc -l`i/${halfh}i"
    REGESF="-R-50/50/-1/1"
    PROJFRS="-JX${onesixthwidth}i/${halfh}i"
    REGFRS="-R0/${Time}/-0.5/0.5"
    REG="-R0/${Time}/-1/1"

    page=0
    plot=$(($PLOTPERPAGE_ALL+1))
    while read EQ STNM NETNM Weight GCARC Cate CCC_S SNR_S Weight_S CCC_ScS SNR_ScS Weight_ScS CCC_St Weight_Smooth Good
    do

        frsfile=${WORKDIR_FRS}/${EQ}_${STNM}.frs

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
            title1="FRS waveforms for ScS-Stripping Project.  Page: ${page}"
            title2="Bin ${binN}.  Center LAT/LON: ${binLat} ${binLon}  Radius: ${binR}  NSTA: ${NSTA}."
            title3="Time tick interval: ${Tick_A} sec."

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${title2}
EOF

            pstext ${PROJFRS} -R-1/1/-1/1 -X`echo ${onethirdwidth}*2 | bc -l`i -N -O -K >> ${OUTFILE} << EOF
0 0.5 8 0 0 CB ${title3}
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

        # plot FRS stack.
        if [ ${page} -eq 1 ] && [ ${plot} -eq 1 ]
        then
            psxy ${PROJFRS} ${REGFRS} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
>
0 -1
0 1
EOF
            for time in `seq -5 5`
            do
                psxy -J -R -Sy0.02i -Wred -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_A}" | bc -l` 0
EOF
                psxy -J -R -S-0.02i -Wred -O -K >> ${OUTFILE} << EOF
0 `echo "${time} * 0.25" | bc -l`
EOF
            done

            pstext ${PROJFRS} ${REGFRS} -O -K >> ${OUTFILE} << EOF
0 0.5 6 0 0 LT FRS stack
EOF
            awk '{print $1,$2}' ${frsstackfile} | psxy ${PROJFRS} ${REGFRS} -Wthick,black -O -K >> ${OUTFILE}
            awk '{print $1,$2+$3}' ${frsstackfile} | psxy ${PROJFRS} ${REGFRS} -Wfaint,red -O -K >> ${OUTFILE}
            awk '{print $1,$2-$3}' ${frsstackfile} | psxy ${PROJFRS} ${REGFRS} -Wfaint,red -O -K >> ${OUTFILE}

            pstext ${PROJ} ${REG} -X${onethirdwidth}i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT EQ  STNM  Gcarc
0 0.0 9 0 0 LT Weight_Final  Weight_Smooth
EOF

            pstext ${PROJ} ${REG} -X${onethirdwidth}i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT S:   CCC  SNR  Weight
0 0.0 9 0 0 LT ScS: CCC  SNR  Weight
EOF
            psxy ${PROJFRS} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF
            plot=$((plot+1))

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

    ### 6.6. plot FRS.
        psxy ${PROJFRS} ${REG} -W0.3p,black,. -m -O -K >> ${OUTFILE} << EOF
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

        pstext ${PROJFRS} ${REG} -O -K >> ${OUTFILE} << EOF
`echo "${Time} * 0.05" | bc -l` 1 6 0 0 LT FRS
EOF

        psxy ${PROJFRS} ${REG} ${frsfile} -O -K >> ${OUTFILE}
        psxy ${PROJFRS} ${REG} ${frsstackfile} -Wred -O -K >> ${OUTFILE}

        ### 6.6. Info.
        pstext ${PROJ} ${REG} -X${onethirdwidth}i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT ${EQ}  ${STNM}  ${GCARC}
0 0.0 9 0 0 LT ${Weight}  ${Weight_Smooth}
EOF

        pstext ${PROJ} ${REG} -X${onethirdwidth}i -N -O -K >> ${OUTFILE} << EOF
0 0.9 9 0 0 LT ${CCC_S}  ${SNR_S}  ${Weight_S}
0 0.0 9 0 0 LT ${CCC_ScS}  ${SNR_ScS}  ${Weight_ScS}
EOF

        psxy ${PROJFRS} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF
        plot=$((plot+1))

    done < sort.lst # end of plot loop.

    # Make PDF.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

	Title=`basename $0`
    cat `ls -rt *.ps` > tmp.ps
	mkdir -p ${WORKDIR_Plot}/${Title%.sh}
    ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}/Bin${binN}.pdf
    rm -f ${WORKDIR_Plot}/tmpdir_$$/*

done # done bin loop.

exit 0
