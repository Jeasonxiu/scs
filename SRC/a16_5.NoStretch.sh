#!/bin/bash

#=================================================================
# This script: Stretch / Shrink ESF of S to looks like ESF of ScS.
#              Also, write none-stretched ESF S files in the same
#              format.
#
# Outputs:
#
#           ${WORKDIR_Stretch}/${EQ}/
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Work Begins.
for EQ in ${EQnames}
do
	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_a13 where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
	if [ ${NR} -eq 0 ]
	then
		continue
	fi

    echo "    ==> ${EQ} NoStretch/Shrink begin !"

	rm -rf ${WORKDIR_Stretch}/${EQ}
    mkdir -p ${WORKDIR_Stretch}/${EQ}
    cd ${WORKDIR_Stretch}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stretch}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Stretch}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    for cate in `seq 1 ${CateN}`
    do
        ${EXECDIR}/StretchWindow.out 3 3 7 << EOF
2
2
${cate}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/fullstack
${EQ}.ESF_F${cate}.stretched
${LCompare}
${RCompare}
1
1
0
0
${AMPlevel_Default}
EOF

    done # Done Category loop.

done # Done EQ loop.

cd ${CODEDIR}

exit 0
