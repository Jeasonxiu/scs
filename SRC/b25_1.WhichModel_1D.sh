#!/bin/bash

# ===========================================================
# Plot Modeling result.
#
# Shule Yu
# May 19 2015
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT


# =========================================
#     ! Check the calculation result !
# =========================================
if ! [ -e ${WORKDIR_Model}/CompareCCC ]
then
    echo "    ==> `basename $0`: Run modeling first ..."
    continue
else
    echo "    ==> Plotting modeling result."
fi


# Plot parameters.
height=`echo ${PLOTHEIGHT_M}/${PLOTY_M} | bc -l`
width=`echo ${PLOTWIDTH_M}/${PLOTX_M} | bc -l`
color_model=red
color_data=black


gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

if [ ${CompareKey} = "CCC" ] || [ ${CompareKey} = "CCC_new" ]
then
    CompareString="-g -r -k 3,3"
else
    CompareString="-g -k 3,3"
fi

# sort the model of this bin according to the compare key:
#     keys="<BinN> <Model> <CCC> <Norm2> <Norm1> <CCC_new>"
keys="<BinN> <Model> <${CompareKey}>"
${BASHCODEDIR}/Findfield.sh ${WORKDIR_Model}/CompareCCC "${keys}" > tmpfile_compare

rm tmpfile_selectedmodels 2>/dev/null
for Model in ${Modelnames}
do
    grep ${Model} tmpfile_compare >> tmpfile_selectedmodels
done

sort ${CompareString} tmpfile_selectedmodels | awk '{print $1,$2}' > tmpfile_sorted

Nbins=`ls ${WORKDIR_Geo}/*.grid | wc -l`

for binN in `seq 1 ${Nbins}`
do

    NRecord=`wc -l < ${WORKDIR_Geo}/${binN}.grid`

    BestFit=`awk -v B=${binN} '{if ($1==B) print $2}' tmpfile_sorted | head -n 5`
    LeastFit=`awk -v B=${binN} '{if ($1==B) print $2}' tmpfile_sorted | tail -n 5`

    page=0
    plot=$((PLOTX_M*PLOTY_M+1))

    for Model in ${Modelnames}
    do


        # get model parameters.
#     keys="<EQ> <Thickness> <Vp_Bot> <Vp_Top> <Vs_Bot> <Vs_Top> <Rho_Bot> <Rho_Top>"
        echo "${Model}" > tmpfile_$$
        INFO=`${BASHCODEDIR}/Findrow.sh ${SYNDATADIR}/index tmpfile_$$`
        Thickness=`echo "${INFO}" | awk '{print $2}'`
        Vs=`echo "${INFO}" | awk '{print $5}'`
        Rho=`echo "${INFO}" | awk '{print $7}'`
        Estimation=`awk -v M=${Model} -v B=${binN} '{if ($1==B && $2==M) print $3}' tmpfile_compare`

        # ===================================
        #        ! Plot !
        # ===================================

        ## 4.2 check if need to plot on a new page.
        if [ ${plot} -eq $((PLOTX_M*PLOTY_M+1)) ]
        then

            ### 4.2.1. if this isn't first page, seal the last page.
            if [ ${page} -gt 0 ]
            then
                psxy -J -R -O >> ${OUTFILE} << EOF
EOF
            fi

            ### 4.2.2 plot titles and legends
            plot=1
            page=$((page+1))
            OUTFILE=${page}.ps
            title="Modeling plot, Bin Number ${binN}, NR = $((NRecord-1))"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.5i -Y8i -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title}
EOF

        ## 4.3 go to the right position (preparing to plot seismograms)
        psxy -JX`echo "0.9*${width}"|bc -l`i/`echo "0.9*${height}"| bc -l`i -R${TIMEMIN_M}/${TIMEMAX_M}/-1/1 -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        fi # end test if it's a new page.

        ### plot zero line
        psxy -J -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${TIMEMIN_M} 0
${TIMEMAX_M} 0
EOF
        for  time in `seq 0 20`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
    `echo "${time} * ${Tick_M}" | bc -l` 0
EOF
        done

        ### data.
        psxy ${WORKDIR_Geo}/${binN}.frstack -J -R -W0.5p,${color_data} -O -K >> ${OUTFILE}

        ### synthesis.
        psxy ${WORKDIR_Model}/${Model}_${binN}.frstack -J -R -W0.5p,${color_model} -O -K >> ${OUTFILE}

        ### Text.
        pstext -J -R -O -K >> ${OUTFILE} << EOF
${TIMEMIN_M} 0.9 8 0 0 LT ${Thickness}
${TIMEMIN_M} 0.7 8 0 0 LT ${Vs}
${TIMEMIN_M} 0.5 8 0 0 LT ${Rho}
EOF
        if [[ "${BestFit}" == *"${Model}"* ]]
        then
            pstext -J -R -O -K -Wred >> ${OUTFILE} << EOF
${TIMEMIN_M} -0.6 8 0 0 LB ${Estimation}
EOF
        elif [[ "${LeastFit}" == *"${Model}"* ]]
        then
            pstext -J -R -O -K -Wblue >> ${OUTFILE} << EOF
${TIMEMIN_M} -0.6 8 0 0 LB ${Estimation}
EOF
        else
            pstext -J -R -O -K >> ${OUTFILE} << EOF
${TIMEMIN_M} -0.6 8 0 0 LB ${Estimation}
EOF
        fi

        ### Shift ploting position.
        if [ $((plot%PLOTX_M)) -ne 0 ]
        then
            psxy -J -R -X${width}i -O -K >> ${OUTFILE} << EOF
EOF
        else
            psxy -J -R -X`echo "(1-${PLOTX_M}) * ${width}" | bc -l `i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF
        fi

        plot=$((plot+1))

    done # done Model loop.

    # Seal the last page.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

    # make tmppsfile for this bin.
    cat `ls *.ps | sort -g` > ${binN}.tmppsfile
    rm *.ps 2>/dev/null

done # End of bin loop.

# Make PDF.
cat `ls *.tmppsfile | sort -g` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/Modeling_1D.pdf

# Clean up.

cd ${CODEDIR}

exit 0
