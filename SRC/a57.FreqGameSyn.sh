#!/bin/bash

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Game}
cd ${WORKDIR_Game}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Game}/INFILE
trap "rm -f ${WORKDIR_Game}/INFILE; exit 1" SIGINT

# ==================================================
#              ! Work Begin !
# ==================================================

# Game parameters.
NPTS_signal=10000
taperwidth=0.1

# I/O.
count=0

while read sigma_source gwidth cutoff_left cutoff_right waterlevel sigma_smooth secondarrival secondamp ulvzarrival ulvzamp method
do
    count=$((count+1))

    # Run C code.
    ${EXECDIR}/FreqGameSyn.out 2 18 12 << EOF
${NPTS_signal}
${method}
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
${DELTA}
${sigma_source}
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
EOF

    if [ $? -ne 0 ]
    then
        echo "Game C code failed on Case ${count}..."
        exit 1;
    fi

done < ${WORKDIR}/tmpfile_Game_${RunNumber}

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
