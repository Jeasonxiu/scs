#!/bin/bash

#==============================================================
# This script stack FRS over geological bins results.
#
# Outputs:
#
#           ${WORKDIR_Geo}/${BinN}.frstack
#           ${WORKDIR_Geo}/${BinN}.frstack_unweighted
#           ${WORKDIR_Geo}/${BinN}.stackSig
#           ${WORKDIR_Geo}/${binN}.stackSig_max
#
# Update: 
#           ${WORKDIR_Geo}/${BinN}.grid
# Shule Yu
# Jun 23 2015
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

cd ${WORKDIR_Geo}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ./INFILE
trap "rm -f ${WORKDIR_Geo}/* ${WORKDIR}/*_${RunNumber} ; exit 1" SIGINT

# Work Begins.

# Stack FRS through bins.

echo "    ==> Stacking FRSs through Bins."

# C code I/O. Part I.
# Fix Radiation Pattern, S Amplitude.
if [ ${RadFix} -eq 1 ]
then
	mysql -N -u shule ${DB} > tmpfile_trace_weight << EOF
select concat("${WORKDIR_FRS}/",PairName,".frs"),Weight_Final*(Amp_ScS/Rad_Pat_ScS)/(Amp_S/Rad_Pat_S) from Master_a21 where wantit=1;
EOF

else

	mysql -N -u shule ${DB} > tmpfile_trace_weight << EOF
select concat("${WORKDIR_FRS}/",PairName,".frs"),Weight_Final from Master_a21 where wantit=1;
EOF

fi

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    # C code I/O. Part II.
    keys="<EQ> <STNM> <DIST> <binR>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | awk '{print $1"_"$2,$3/$4}' > tmpfile_$$

    rm -f tmpfile_Cin
    while read EQ_STNM dist
    do
        INFO=`grep -w ${EQ_STNM} tmpfile_trace_weight`
        echo "${INFO} ${dist}" >> tmpfile_Cin
    done < tmpfile_$$

    # C code.
    ${EXECDIR}/StackData.out 3 6 3 << EOF
`wc -l < tmpfile_Cin`
`ls ${WORKDIR_FRS}/*.frs | head -n 1 | xargs wc -l | awk '{print $1}'`
${Adaptive}
tmpfile_Cin
${binN}.frstack
${binN}.frstack_unweighted
${binN}.stackSig
${binN}.stackSig_max
tmpfile_new_weights
${DELTA}
${StdSig}
${Smooth_sigma}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> StackFRS C code failed ..."
		sleep 10000
        rm -f ${WORKDIR_Geo}/*
        exit 1;
    fi

    # Update *.grid files. add a column of weights.
	keys=`head -n 1 ${file} | sed s/\<Weight_Smooth\>//g`
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_$$
	echo "${keys} <Weight_Smooth>" > ${file}
    paste tmpfile_$$ tmpfile_new_weights >> ${file}

done # Done Bin loop.

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
