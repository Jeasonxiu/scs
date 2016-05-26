#!/bin/bash

# =========================================================
# This script run kmeans cluster analysis on S waveforms to
# devide waveforms from one earthquake into several sub-
# categories.
#
# Outputs:
#
#           ${WORKDIR_Category}/${EQ}.Category
#
# Shule Yu
# Jun 22 2014
# =========================================================

echo ""
echo "--> `basename $0` is running. "

# Work Begins.
for EQ in ${EQnames}
do

    mkdir -p ${WORKDIR_Category}/${EQ}
    cd ${WORKDIR_Category}/${EQ}
    cp ${WORKDIR}/INFILE .
    trap "rm -r ${WORKDIR_Category}/${EQ} ${WORKDIR}/*_${RunNumber} 2>/dev/null; exit 1" SIGINT

    echo "    ==> Categorizing ${EQ} S shape..."

    # C code I/O.

    ## select only weight != 0 stations.
    keys="<STNM> <Weight>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${MainPhase}/${EQ}.ESF_DT "${keys}" | awk '{ if ($2>0.1) print $1 }' > tmpfile_stnm

    keys="<STNM> <Weight> <Peak> <Polarity>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${EQ}.ESF_DT "${keys}" | awk '{ if ($2>0.1) print $1,$3,$4}' > tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm > tmpfile_station_list

    ## make input file.
    rm tmpfile_Cin 2>/dev/null
    while read stnm Peak polarity
    do
        echo "${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/${stnm}.waveform ${stnm} ${Peak} ${polarity}" >> tmpfile_Cin
    done < tmpfile_station_list


    # C code.
    ${EXECDIR}/category.out 2 2 4 << EOF
`wc -l < tmpfile_Cin`
`echo "${CateWidth}/${DELTA} + 1" | bc`
tmpfile_Cin
tmpfile_kmeans.txt
${CateAMPlevel}
${CateWidth}
${CateTaper}
${DELTA}
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> category C code failed ..."
        exit 1
    fi

    # Do Clustering.
    mlpack_kmeans -c ${CateN} -i tmpfile_kmeans.txt -o tmpfile_kmeans.txt
    awk '{printf "%d\n",$NF}' tmpfile_kmeans.txt > tmpfile_result

    # Rearrange cluster result. So that the cluster with most population is always # 1.
    for count in `seq 0 $((CateN-1))`
    do
        Trace[$((count+1))]=`awk -v C=${count} '{if ($1==C) print $1 }' tmpfile_result | wc -l`
    done

    for count in `seq 1 ${CateN}`
    do
        New[${count}]=1
        for count2 in `seq 1 ${CateN}`
        do
            if [ ${Trace[${count2}]} -gt ${Trace[${count}]} ]
            then
                New[${count}]=$((New[${count}]+1))
            fi
        done
    done

    for count in `seq 1 $((CateN-1))`
    do
        for count2 in `seq $((count+1)) ${CateN}`
        do
            if [ ${New[${count2}]} -eq ${New[${count}]} ]
            then
                New[${count2}]=$((New[${count2}]+1))
            fi
        done
    done

    rm tmpfile_$$ 2>/dev/null
    while read cate
    do
        cate=$((cate+1))
        echo ${New[${cate}]} >> tmpfile_$$
    done < tmpfile_result

    paste tmpfile_station_list tmpfile_$$ | awk '{print $1,$4}' > tmpfile1_$$
    echo "<STNM> <Cate>" > ${EQ}.Category
    cat tmpfile1_$$ >> ${EQ}.Category

    # Clean up.
    rm tmpfile* 2>/dev/null

done # Done EQ loop.

cd ${CODEDIR}

exit 0
