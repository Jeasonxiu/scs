#!/bin/bash

#==============================================================
# SYNTHESIS
# This script merge information of each EQ-ST pair from all
# steps previously done.
#
# Outputs:
#
#           ${WORKDIR_FRS}/INFO_All
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_FRS}
cd ${WORKDIR_FRS}
cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ./INFILE
trap "rm -f ${WORKDIR_FRS}/* ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT
echo "    ==> Generating EQ_Station pairs information..."

# Work Begins.
for EQ in ${EQnames}
do

    keys="<STNM>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Decon}/${EQ}/${EQ}_StretchDecon_Info "${keys}" > tmpfile_stnm
    if ! [ -s tmpfile_stnm ]
    then
        continue
    fi

    # 1. Station INFO_All.
    keys="<STNM> <EQ> <NETWK> <GCARC> <AZ> <BAZ> <STLO> <STLA> <EVLO> <EVLA>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Select}/${EQ}.BasicInfo "${keys}" > tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm > tmpfile_paste_1

    # 2. S and ScS INFO_All.
    rm -f tmpfile_paste_2 tmpfile_paste_3
    for cate in `seq 1 ${CateN}`
    do
        keys="<STNM> <D_T> <CCC> <SNR> <Weight> <Peak> <Rad_Pat> <Misfit> <Norm2> <Polarity>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${ReferencePhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0 }' >> tmpfile_paste_2

        keys="<STNM> <D_T> <CCC> <SNR> <Weight> <Peak> <Rad_Pat> <Misfit> <Norm2> <Polarity>"
        ${BASHCODEDIR}/Findfield.sh ${WORKDIR_ESF}/${EQ}_${MainPhase}/${cate}/${EQ}.ESF_DT "${keys}" > tmpfile_$$
        ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0 }' >> tmpfile_paste_3

    done

    # 3. StretchDecon INFO_All.
    keys="<STNM> <Cate> <SNR_1> <SNR_2> <SNR> <CCC_St> <Misfit_St> <Shift_St>"
    ${BASHCODEDIR}/Findfield.sh ${WORKDIR_Decon}/${EQ}/${EQ}_StretchDecon_Info "${keys}" > tmpfile_$$
    ${BASHCODEDIR}/Findrow.sh tmpfile_$$ tmpfile_stnm | awk '{$1="" ; print $0 }' > tmpfile_paste_4

    paste tmpfile_paste_1 tmpfile_paste_2 tmpfile_paste_3 tmpfile_paste_4 > tmpfile_${EQ}

done # End of EQ loop. done INFO creation.

# Merge all of the estimations. Make INFO_All file.
keys1="<STNM> <EQ> <NETNM> <GCARC> <AZ> <BAZ> <STLO> <STLA> <EVLO> <EVLA>"
keys2="<D_T_S> <CCC_S> <SNR_S> <Weight_S> <Peak_S> <Rad_Pat_S> <Misfit_S> <Norm2_S> <Polarity_S>"
keys3="<D_T_ScS> <CCC_ScS> <SNR_ScS> <Weight_ScS> <Peak_ScS> <Rad_Pat_ScS> <Misfit_ScS> <Norm2_ScS> <Polarity_ScS>"
keys4="<Cate> <SNR_1> <SNR_2> <SNR_D> <CCC_St> <Misfit_St> <Shift_St>"
echo "${keys1} ${keys2} ${keys3} ${keys4}" > INFO_All

for EQ in ${EQnames}
do
    if [ -e tmpfile_${EQ} ]
    then
        cat tmpfile_${EQ} >> INFO_All
    fi
done

if [ `wc -l < INFO_All` -le 1 ]
then
    echo "    ==> `basename $0`: no traces left for INFO_All ..."
    exit 1
else
    echo "    ==> Number of FRS : `wc -l < INFO_All | awk '{print $1-1}'`"
fi

# Clean up.
rm -f ${WORKDIR_FRS}/tmpfile*

cd ${CODEDIR}

exit 0
