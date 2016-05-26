#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot ESF with STD / Histograms.
#
# Shule Yu
# Oct 20 2014
# ===========================================================

PLOTVERTIC="8"
PLOTHORIZ="10"
VERTICNUM=3
HORIZNUM=4
VERTICPER="0.8"
HORIZPER="0.8"
PLOTORIENT=""

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

hskip=`echo "${PLOTVERTIC}/${VERTICNUM}" | bc -l`
wskip=`echo "${PLOTHORIZ}/($((HORIZNUM-1))+${HORIZPER})" | bc -l`
height=`echo "${hskip}*${VERTICPER}" | bc -l`
width=`echo "${wskip}*${HORIZPER}" | bc -l`

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

for TomoModel in `cat ${WORKDIR}/tmpfile_TomoModels_${RunNumber}`
do
    MODELname=${TomoModel%_*}
    MODELcomp=${TomoModel#*_}
    echo "    ==> Tomography Model: ${MODELname}"
    echo "        Component       : ${MODELcomp}"

    # Check calculation (counting) result.
    if ! [ -e ${WORKDIR_Structure}/${TomoModel}/INFILE ]
    then
        echo "    !=> Run counting first on ${TomoModel}..."
        continue
    fi

    echo "    ==> Plot structure histogram on ${TomoModel}."

    for EQ in ${EQnames}
    do
        # EQ Info.
        keys="<EVLO> <EVLA> <EVDE> <MAG>"
        INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
        EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
        EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
        EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
        EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`

        # CMT info.
        CMT=`grep ${EQ} ${CMTINFO} | awk 'NR==1 {print $0}'`
        if ! [ -z "${CMT}" ]
        then
            STRIKE=`echo "${CMT}" | awk '{print $3}'`
            DIP=`echo "${CMT}" | awk '{print $4}'`
            RAKE=`echo "${CMT}" | awk '{print $5}'`
        fi

        # Plot I/O's.
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "<STNM>" | awk '{print $1}' | sort -u > tmpfile1_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Count "<STNM>" | awk '{print $1}' | sort -u > tmpfile2_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Category}/${EQ}/${EQ}.Category "<STNM>" | awk '{print $1}' | sort -u > tmpfile3_$$

        comm -1 -2 tmpfile1_$$ tmpfile2_$$ > tmpfile_$$
        comm -1 -2 tmpfile_$$ tmpfile3_$$  > tmpfile_stnm

        keys="<STNM> <Cate>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Category}/${EQ}/${EQ}.Category "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_category

        keys="<STNM> <Misfit>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${StructurePhase}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_misfit

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Count_Source "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentage_source

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Count_Receiver "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentage_receiver

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Count_Middle "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentage_middle

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Extreme_Source "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extreme_source

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Extreme_Receiver "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extreme_receiver

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.Extreme_Middle "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extreme_middle

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.CountL_Source "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentageL_source

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.CountL_Receiver "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentageL_receiver

        keys="<STNM> <Percentage>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.CountL_Middle "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_percentageL_middle

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.ExtremeL_Source "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extremeL_source

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.ExtremeL_Receiver "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extremeL_receiver

        keys="<STNM> <Vs>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.ExtremeL_Middle "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_extremeL_middle


        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentage_source tmpfile_misfit > tmpfile_cate_per_source_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentage_middle tmpfile_misfit > tmpfile_cate_per_middle_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentage_receiver tmpfile_misfit > tmpfile_cate_per_receiver_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extreme_source tmpfile_misfit > tmpfile_cate_ext_source_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extreme_middle tmpfile_misfit > tmpfile_cate_ext_middle_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extreme_receiver tmpfile_misfit > tmpfile_cate_ext_receiver_misfit

        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentageL_source tmpfile_misfit > tmpfile_cate_perl_source_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentageL_middle tmpfile_misfit > tmpfile_cate_perl_middle_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_percentageL_receiver tmpfile_misfit > tmpfile_cate_perl_receiver_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extremeL_source tmpfile_misfit > tmpfile_cate_extl_source_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extremeL_middle tmpfile_misfit > tmpfile_cate_extl_middle_misfit
        ${BASHCODEDIR}/Paste.sh tmpfile_category tmpfile_extremeL_receiver tmpfile_misfit > tmpfile_cate_extl_receiver_misfit

        # Plot Begin.
        OUTFILE=${EQ}.ps
        rm ${OUTFILE} 2>/dev/null
        NR=`wc -l < tmpfile_stnm`

        # Title.
        title="${EQ}. ${TomoModel}. ${EVLO}/${EVLA}/${EVDE}/${EVMA}. NRecord=${NR}"
        PROJ="-JX${PLOTHORIZ}i/0.3i"
        REG="-R-1/1/-1/1"
        pstext ${REG} ${PROJ} -X0.65i -Y8.1i ${PLOTORIENT} -N -K > ${OUTFILE} << EOF
0 0 10 0 0 CB ${title}
EOF
        psxy -J -R -Y-8.1i -O -K >> ${OUTFILE} << EOF
EOF

        # SubPlots.
        psxy -J -R -Y${PLOTVERTIC}i -O -K >> ${OUTFILE} << EOF
EOF

        psxy -J -R -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        for count in `seq 1 $((VERTICNUM*HORIZNUM))`
        do
            if [ -e ${PLOTSRCDIR}/plot_${count}.sh ]
            then
                ${PLOTSRCDIR}/plot_${count}.sh
            fi

            if [ $((count%HORIZNUM)) -eq 0 ]
            then
                psxy -J -R -X`echo "-$((HORIZNUM-1))*${wskip}" | bc -l`i -Y-${hskip}i -O -K >> ${OUTFILE} << EOF
EOF
            else
                psxy -J -R -X${wskip}i -O -K >> ${OUTFILE} << EOF
EOF
            fi

        done

        # Seal it.
        psxy -J -R -O >> ${OUTFILE} << EOF
EOF

    done # done EQ loop.

    # Make PDF.
    cat `ls -rt 20*.ps` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_Plot}/Structure_${MODELname}_${StructurePhase}_1.pdf

done # Done TomoModel loop.

cd ${CODEDIR}

exit 0
