#!/bin/bash

# ================================================================
# Compare Plot: source equalized ScS and its FRS from one selcted
# method for given 2 EQs. (from same Decon Dir, same syn data)
#
# This is only used for synthesis plot.
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

if ! [ -e ${WORKDIR_FRS}/INFO_All ]
then
    echo "    ==> `basename $0`: Run FRS first ..."
    exit 1
fi

echo "    ==> `basename $0`: Plotting ${EQ1} & ${EQ2} Decon, FRS result from method ${DeconMethod} ..."

# =========================================
#     ! Check the calculation result !
# =========================================
INFILE=${WORKDIR_FRS}/INFILE

# All Parameters.
order=`grep "<order>"                       ${INFILE} | awk '{print $2}'`
passes=`grep "<passes>"                     ${INFILE} | awk '{print $2}'`
Time=`grep "<Time>"                         ${INFILE} | awk '{print $2}'`

# EQ info.
keys="<EQ> <Vs_Bot> <Rho_Bot> <Thickness>"
${BASHCODEDIR}/Findfield.sh ${SYNDATADIR}/index "${keys}" > tmpfile_$$

INFO_1=`grep ${EQ1} tmpfile_$$ | awk '{print $0}'`
Vs_Change_1=`echo "${INFO_1}" | awk '{printf "%.2lf",$2}'`
Rho_Change_1=`echo "${INFO_1}" | awk '{printf "%.2lf",$3}'`
Thickness_1=`echo "${INFO_1}" | awk '{printf "%.2lf",$4}'`

# ================================================
#         ! Make Plot Data !
# ================================================

keys="<EQ> <STNM> <NETNM> <Weight> <GCARC> <Cate> <D_T_S> <CCC_S> <Polarity_S> <D_T_ScS> <CCC_ScS> <CCC_St> <Polarity_ScS> <Peak_S> <Peak_ScS> <Shift_St>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_FRS}/INFO_All "${keys}" | awk -v E=${EQ1} '{if ($1==E) {$1="";print $0}}' > tmpfile_info

# sort.
rm -f tmpfile_$$
while read STNM NETNM Weight Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS Peak_S Peak_ScS Shift_St
do
    Good=1
    echo ${STNM} ${NETNM} ${Weight} ${Gcarc} ${Cate} ${D_T_S} ${CCC_S} ${Polarity_S} ${D_T_ScS} ${CCC_ScS} ${CCC_St} ${Polarity_ScS} ${Peak_S} ${Peak_ScS} ${Shift_St} ${Good} >> tmpfile_$$

done < tmpfile_info

sort -g -r -k 3,3 tmpfile_$$ > sort.lst

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
while read STNM NETNM Weight Gcarc Cate D_T_S CCC_S Polarity_S D_T_ScS CCC_ScS CCC_St Polarity_ScS Peak_S Peak_ScS Shift_St Good
do

    Gcarc=`printf "%.2lf" ${Gcarc}`
    Decon1file=${WORKDIR_Decon}/${EQ1}/${STNM}.trace
    Decon2file=${WORKDIR_Decon}/${EQ2}/${STNM}.trace
    frs1file=${WORKDIR_FRS}/${EQ1}_${STNM}.frs
    frs2file=${WORKDIR_FRS}/${EQ2}_${STNM}.frs

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
        title1="ScS Deconvolution / FRS Comparison. @;${color[1]};${Marker1}@;;, @;${color[2]};${Marker2}@;;  Page: ${page}"
		title2="Vs: ${Vs_Change_1}  H: ${Thickness_1} km.  Rho: ${Rho_Change_1}  NSTA: ${NSTA}"
        title3="Time tick interval: ${Tick_A} sec."
        title4="Weight  STNM  Gcarc"

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
/T (${EQ1}_${STNM})
/FT /Btn
/Rect [-180 -65 -50 65]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (4) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 0.196 0.80 0.196 rg)
/AP << /N << /${EQ1}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF
    else
        cat >> ${OUTFILE} << EOF
[
/T (${EQ1}_${STNM})
/V /${EQ1}_${STNM}
/FT /Btn
/Rect [-180 -65 -50 65]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (4) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 0.196 0.80 0.196 rg)
/AP << /N << /${EQ1}_${STNM} /null >> >>
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
0 0.9 9 0 0 LT ${Weight}  ${STNM}  ${Gcarc}
EOF

    psxy ${PROJ} ${REGESF} -X-`echo ${onethirdwidth}*2 | bc -l`i -Y-${halfh}i -O -K >> ${OUTFILE} << EOF
EOF
    plot=$((plot+1))

done < sort.lst # end of plot loop.

# Make PDF.
psxy -J -R -O >> ${OUTFILE} << EOF
EOF
cat `ls *.ps | sort -n` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${EQ1}_${EQ2}_Decon_FRS.pdf

exit 0
