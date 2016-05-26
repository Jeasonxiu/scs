#!/bin/bash

#==============================================================
# This script run cluster analysis on geographic bin stacks.
#
# Outputs:
#
#           ${WORKDIR_Cluster}/
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. "

# Check bin stack result.
if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> `basename $0`: no bin stack result in ${WORKDIR_Geo} ..."
    exit 1
fi

mkdir -p ${WORKDIR_Cluster}
cd ${WORKDIR_Cluster}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Cluster}
trap "rm -f ${WORKDIR_Cluster}/* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Work Begins.

echo "    ==> Cluster analysis on each bin FRS stacks ..."

# Run Cluster Analysis on each bin's stack.

## I/O.
rm -f tmpfile_kmeans.csv tmpfile_paste1
for file in `ls ${WORKDIR_Geo}/*frstack | sort -g`
do
    BinN=${file%.frstack}
    BinN=${BinN##*/}
    echo ${BinN} >> tmpfile_paste1
    awk -v F=${FirstXSec} '{if ($1<F) printf "%.5e ,", $2}' ${file} >> tmpfile_kmeans.csv
    printf "\n" >> tmpfile_kmeans.csv
done

## Run Clustering.
mlpack_kmeans -c ${ClusterNum} -i tmpfile_kmeans.csv -o tmpfile_kmeans.txt
awk '{printf "%d\n",$NF}' tmpfile_kmeans.txt > tmpfile_paste2
paste tmpfile_paste1 tmpfile_paste2 > Grid_Cate

# Rearrange cluster so that the cluster with least traces are #1.
for count in `seq 0 $((ClusterNum-1))`
do
    Trace[$((count+1))]=`awk -v C=${count} '{if ($2==C) print $0 }' Grid_Cate | wc -l`
done

for count in `seq 1 ${ClusterNum}`
do
    New[${count}]=1
    for count2 in `seq 1 ${ClusterNum}`
    do
        if [ ${Trace[${count2}]} -lt ${Trace[${count}]} ]
        then
            New[${count}]=$((New[${count}]+1))
        fi
    done
done

for count in `seq 1 $((ClusterNum-1))`
do
    for count2 in `seq $((count+1)) ${ClusterNum}`
    do
        if [ ${New[${count2}]} -eq ${New[${count}]} ]
        then
            New[${count2}]=$((New[${count2}]+1))
        fi
    done
done

rm -f tmpfile_$$
while read grid cate
do
    cate=$((cate+1))
    echo ${grid} ${New[${cate}]} >> tmpfile_$$
done < Grid_Cate
mv tmpfile_$$ Grid_Cate

# Clean up.
rm -f tmpfile*

cd ${CODEDIR}

exit 0
