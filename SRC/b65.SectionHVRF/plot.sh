#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot structure histogram result.
#
# Shule Yu
# May 28 2015
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

        # Plot I/O's.
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "<STNM>" | awk '{print $1}' | sort -u > tmpfile1_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.SectionHVRF_S_1 "<STNM>" | awk '{print $1}' | sort -u > tmpfile2_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Category}/${EQ}/${EQ}.Category "<STNM>" | awk '{print $1}' | sort -u > tmpfile3_$$

        comm -1 -2 tmpfile1_$$ tmpfile2_$$ > tmpfile_$$
        comm -1 -2 tmpfile_$$ tmpfile3_$$  > tmpfile_stnm

        keys="<STNM> <Cate>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Category}/${EQ}/${EQ}.Category "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_cate

        keys="<STNM> <Misfit>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_s_misfit

        keys="<STNM> <Misfit>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_scs_misfit

        for count in `seq 1 $((2*SectionNum))`
        do
            keys="<STNM> <Fraction>"
            ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.SectionHVRF_S_${count} "${keys}" > tmpfile_$$
            ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{ print $2}' > tmpfile_extreme_s_${count}

            keys="<STNM> <Fraction>"
            ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Structure}/${TomoModel}/${EQ}.SectionHVRF_ScS_${count} "${keys}" > tmpfile_$$
            ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{ print $2}' > tmpfile_extreme_scs_${count}

            ${BASHCODEDIR}/Paste.sh tmpfile_cate tmpfile_s_misfit tmpfile_extreme_s_${count} > tmpfile_cate_${count}_s_misfit_extreme
            ${BASHCODEDIR}/Paste.sh tmpfile_cate tmpfile_scs_misfit tmpfile_extreme_scs_${count} > tmpfile_cate_${count}_scs_misfit_extreme
        done



        # Plot Begin.
        OUTFILE=${EQ}.ps
        rm ${OUTFILE} 2>/dev/null
        NR=`wc -l < tmpfile_stnm`

        # Title.
        title="${EQ}. ${MODELname}. ${EVLO}/${EVLA}/${EVDE}/${EVMA}. NRecord=${NR}"
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

        for count2 in `seq 1 $((VERTICNUM*HORIZNUM))`
        do
            if [ -e ${PLOTSRCDIR}/plot_${count2}.sh ]
            then
                ${PLOTSRCDIR}/plot_${count2}.sh
            fi

            if [ $((count2%HORIZNUM)) -eq 0 ]
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
    ps2pdf tmp.ps ${WORKDIR_Plot}/Structure_${MODELname}_SectionHVRF.pdf

done # Done TomoModel loop.

cd ${CODEDIR}

exit 0
