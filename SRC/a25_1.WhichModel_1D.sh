#!/bin/bash

# ========================================================
# This script use the populated synthesis stack.
# Compare them with data.
#
# Outputs:
#
#           ${WORKDIR_Model}/CompareCCC
#
# Shule Yu
# May 20 2015
# ========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"

# Check model result.
if ! [ -e ${WORKDIR_Model}/INFILE ]
then
    echo "    !=> `basename $0`: no model stack file in ${WORKDIR_Model}..."
    exit 1
fi

cd ${WORKDIR_Model}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Model}/INFILE
trap "rm -f ${WORKDIR_Model}/CompareCCC ${WORKDIR}/*_${RunNumber}" SIGINT

# Work Begins.

# Compare with data.

echo "<BinN> <Model> <CCC> <Norm2> <Norm1> <CCC_Amp>" > CompareCCC

for file in `ls ${WORKDIR_Geo}/*.grid`
do
    binN=${file%.grid}
    binN=${binN##*/}

    echo "    ==> Compare synthesis with data at bin ${binN} ..."

    for Model in ${Modelnames}
    do
        ${EXECDIR}/WhichModel.out 1 4 0 << EOF
${binN}
${WORKDIR_Geo}/${binN}.frstack
${Model}_${binN}.frstack
CompareCCC
${Model}
EOF
    done # Done Model loop.

done # Done Bin loop.

# Clean up.

cd ${WORKDIR}

exit 0
