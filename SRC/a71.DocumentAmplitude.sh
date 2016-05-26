#!/bin/bash

#==============================================================
# SYNTHESIS
# This script document the S and ScS peak amplitude ratio change
# with respect to gcarc.
# Outputs:
#
#           ${WORKDIR_Amplitude}/${EQ}.dat
#
# Shule Yu
# Mar 02 2016
#==============================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Amplitude}
cd ${WORKDIR_Amplitude}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Amplitude}/INFILE
trap "rm -f ${WORKDIR_Amplitude}/* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.
for EQ in ${EQnames}
do

	rm -f ${EQ}.dat
	for cateN in `seq 1 ${CateN}`
	do
		dir1="${WORKDIR_ESF}/${EQ}_${MainPhase}/${cateN}"
		dir2="${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cateN}"
		if ! [ -e ${dir1}/*DT ] || ! [ -e ${dir2}/*DT ]
		then
			echo "    ~=> Do ESF for ${EQ} on category ${cateN} first..."
			continue
		fi

		keys="<STNM> <GCARC>"
		${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" > tmpfile_stnm_gcarc

		keys="<STNM> <Amplitude>"
		${BASHCODEDIR}/Findfield.sh `ls ${dir1}/*DT` "${keys}" > tmpfileScS_stnm_amplitude
		${BASHCODEDIR}/Findfield.sh `ls ${dir2}/*DT` "${keys}" > tmpfileS_stnm_amplitude

		awk '{print $1}' tmpfileScS_stnm_amplitude > tmpfile_stnm.lst
		${BASHCODEDIR}/Findrow.sh tmpfileS_stnm_amplitude tmpfile_stnm.lst > tmpfile_$$
		mv tmpfile_$$ tmpfileS_stnm_amplitude

		awk '{print $1}' tmpfileS_stnm_amplitude > tmpfile_stnm.lst
		${BASHCODEDIR}/Findrow.sh tmpfileScS_stnm_amplitude tmpfile_stnm.lst > tmpfile_$$
		mv tmpfile_$$ tmpfileScS_stnm_amplitude
		${BASHCODEDIR}/Findrow.sh tmpfileS_stnm_amplitude tmpfile_stnm.lst > tmpfile_$$
		mv tmpfile_$$ tmpfileS_stnm_amplitude

		${BASHCODEDIR}/Findrow.sh tmpfile_stnm_gcarc tmpfile_stnm.lst > tmpfile_$$
		mv tmpfile_$$ tmpfile_stnm_gcarc

		# 1. ScS/S:
		paste tmpfileS_stnm_amplitude tmpfileScS_stnm_amplitude tmpfile_stnm_gcarc | awk '{print $6,$4/$2}' >> ${EQ}.dat

		# or 2. ScS (normalized to 0~1):
# 		paste tmpfileScS_stnm_amplitude tmpfile_stnm_gcarc | awk '{print $4,$2}' > tmpfile_gcarc_ratio
# 		MAXAmp=`minmax -C tmpfile_gcarc_ratio | awk '{print $4}'`
# 		awk -v A=${MAXAmp} '{print $1,$2/A}' tmpfile_gcarc_ratio >> ${EQ}.dat

		# or 3. S (normalized to 0~1):
# 		paste tmpfileS_stnm_amplitude tmpfile_stnm_gcarc | awk '{print $4,$2}' > tmpfile_gcarc_ratio
# 		MAXAmp=`minmax -C tmpfile_gcarc_ratio | awk '{print $4}'`
# 		awk -v A=${MAXAmp} '{print $1,$2/A}' tmpfile_gcarc_ratio >> ${EQ}.dat


	done # Done category loop.

done # End of Model loop.

# Clean up.
rm -f ${WORKDIR_Amplitude}/tmpfile*

cd ${CODEDIR}

exit 0
