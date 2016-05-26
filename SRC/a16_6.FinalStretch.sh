#!/bin/bash

#=================================================================
# This script: Stretch S/ScS ESF to look like ScS/S ESF.
# Vertical stretch is always applied on S.
# Horizontal stretch (tstar) is applied on S when Ts>=0.
# Horizontal stretch (tstar) is applied on ScS when Ts<0.
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

    echo "    ==> ${EQ} Stretching begin !"

	rm -rf ${WORKDIR_Stretch}/${EQ}
    mkdir -p ${WORKDIR_Stretch}/${EQ}
    cd ${WORKDIR_Stretch}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stretch}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Stretch}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    for cate in `seq 1 ${CateN}`
    do

        # Check ESF result.

        if ! [ -d ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate} ]
        then
            echo "    !=> ${ReferencePhase}_${EQ}_Category${cate} ESF doesn't exist ..."
            continue
        fi

        if ! [ -d ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate} ]
        then
            echo "    !=> ${MainPhase}_${EQ}_Category${cate} ESF doesn't exist ..."
            continue
        fi

        # C Code.
        ${EXECDIR}/FinalStretch.out 3 7 8 << EOF
${nXStretch}
${nYStretch}
${cate}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/fullstack
${EQ}.ESF_F${cate}.stretched
${EQ}.ESF_F${cate}.newScS
Stretch_Info.${cate}
plotfile_shifted_original_${cate}
Stretch_Info.Best.${cate}
${LCompare}
${RCompare}
-2.0
2.0
${V1}
${V2}
${AMPlevel_Default}
${DELTA}
EOF

        if [ $? -ne 0 ]
        then
            echo "    !=> Stretch: ${EQ} stretch C code failed for Category: ${cate} ..."
            continue
        fi

    done # Done Category loop.

done # Done EQ loop.

cd ${WORKDIR}

exit 0
