#!/bin/bash

# ========================================================
# This script populate the synthesis to make a same set of
# synthesis as data in terms of the great circle distance.
# Execute after a41. is done.
#
# Outputs:
#
#           ${WORKDIR_Model}/${Model}_${BinN}.frstack
#
# Shule Yu
# Apr 22 2015
# ========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Check bin stack result.
if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> `basename $0`: No bin stack result in ${WORKDIR_Geo} ..."
    exit 1
fi

# Check Synthesis FRS result.
if ! [ -e ${SYNWORKDIR_FRS}/INFILE ]
then
    echo "    !=> `basename $0`: no synthesis frs traces in ${SYNWORKDIR_FRS} ..."
    exit 1
fi

mkdir -p ${WORKDIR_Model}
cd ${WORKDIR_Model}
rm -f ${WORKDIR_Model}/*
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Model}/INFILE
trap "rm -rf ${WORKDIR_Model}/* ${WORKDIR}/*_${RunNumber} ; exit 1" SIGINT

# Work Begins.

echo "    ==> Stacking Synthesis for each bins ..."

# Make synthesis stacks.

# Info Gathering. For each bin, get gcarc-weight.
for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    keys="<EQ> <STNM> <Weight_Smooth>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_$$

	mysql -N -u shule ${DB} > tmpfile_eq_stnm_gcarc_$$ << EOF
select EQ,STNM,SHIFT_GCARC from Master_a21 where wantit=1;
EOF

    rm -f tmpfile_${binN}_gcarc_weight_$$
    while read EQ STNM weight
    do
        awk -v E=${EQ} -v S=${STNM} -v W=${weight} '{ if ($1==E && $2==S) printf "%.1lf\t%.3lf\n",$3,W}' tmpfile_eq_stnm_gcarc_$$ >> tmpfile_${binN}_gcarc_weight_$$
    done < tmpfile_$$

done # Done bin loop.

# Info Gathering. For each Model, get gcarc-frsfile.

for Model in ${Modelnames}
do
	mysql -N -u shule ${SYNDB} > tmpfile_${Model}_$$ << EOF
select truncate(GCARC,1),concat("${SYNWORKDIR_FRS}/",EQ,"_",STNM,".frs") from Master_a41 where eq=${Model} and wantit=1;
EOF

done

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    for Model in ${Modelnames}
    do
		# Info Gathering. For each bin-Model pair, use the same gcarc,
		# get frsfile-weight list as the c code input.
        D_Min=`minmax -C tmpfile_${Model}_$$ | awk '{printf "%.1lf",$1+0.1}'`
        D_Max=`minmax -C tmpfile_${Model}_$$ | awk '{printf "%.1lf",$2-0.1}'`
        awk -v M=${D_Min} -v D=${D_Max} '{ if ($1>D) printf "%.1lf\n",D ; else if ($1<M) printf "%.1lf\n",M; else printf "%.1lf\n",$1}' tmpfile_${binN}_gcarc_weight_$$ > tmpfile_grouplist_$$

        awk '{ print $2 }' tmpfile_${binN}_gcarc_weight_$$ > tmpfile_weight_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_${Model}_$$ tmpfile_grouplist_$$ | awk '{print $2}' > tmpfile1_$$
        paste tmpfile1_$$ tmpfile_weight_$$ > ${Model}_${binN}.frsfile_weight

        firstfile=`head -n 1 ${Model}_${binN}.frsfile_weight | awk '{print $1}'`

        # C code.
        ${EXECDIR}/StackModels.out 1 2 1 << EOF
`wc -l < ${firstfile}`
${Model}_${binN}.frsfile_weight
${Model}_${binN}.frstack
${DELTA}
EOF

    done # Done Model loop.

done # Done Bin loop.

# Clean up.
rm -f ${WORKDIR_Model}/tmpfile*$$

cd ${CODEDIR}

exit 0
