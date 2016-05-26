#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot ESF Measurements.
#
# Shule Yu
# Oct 20 2014
# ===========================================================

PLOTVERTIC="8"
PLOTHORIZ="10"
VERTICNUM=3
HORIZNUM=1
VERTICPER="0.8"
HORIZPER="0.8"
PLOTORIENT=""

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

hskip=`echo "${PLOTVERTIC}/${VERTICNUM}" | bc -l`
wskip=`echo "${PLOTHORIZ}/($((HORIZNUM-1))+${HORIZPER})" | bc -l`
height=`echo "${hskip}*${VERTICPER}" | bc -l`
width=`echo "${wskip}*${HORIZPER}" | bc -l`

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

CertainNT="TA"

for EQ in ${EQnames}
do
	# EQ Info.
	keys="<EVLO> <EVLA> <EVDE> <MAG>"
	INFO=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | head -n 1`
	EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
	EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
	EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3/1000}'`
	EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`

	for cate in `seq 1 ${CateN}`
	do

        # S amplitude I/O's.
		keys="<STNM>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys} <NETWK>" | awk -v T=${CertainNT} '{if ($2==T) print $1}' | sort -u > tmpfile1_$$
#         ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | awk '{print $1}' | sort -u > tmpfile1_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}*DT "${keys}" | awk '{print $1}' | sort -u > tmpfile2_$$
        comm -1 -2 tmpfile1_$$ tmpfile2_$$ > tmpfile_stnm
	
        keys="<STNM> <Amplitude>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}*DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_amplitude

        keys="<STNM> <SHIFT_GCARC> <Rad_${ReferencePhase}>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{{if ($3<0) $3=-$3} print $2,$3}' > tmpfile_gcarc_radpat

		paste tmpfile_amplitude tmpfile_gcarc_radpat | awk '{print $2,$1/$3}' > tmpfile${cate}_gcarc_${ReferencePhase}amp

		# Get maxAmp.
		# Normalize them to EQ max.
		MaxAmp=`minmax -C tmpfile${cate}_gcarc_${ReferencePhase}amp | awk '{print $4}'`
		awk -v A=${MaxAmp} '{print $1,$2/A}' tmpfile${cate}_gcarc_${ReferencePhase}amp > tmpfile_$$
		mv tmpfile_$$ tmpfile${cate}_gcarc_${ReferencePhase}amp


        # ScS amplitude I/O's.
		keys="<STNM>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys} <NETWK>" | awk -v T=${CertainNT} '{if ($2==T) print $1}' | sort -u > tmpfile1_$$
#         ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" | awk '{print $1}' | sort -u > tmpfile1_$$
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}*DT "${keys}" | awk '{print $1}' | sort -u > tmpfile2_$$
        comm -1 -2 tmpfile1_$$ tmpfile2_$$ > tmpfile_stnm

        keys="<STNM> <Amplitude>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}*DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{print $2}' > tmpfile_amplitude

        keys="<STNM> <SHIFT_GCARC> <Rad_${MainPhase}>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{{if ($3<0) $3=-$3} print $2,$3}' > tmpfile_gcarc_radpat

		paste tmpfile_amplitude tmpfile_gcarc_radpat | awk '{print $2,$1/$3}' > tmpfile${cate}_gcarc_${MainPhase}amp

		# Get maxAmp.
		# Normalize them to EQ max.
		MaxAmp=`minmax -C tmpfile${cate}_gcarc_${MainPhase}amp | awk '{print $4}'`
		awk -v A=${MaxAmp} '{print $1,$2/A}' tmpfile${cate}_gcarc_${MainPhase}amp > tmpfile_$$
		mv tmpfile_$$ tmpfile${cate}_gcarc_${MainPhase}amp


        # ratio I/O's.
		paste tmpfile${cate}_gcarc_${MainPhase}amp tmpfile${cate}_gcarc_${ReferencePhase}amp | awk '{print $1,$2/$4}' > tmpfile${cate}_gcarc_ratio
		# Get maxAmp.
		# Normalize them to EQ max.
		MaxAmp=`minmax -C tmpfile${cate}_gcarc_ratio | awk '{print $4}'`
		awk -v A=${MaxAmp} '{print $1,$2/A}' tmpfile${cate}_gcarc_ratio > tmpfile_$$
		mv tmpfile_$$ tmpfile${cate}_gcarc_ratio


        # Plot Begin.
        OUTFILE=${EQ}.ps
        rm -f ${OUTFILE}
        NR=`wc -l < tmpfile_stnm`

        # Title.
        title="${EQ} radiation pattern-corrected amplitude. NRecord=${NR}. ${CertainNT}"
        PROJ="-JX${PLOTHORIZ}i/0.3i"
        REG="-R-1/1/-1/1"
        pstext ${REG} ${PROJ} -X0.65i -Y8.1i ${PLOTORIENT} -N -K > ${OUTFILE} << EOF
0 0 20 0 1 CB ${title}
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
    ps2pdf tmp.ps ${WORKDIR_Plot}/DataAmplitude.pdf

done # Done EQ loop.

cd ${CODEDIR}

exit 0
