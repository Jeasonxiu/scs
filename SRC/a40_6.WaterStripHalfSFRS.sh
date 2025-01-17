#!/bin/bash

#==============================================================
# This script chop each de-convolved ScS at their peak and do
# Flip-Reverse-Sum ( FRS ) operation.
#
# Outputs:
#
#           ${WORKDIR_WaterHalfSFRS}/${EQ}_${STNM}.frs
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. "
rm -rf ${WORKDIR_WaterHalfSFRS}
mkdir -p ${WORKDIR_WaterHalfSFRS}
cd ${WORKDIR_WaterHalfSFRS}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_WaterHalfSFRS}/INFILE
trap "rm -f ${WORKDIR_WaterHalfSFRS}/tmpfile* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT


echo "    ==> Flipping ..."

# ==================================================
#       ! Flip-Reverse-Sum !
# ==================================================

for EQ in ${EQnames}
do

	# C code I/O.
	mysql -N -u shule ${SYNDB} > tmpfile_Cinfile << EOF
select concat("${WORKDIR_WaterHalfSDecon}/",EQ,"/",STNM,".trace"),concat(EQ,"_",STNM,".frs") from Master_a38 where eq=${EQ} and wantit=1;
EOF

	# C code.
	${EXECDIR}/FRS.out 0 1 2 << EOF
tmpfile_Cinfile
${Time}
${DELTA}
EOF

	if [ $? -ne 0 ]
	then
		echo "    !=> FRS C code failed ..."
		rm -f ${WORKDIR_WaterHalfSFRS}/*
		exit 1;
	fi
done

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
