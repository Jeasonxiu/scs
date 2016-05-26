#!/bin/bash

#=================================================================
# SYNTHESIS
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
echo "--> `basename $0` is running."

# Work Begins.
for EQ in ${EQnames}
do
    echo "    ==> ${EQ} Stretch/Shrink begin !"

	rm -rf ${WORKDIR_Stretch}/${EQ}
    mkdir -p ${WORKDIR_Stretch}/${EQ}
    cd ${WORKDIR_Stretch}/${EQ}
    cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Stretch}/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Stretch}/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Set specialized EQ parameters.

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

        # C Code. (Tstar S)
        ${EXECDIR}/TstarStretchWindow.out 2 6 6 << EOF
${nXStretch}
${cate}
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/fullstack
${EQ}.ESF_F${cate}.stretched
${EQ}.ESF_F${cate}.original
Stretch_Info.${cate}
S_GET_Tstarred
${LCompare}
${RCompare}
0.0
2.0
${AMPlevel_Default}
0.0
EOF

        if [ $? -ne 0 ]
        then
            echo "    !=> Stretch: ${EQ} stretch C code failed for Category: ${cate} ..."
            continue
        fi

		if [ -e S_GET_Tstarred ]
		then
			echo "        S get Tstarred..."
			continue
		fi
		echo "        ScS get Tstarred..."

		# C Code. (Tstar ScS)
        ${EXECDIR}/TstarStretchWindow.out 2 6 6 << EOF
${nXStretch}
${cate}
${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/fullstack
${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/fullstack
${EQ}.ScS.stretched
${EQ}.ESF_F${cate}.stretched
tmpfile_$$
ScS_GET_Tstarred
${LCompare}
${RCompare}
0.0
2.0
${AMPlevel_Default}
0.0
EOF

	awk '{print -$1,$2,$3,$4}' tmpfile_$$ > Stretch_Info.${cate}

    done # Done Category loop.


	rm -f tmpfile_$$

done # Done EQ loop.

cd ${CODEDIR}

exit 0
