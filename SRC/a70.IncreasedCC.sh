#!/bin/bash

#==============================================================
# SYNTHESIS
# This script test whether the correlation coefficients
# distribution changed before / after the FRS operation.
# If the distribution is changing to a more scattered pattern
# after the FRS operation, then we can say our method helps
# increasing the resolution.
#
# Outputs:
#
#           ${WORKDIR_Resolution}/${Dist}
#
# Shule Yu
# Sept 23 2015
#==============================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Resolution}
cd ${WORKDIR_Resolution}
trap "rm -f ${WORKDIR_Resolution}/* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.
for Dist in `seq ${D1_CC} ${DInc_CC} ${D2_CC}`
do

	OUTFILE=ScS_${Dist}
	OUTFILE2=FRS_${Dist}
	OUTFILE3=ScS_Norm2_${Dist}
	OUTFILE4=FRS_Norm2_${Dist}
	rm -f ${OUTFILE} ${OUTFILE2} ${OUTFILE3} ${OUTFILE4}

	# Find synthesis station name.
	EQ=`echo "${EQnames}" | awk 'NR==1 {print $1}'`
	STNM=`${BASHCODEDIR}/Findfield.sh ${WORKDIR_Basicinfo}/${EQ}.BasicInfo "<STNM> <GCARC>" | awk -v D=${Dist} '{if ($2==D) print $1}'`

	# Check files.

	rm -f tmpfile_Cin_ScS tmpfile_Cin_FRS
	for EQ in ${EQnames}
	do
		if ! [ -e ${WORKDIR_Decon}/${EQ}/${STNM}.trace ]
		then
			echo "        !=> Can't find ${EQ} Deconed ScS file for ${STNM}..."
			rm -f tmpfile*
			exit 1;
		fi

		if ! [ -e ${WORKDIR_FRS}/${EQ}_${STNM}.frs ]
		then
			echo "        !=> Can't find ${EQ} FRS file for ${STNM}..."
			rm -f tmpfile*
			exit 1;
		fi

		echo ${WORKDIR_Decon}/${EQ}/${STNM}.trace >> tmpfile_Cin_ScS
		echo ${WORKDIR_FRS}/${EQ}_${STNM}.frs >> tmpfile_Cin_FRS

	done

	# Do CC on Deconed ScS traces.
	echo "    ==> Compare Deconed ScS across model space on ${Dist}..."
	${EXECDIR}/CCModelScS.out 1 3 2 << EOF
`wc -l < tmpfile_Cin_ScS`
tmpfile_Cin_ScS
${OUTFILE}
${OUTFILE3}
${Time}
${DELTA}
EOF

	if [ $? -ne 0 ]
	then
		echo "    !=> CCModelScS C code failed ..."
		exit 1
	fi

	# Do CC on FRS traces.
	echo "    ==> Compare FRS across model space on ${Dist}..."
	${EXECDIR}/CCModelFRS.out 1 3 2 << EOF
`wc -l < tmpfile_Cin_FRS`
tmpfile_Cin_FRS
${OUTFILE2}
${OUTFILE4}
${Time}
${DELTA}
EOF

	if [ $? -ne 0 ]
	then
		echo "    !=> CCModelFRS C code failed ..."
		exit 1
	fi

done # End of Distance loop.

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
