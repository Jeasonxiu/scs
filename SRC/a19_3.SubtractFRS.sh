#!/bin/bash

#==============================================================
# This script chop each de-convolved ScS at their peak and do
# Flip-Reverse-Sum ( FRS ) operation.
#
# Outputs:
#
#           ${WORKDIR_SubtractFRS}/${EQ}_${STNM}.frs
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_SubtractFRS}
rm -rf ${WORKDIR_SubtractFRS}/*
cd ${WORKDIR_SubtractFRS}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_SubtractFRS}/INFILE
trap "rm -f ${WORKDIR_SubtractFRS}/tmpfile* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT


echo "    ==> Flipping ..."

# ==================================================
#       ! Flip-Reverse-Sum !
# ==================================================

for EQ in ${EQnames}
do
	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_a17 where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
	if [ ${NR} -eq 0 ]
	then
		continue
	fi


	# C code I/O.
	mysql -N -u shule ${DB} > tmpfile_Cinfile << EOF
select concat("${WORKDIR_SubtractDecon}/",EQ,"/",STNM,".trace"),concat(EQ,"_",STNM,".frs") from Master_a17 where eq=${EQ} and wantit=1;
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
		rm -f ${WORKDIR_SubtractFRS}/*
		exit 1;
	fi
done

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
