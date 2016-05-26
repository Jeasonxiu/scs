#!/bin/bash

#=================================================================
# This script: calculate the frequency content of each ESW from
# each cluster.
#
# Outputs: ${WORKDIR_Freq}
#
# Shule Yu
# Apr 22 2015
#=================================================================

echo ""
echo "--> `basename $0` is running."
mkdir -p ${WORKDIR_Freq}
cd ${WORKDIR_Freq}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} .
trap "rm -rf ${WORKDIR_Freq}; exit 1" SIGINT

rm -f tmpfile_Cin
for EQ in ${EQnames}
do

    # Judge whether S and ScS ESF has been made.
    DATADIR_S=${WORKDIR_ESF}/${EQ}_${ReferencePhase}
    DATADIR_ScS=${WORKDIR_ESF}/${EQ}_${MainPhase}

    if ! [ -d ${DATADIR_S} ]
    then
        echo "    ==> ESF of ${ReferencePhase} of ${EQ} doesn't exist ..."
        continue
    fi

    if ! [ -d ${DATADIR_ScS} ]
    then
        echo "    ==> ESF of ${MainPhase} of ${EQ} doesn't exist ..."
        continue
    fi

    for cate in `seq 1 ${CateN}`
    do
        cp ${DATADIR_S}/${cate}/${EQ}.ESF_F ${EQ}.S${cate}.ESF_F 
        cp ${DATADIR_ScS}/${cate}/${EQ}.ESF_F ${EQ}.ScS${cate}.ESF_F 

        echo ${DATADIR_S}/${cate}/${EQ}.ESF_F ${EQ}.S${cate}.ESF_F.freq >> tmpfile_Cin
        echo ${DATADIR_ScS}/${cate}/${EQ}.ESF_F ${EQ}.ScS${cate}.ESF_F.freq >> tmpfile_Cin
    done

done # End of EQ loop.

file=`head -n 1 tmpfile_Cin | awk '{print $1}'`

# Run C Code.
${EXECDIR}/FreqESW.out 2 1 0 << EOF
`wc -l < tmpfile_Cin`
`wc -l < ${file}`
tmpfile_Cin
EOF

if [ $? -ne 0 ]
then
    echo "    !=> Frequency: ${EQ} frequency C code failed..."
    exit 1
fi

cd ${WORKDIR}

exit 0
