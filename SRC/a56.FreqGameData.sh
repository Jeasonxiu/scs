#!/bin/bash

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Game}
rm -rf ${WORKDIR_Game}/*
cd ${WORKDIR_Game}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Game}/INFILE
trap "rm -rf ${WORKDIR_Game}/*; exit 1" SIGINT

# ==================================================
#              ! Work Begin !
# ==================================================

# Game parameters.
cut=35
taperwidth=0.1

# I/O.
count=0

while read EQ gwidth cutoff_left cutoff_right waterlevel sigma_smooth secondarrival secondamp ulvzarrival ulvzamp noiselevel method
do

    count=$((count+1))
    echo "Running on Case ${count} .."

    if [ ${EQ%??????} = "201400" ]
    then
        file=${SYNWORKDIR_ESF}/${EQ}_${dataGamePhase}/${dataGameCate}/fullstack
    else
        file=${WORKDIR_ESF}/${EQ}_${dataGamePhase}/${dataGameCate}/fullstack
    fi

    # Run C code.
    ${EXECDIR}/FreqGameData.out 1 22 13 << EOF
${method}
${file}
waterlevel_decon_out_structure_${count}
waterlevel_decon_out_source_${count}
waterlevel_decon_out_signal_${count}
waterlevel_decon_out_decon_${count}
waterlevel_decon_out_frs_nodecon_${count}
waterlevel_decon_out_frs_${count}
structure_fft_amp_${count}
structure_fft_phase_${count}
source_fft_amp_${count}
source_fft_phase_${count}
signal_fft_amp_${count}
signal_fft_phase_${count}
decon_fft_amp_${count}
decon_fft_phase_${count}
modified_fft_amp_${count}
modified_fft_phase_${count}
gauss_fft_amp_${count}
gauss_fft_phase_${count}
divide_fft_amp_${count}
divide_fft_phase_${count}
${WORKDIR_ESF}/${EQ}_${MainPhase}/1/fullstack
${cut}
${DELTA}
${gwidth}
${cutoff_left}
${cutoff_right}
${waterlevel}
${sigma_smooth}
${taperwidth}
${secondarrival}
${secondamp}
${ulvzarrival}
${ulvzamp}
${noiselevel}
EOF

    if [ $? -ne 0 ]
    then
        echo "Game C code failed on Case ${count}..."
        exit 1;
    fi

done < ${WORKDIR}/tmpfile_DataGame_${RunNumber}

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
