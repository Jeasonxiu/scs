#!/bin/bash

# ===========================================================
# Randomly resample each bin. Num of traces is decided by
# other bins. Number of test is decide by ${RandTestNum}
#
# Shule Yu
# Jul 14 2016
# ===========================================================


echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

if [ ${RandTestNum} -le 0 ] || [ ${RandTestNum} -gt 100 ]
then
	echo "	!=> RandTestNum is not proper !"
	exit 1
fi

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 10p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.25p,gray,-
gmt gmtset MAP_GRID_PEN_PRIMARY 0.25p,gray,-

# Set some Parameters.
NBin=`ls ${WORKDIR_Geo}/*.grid | wc -l`
Perwidth="1.58"
width="1.42"
Perheight="0.85"
height="0.765"
HorizNum="6"
height1=`echo "${Perheight}" | awk '{print $1*8}'`
width1=`echo "${Perwidth} ${HorizNum}" | awk '{print $1*$2}'`

# Get how many traces are there for each bin.
rm -f tmpfile_NR
for bin in `seq 1 ${NBin}`
do
	file=`ls ${WORKDIR_Geo}/${bin}.grid`
	echo ${bin} `wc -l < ${file} | awk '{print $1-1}'` >> tmpfile_NR
done

# For each bin, count and decide how many traces to resample.
${EXECDIR}/CountResample.out 0 2 0 << EOF
tmpfile_NR
tmpfile_Num_Bins_
EOF


for bin in `seq 1 ${NBin}`
do

	# Gathering Information.
	BinFile=`ls ${WORKDIR_Geo}/${bin}.grid`
	Keys="<EQ> <STNM> <Weight_Smooth>"
	${BASHCODEDIR}/Findfield.sh ${BinFile} "${Keys}" | awk -v D=${WORKDIR_FRS} '{print D"/"$1"_"$2".frs",$3}'> tmpfile_filename_weight
	firstfile=`head -n 1 tmpfile_filename_weight | awk '{print $1}'`
	NTrace=`wc -l < ${BinFile} | awk '{print $1-1}'`

	# Resample and stack.
	while read ResampleNum Bins
	do
		${EXECDIR}/ResampleBins.out 3 2 1 << EOF
`wc -l < ${firstfile}`
${ResampleNum}
${RandTestNum}
tmpfile_filename_weight
tmpfile_Bin${bin}_Stack${ResampleNum}_
${DELTA}
EOF
	done < tmpfile_Num_Bins_${bin}

    # Plot.
	rm -f *.ps
	while read ResampleNum Bins
	do
		OUTFILE=${ResampleNum}.ps
		Bins=`echo ${Bins} | sed 's/\ /,\ /g'`

		# Title.
		title="Subsampled (without replacement) FRS stack from Bin ${bin}, TraceNum=${ResampleNum}/${NTrace}, according to Bin(s):"
		cat > tmpfile_$$ << EOF
0 0.5 ${title}
0 -0.9 ${Bins}.
EOF
		gmt pstext tmpfile_$$ -F+jCB+f16p -JX11i/0.3i -R-1/1/-1/1 -Xf0i -Yf7.8i -N -K > ${OUTFILE}

		REG="-R0/15/-1/1"
		PROJ="-JX${width}i/${height}i"
		PROJ1="-JX${width1}i/${height1}i"

		gmt psbasemap -R0/100/0/800 ${PROJ1} -B/g100wsne -Xf0.75i -Yf0.75i -O -K >> ${OUTFILE}
		gmt psbasemap ${REG} ${PROJ} -Ba5:"sec.":/a0.5:"Amp":WS -Xf0.75i -Yf0.75i -O -K >> ${OUTFILE}

		for Count in `seq 0 $((RandTestNum-1))`
		do
			MOVEX=$((Count%HorizNum))
			MOVEY=$((Count/HorizNum))
			MOVEX=`echo ${MOVEX} ${Perwidth} | awk '{print $1*$2+0.75}'`
			MOVEY=`echo ${MOVEY} ${Perheight} | awk '{print $1*$2+0.75}'`

			awk '{print $1,$2}' tmpfile_Bin${bin}_Stack${ResampleNum}_$((Count+1)) | gmt psxy -R -J -O -K -Xf${MOVEX}i -Yf${MOVEY}i >> ${OUTFILE}
		done

		# Seal it.
		gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

	done < tmpfile_Num_Bins_${bin}


	Title=`basename $0`
	Title=${Title%.sh}
	mkdir -p ${WORKDIR_Plot}/${Title}
	cat `ls -rt *.ps` > tmp.ps
	ps2pdf tmp.ps ${WORKDIR_Plot}/${Title}/Bin${bin}.pdf
	rm -f tmpfile_Bin*

done # done bin loop.

cd ${WORKDIR}

exit 0
