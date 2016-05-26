#!/bin/bash

# ===========================================================
# Plot a93.synthesisGame.sh result.
#
# Shule Yu
# Apr 29 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

# Plot parameters.
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 10p
gmtset LABEL_OFFSET = 0.05c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

if ! [ -e ${WORKDIR_Game}/INFILE ]
then
    echo "    ==> Run a93.synthesisGame.sh first..."
    exit 1
else
    echo "    ==> Plotting Game results."
fi

CaseN=`wc -l < ${WORKDIR}/tmpfile_Game_${RunNumber}`
for count in `seq 1 ${CaseN}`
do

    # ===========================
    #         ! Plot 1 !
    # ===========================

    REG="-R-50/50/-0.5/1.1"
    PROJ="-JX7i/`echo "10.5 *6 / 7 / 4" | bc -l`i"
    OUTFILE=${count}.ps

    # Plot fancy title.
    pstext ${REG} ${PROJ} -Y11i -P -N -K > ${OUTFILE} << EOF
0 -0.65 10 0 0 CB Structure - Source - Signal - Deconvolution. (Case ${count})
EOF

    for file in ${WORKDIR_Game}/waterlevel_decon_out_structure_${count} ${WORKDIR_Game}/waterlevel_decon_out_source_${count} ${WORKDIR_Game}/waterlevel_decon_out_signal_${count} ${WORKDIR_Game}/waterlevel_decon_out_decon_${count}
    do

        if [ ${file} = "${WORKDIR_Game}/waterlevel_decon_out_decon_${count}" ]
        then
            psbasemap -R -J -Ba10g10f1:Sec.:/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        else
            psbasemap -R -J -Ba10g10f1/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        fi

        # Plot file.
        psxy ${file} -W0.03p -R -J -O -K >> ${OUTFILE}

    done # done file loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # Done case loop.
cat `ls *.ps | sort -n` > tmpfile1

# ===========================
#         ! Plot 2 ! Freq.
# ===========================

for count in `seq 1 ${CaseN}`
do

    REG="-R0/1/-0.05/1.1"
    PROJ="-JX7i/`echo "10.5 *6 / 7 / 4" | bc -l`i"
    OUTFILE=${count}.ps

    # Plot fancy title.
    pstext ${REG} ${PROJ} -Y11i -P -N -K > ${OUTFILE} << EOF
15 -0.4 10 0 0 CB FRS without / with Decon. (Case ${count})
EOF

    for file in ${WORKDIR_Game}/structure_fft_amp_${count} ${WORKDIR_Game}/source_fft_amp_${count} ${WORKDIR_Game}/signal_fft_amp_${count} ${WORKDIR_Game}/decon_fft_amp_${count}
    do

        if [ ${file} = "${WORKDIR_Game}/decon_fft_amp_${count}" ]
        then
            psbasemap -R -J -Ba0.1g0.1f0.1:Freq.:/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        else
            psbasemap -R -J -Ba0.1g0.1f0.1/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        fi

        # Plot file.
        psxy ${file} -W0.03p,red -R -J -O -K >> ${OUTFILE}
        psxy ${file} -Sc2p -Gblack -R -J -O -K >> ${OUTFILE}

        if [ ${file} = "${WORKDIR_Game}/signal_fft_amp_${count}" ]
        then

            awk '{print $1}' ${WORKDIR_Game}/modified_fft_amp_${count} > tmpfile_paste1
            awk '{print $2}' ${WORKDIR_Game}/modified_fft_amp_${count} > tmpfile_$$
            ${BASHCODEDIR}/normalize.sh tmpfile_$$ > tmpfile_paste2
            paste tmpfile_paste1 tmpfile_paste2 > tmpfile1_$$ 

            awk '{print $1}' ${WORKDIR_Game}/gauss_fft_amp_${count} > tmpfile_paste1
            awk '{print $2}' ${WORKDIR_Game}/gauss_fft_amp_${count} > tmpfile_$$
            ${BASHCODEDIR}/normalize.sh tmpfile_$$ > tmpfile_paste2
            paste tmpfile_paste1 tmpfile_paste2 > tmpfile2_$$ 

            psxy tmpfile1_$$ -Sc2p -Gblue -R -J -O -K >> ${OUTFILE}
            psxy tmpfile2_$$ -Sc2p -Ggreen -R -J -O -K >> ${OUTFILE}

        fi

    done # done file loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # Done case loop.
cat `ls *.ps | sort -n` > tmpfile2

# ===========================
#         ! Plot 3 !
# ===========================

for count in `seq 1 ${CaseN}`
do

    REG="-R0/30/-0.3/0.8"
    PROJ="-JX7i/`echo "10.5 *6 / 7 / 4" | bc -l`i"
    OUTFILE=${count}.ps

    # Plot fancy title.
    pstext ${REG} ${PROJ} -Y11i -P -N -K > ${OUTFILE} << EOF
15 -0.4 10 0 0 CB FRS without / with Decon. (Case ${count})
EOF

    for file in ${WORKDIR_Game}/waterlevel_decon_out_frs_nodecon_${count} ${WORKDIR_Game}/waterlevel_decon_out_frs_${count}
    do

        if [ ${file} = "${WORKDIR_Game}/waterlevel_decon_out_frs_${count}" ]
        then
            psbasemap -R -J -Ba5g1f1:Sec.:/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        else
            psbasemap -R -J -Ba5g1f1/a0.5g0.1f0.1WSne -Y-`echo "10.5/4" | bc -l`i -O -K >> ${OUTFILE}
        fi

        # Plot file.
        psxy ${file} -W0.03p -R -J -O -K >> ${OUTFILE}

    done # done file loop.

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

done # Done case loop.
cat `ls *.ps | sort -n` > tmpfile3

# Make PDFs.
ps2pdf tmpfile1 ${WORKDIR_Plot}/Game_1.pdf
ps2pdf tmpfile2 ${WORKDIR_Plot}/Game_2.pdf
ps2pdf tmpfile3 ${WORKDIR_Plot}/Game_3.pdf

cd ${CODEDIR}

exit 0
