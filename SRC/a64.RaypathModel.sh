#!/bin/bash

# ====================================================================
# This script count how many high-velocity anomalies does one certain
# ray path pass through.
#
# Shule Yu
# May 27 2015
# ====================================================================

echo ""
echo "--> `basename $0` is running."

for TomoModel in `cat ${WORKDIR}/tmpfile_TomoModels_${RunNumber}`
do
    # Model parameters.
    MODELname=${TomoModel%_*}
    MODELcomp=${TomoModel#*_}
    echo "    ==> Tomography Model: ${MODELname}"
    echo "        Component       : ${MODELcomp}"

    mkdir -p ${WORKDIR_Structure}/${TomoModel}
    cd ${WORKDIR_Structure}/${TomoModel}
	cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Structure}/${TomoModel}/INFILE
    trap "rm -rf ${WORKDIR_Structure}/${TomoModel} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # Check the chosen tomography model.
    cp ${WORKDIR_Preprocess}/${TomoModel}/*dat .
    if [ $? -ne 0 ]
    then
        echo "    ~=> Run ${TomoModel} Preprocessing first ..."
		continue
    fi

    # Work Begins.
    for EQ in ${EQnames}
    do
        echo "    ==> Counting path for ${EQ} on ${MODELname} ... "

        # C code I/O. (who has the pattern?)
		mysql -N -u shule ${DB} > tmpfile_Cin << EOF
select stnm,concat("${WORKDIR_Sampling}/${EQ}_",stnm,"_${StructurePhase}.path") from Master_a10 where eq=${EQ} and wantit=1 and misfit_s_all<0 and misfit_scs_all>0 and weight_S_all is not null and weight_S_all>0.85 and weight_ScS_all is not null and weight_ScS_all>0.1;
EOF

        # C code.
        ${EXECDIR}/RaypathModel.out 0 18 5 << EOF
tmpfile_Cin
${EQ}.Count
${EQ}.Count_Source
${EQ}.Count_Receiver
${EQ}.Count_Middle
${EQ}.Extreme
${EQ}.Extreme_Source
${EQ}.Extreme_Receiver
${EQ}.Extreme_Middle
${EQ}.CountL
${EQ}.CountL_Source
${EQ}.CountL_Receiver
${EQ}.CountL_Middle
${EQ}.ExtremeL
${EQ}.ExtremeL_Source
${EQ}.ExtremeL_Receiver
${EQ}.ExtremeL_Middle
S
${VFast}
${VSlow}
${NearSource}
${NearReceiver}
${MiddlePart}
EOF

        if [ $? -ne 0 ]
        then
            echo "    !=> RaypathModel.out failed ..."
            exit 1
        fi

    done # Done EQ loop.

	# Clean up.
	rm -f ${WORKDIR_Structure}/${TomoModel}*dat ${WORKDIR_Structure}/${TomoModel}/tmpfile*

done # Done TomoModel loop.


cd ${CODEDIR}

exit 0
