#!/bin/bash

# ================================================================
# Plot FRS distance increment stack from each bins.
#
# Shule Yu
# Jul 03 2015
# ================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -r ${WORKDIR_Plot}/tmpdir_$$ 2>/dev/null; exit 1" SIGINT EXIT

# Plot parameters.

PLOTPERPAGE_ALL=20
height=`echo ${PLOTHEIGHT_ALL} / ${PLOTPERPAGE_ALL} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
onethirdwidth=`echo ${PLOTWIDTH_ALL} / 3 | bc -l`
onesixthwidth=`echo ${onethirdwidth} / 2 | bc -l`

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 9p
gmt gmtset MAP_LABEL_OFFSET 5p
gmt gmtset MAP_FRAME_PEN 0.5p,black

# ================================================
#         ! Check calculation result !
# ================================================

if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    ==> `basename $0`: Run GeoBin first ..."
    exit 1
fi

Time=`grep "<Time>" ${WORKDIR_FRS}/INFILE | awk '{print $2}'`

# ================================================
#         ! Make Plot Data !
# ================================================

mysql -N -u shule ${DB} > tmpfile_eq_stnm_shiftgcarc_weight_ratio_snr << EOF
select eq,stnm,shift_gcarc,weight_final,(Amp_ScS/abs(Rad_Pat_ScS))/(Amp_S/abs(Rad_Pat_S)),SNR_ScS from Master_a21 where wantit=1;
EOF

for binN in `seq ${BeginBin} ${EndBin}`
do
	file=${WORKDIR_Geo}/${binN}.grid
	if ! [ -s ${file} ]
	then
		continue
	fi

    echo "    ==> Plotting FRS GCP increment stack from Bin ${binN}."

    # Get stations in this bin.
    keys="<EQ> <STNM>"
    ${BASHCODEDIR}/Findfield.sh ${file} "${keys}" > tmpfile_eq_stnm

    # Generate the info for this bin.

	rm -f tmpfile_eq_stnm_gcarc_weight_ratio_snr
    while read eq stnm
    do

        if [ "${flag_goodfile}" -eq 1 ]
        then
            grep "${eq}_${stnm}$" ${GoodDecon} >/dev/null 2>&1
            if [ $? -ne 0 ]
            then
				continue
            fi
        fi

        INFO=`grep ${eq} tmpfile_eq_stnm_shiftgcarc_weight_ratio_snr | grep -w ${stnm}`
        echo ${INFO} >> tmpfile_eq_stnm_gcarc_weight_ratio_snr

    done < tmpfile_eq_stnm

    # sort.
    sort -g -k 3,3 tmpfile_eq_stnm_gcarc_weight_ratio_snr | awk -v D=${WORKDIR_FRS} '{print $3" "D"/"$1"_"$2".frs "$4}' > tmpfile_gcarc_filename_weight
    sort -g -k 3,3 tmpfile_eq_stnm_gcarc_weight_ratio_snr | awk '{print $5,$3}' > tmpfile_ratio_gcarc
    sort -g -k 3,3 tmpfile_eq_stnm_gcarc_weight_ratio_snr | awk '{print $6,$3}' > tmpfile_snr_gcarc

    # ===================================
    #        ! C++ code!
    # ===================================
	# Produce ${gcarc}.IncSum file.
	rm -f *IncSum
	rm -f *IncSum_Weighted
	${EXECDIR}/BinInc.out 0 3 4 << EOF
tmpfile_gcarc_filename_weight
.IncSum
.IncSum_Weighted
${D1_FRS}
${D2_FRS}
${DInc}
${Drange}
EOF
    if [ $? -ne 0 ]
    then
        echo "    !=> BinInc C++ code failed ..."
        exit 1;
    fi

    # ===================================
    #        ! Plot !
    # ===================================

	OUTFILE="${binN}.ps"
    NSTA=`wc -l < tmpfile_gcarc_filename_weight`

	PlotHeight="7.5"
	PlotWidth="1.786"
	TraceHeight="1"

    PROJ="-JX${PlotWidth}i/-${PlotHeight}i"
    REG="-R0/${Time}/${D1_FRS}/${D2_FRS}"
	scaley=`echo "${PlotHeight} ${D1_FRS} ${D2_FRS}" | awk '{print $1/($3-$2)}'`

	PROJTrace="-JX${PlotWidth}i/${TraceHeight}i"
	REGTrace="-R0/${Time}/-1/1"

	# Title.
	cat > tmpfile_$$ << EOF
0 104 FRS Inc Sum. Bin: ${binN}. NR=${NSTA}.
EOF
# -Ba10g10/a10f10
	gmt pstext tmpfile_$$ -JX10i/7.5i -R-100/100/-100/100 -F+jCB+f20p,1,black -N -Xf0.7i -Yf0.5i -K > ${OUTFILE}

	# Unweighted Traces.
	rm -f tmpfile_gcarc_NR
	for Tracefile in `ls *.IncSum`
	do
		gcarc=${Tracefile%%_*}
		NR=${Tracefile%.IncSum}
		NR=${NR#*_}
		gmt psxy ${Tracefile} ${PROJTrace} ${REGTrace} -Ya`echo "${scaley} ${D2_FRS} ${gcarc} ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -O -K >> ${OUTFILE}

		# for histogram.
		echo ${gcarc} ${NR} >> tmpfile_gcarc_NR

	done # done unweighted inc loop.

	# annotation and unweighted stack.
	cat > tmpfile_$$ << EOF
1 -1 Unweighted
EOF
	gmt pstext tmpfile_$$ ${PROJTrace} ${REGTrace} -F+jLB+f15p,1,black -N -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -O -K >> ${OUTFILE}
	awk '{print $1,$2}' ${WORKDIR_Geo}/${binN}.frstack_unweighted | gmt psxy ${PROJTrace} ${REGTrace} -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wblack -O -K >> ${OUTFILE}
	awk '{print $1,$2-$3}' ${WORKDIR_Geo}/${binN}.frstack_unweighted | gmt psxy ${PROJTrace} ${REGTrace} -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wred -O -K >> ${OUTFILE}
	awk '{print $1,$2+$3}' ${WORKDIR_Geo}/${binN}.frstack_unweighted | gmt psxy ${PROJTrace} ${REGTrace} -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wred -O -K >> ${OUTFILE}

    # ScS/S amplitude ratio.
	MaxRatio=`minmax -C tmpfile_ratio_gcarc | awk '{print $2}'`
	awk '{{if ($1>1) $1=1} print $1,$2}' tmpfile_ratio_gcarc > tmpfile_$$
    gmt psxy tmpfile_$$ ${PROJ} -R0/1/${D1_FRS}/${D2_FRS} -Xa`echo "${PlotWidth}" | awk '{print $1*1.15}'`i -Sc0.05i -Gdarkblue -W0.5p,black -O -K >> ${OUTFILE}

	# Weighted Traces.
	for Tracefile in `ls *.IncSum_Weighted`
	do
		gcarc=${Tracefile%%_*}
		gmt psxy ${Tracefile} ${PROJTrace} ${REGTrace} -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} ${gcarc} ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -O -K >> ${OUTFILE}
	done # done weighted inc loop.

	# annotation and unweighted stack.
	cat > tmpfile_$$ << EOF
1 -1 SNR Weighted
EOF
	gmt pstext tmpfile_$$ ${PROJTrace} ${REGTrace} -F+jLB+f15p,1,black -N -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -O -K >> ${OUTFILE}
	awk '{print $1,$2}' ${WORKDIR_Geo}/${binN}.frstack | gmt psxy ${PROJTrace} ${REGTrace} -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wblack -O -K >> ${OUTFILE}
	awk '{print $1,$2-$3}' ${WORKDIR_Geo}/${binN}.frstack | gmt psxy ${PROJTrace} ${REGTrace} -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wred -O -K >> ${OUTFILE}
	awk '{print $1,$2+$3}' ${WORKDIR_Geo}/${binN}.frstack | gmt psxy ${PROJTrace} ${REGTrace} -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} 45 ${TraceHeight}" | awk '{print $1*($2-$3)-$4/2}'`i -Wred -O -K >> ${OUTFILE}

    # ScS after Decon snr.
	MaxSNR=`minmax -C tmpfile_snr_gcarc | awk '{print $2}'`
    gmt psxy tmpfile_snr_gcarc ${PROJ} -R0/${MaxSNR}/${D1_FRS}/${D2_FRS} -Xa`echo "${PlotWidth}" | awk '{print $1*3*1.15}'`i -Sc0.05i -Gdarkblue -W0.5p,black -O -N -K >> ${OUTFILE}


	# Histograms (PoorMan's Histogram).
	MaxNR=`minmax -C tmpfile_gcarc_NR | awk '{print $4}'`
	while read gcarc NR
	do
		gmt psxy -JX${PlotWidth}i/`echo "${scaley} ${Drange}" | awk '{print $1*$2}'`i -R0/${MaxNR}/-1/1 -Xa`echo "${PlotWidth}" | awk '{print $1*4*1.15}'`i -Ya`echo "${scaley} ${D2_FRS} ${gcarc} ${Drange}" | awk '{print $1*($2-$3-$4/2)}'`i -Ggray -W0.5p,black -O -K >> ${OUTFILE} << EOF
0 1
${NR} 1
${NR} -1
0 -1
0 1
EOF
	done < tmpfile_gcarc_NR

	# Basemaps.
	gmt psbasemap ${PROJ} ${REG} -Ba5f1:"Time after ScS Peak (sec)":/a5f1:"Gcp Distance (deg)":WSne -O -K >> ${OUTFILE}
	gmt psbasemap ${PROJ} -R0/1/${D1_FRS}/${D2_FRS} -Xa`echo "${PlotWidth}" | awk '{print $1*1.15}'`i -Ba0.1f0.1:"ScS/S":/f1wSne -O -K >> ${OUTFILE}
	gmt psbasemap ${PROJ} ${REG} -Ba5f1:"Time after ScS Peak (sec)":/f1wSne -Xa`echo "${PlotWidth}" | awk '{print $1*2*1.15}'`i -O -K >> ${OUTFILE}
	gmt psbasemap ${PROJ} -R0/${MaxSNR}/${D1_FRS}/${D2_FRS} -Xa`echo "${PlotWidth}" | awk '{print $1*3*1.15}'`i -Ba5f1:"ScS SNR":/f1wSne -O -K >> ${OUTFILE}
	BAXI="-Ba`echo "${MaxNR}" | awk '{if ($1>50) print "40f8"; else if ($1>20) print "15f3"; else print "5f1"}'`:"Freq":/f1WS"
	gmt psbasemap -JX${PlotWidth}i/${PlotHeight}i -R0/${MaxNR}/${D1_FRS}/${D2_FRS} -Xa`echo "${PlotWidth}" | awk '{print $1*4*1.15}'`i ${BAXI} -O -K >> ${OUTFILE}

	# Seal it.
	gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # done bin loop.

# Make PDF.
Title=`basename $0`
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
