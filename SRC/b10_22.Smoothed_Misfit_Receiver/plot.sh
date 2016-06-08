#!/bin/bash

set -a
PLOTSRCDIR=${0}
PLOTSRCDIR=${PLOTSRCDIR%/*}

# ===========================================================
# Plot structure histogram result.
#
# Shule Yu
# May 28 2015
# ===========================================================

VERTICNUM=2
HORIZNUM=1
VERTICPER="0.75"
HORIZPER="0.8"
PLOTORIENT="-P"

if [ -z ${PLOTORIENT} ]
then
    YMOVE="8.1"
    PLOTVERTIC="7.5"
    PLOTHORIZ="10"
else
    YMOVE="10.5"
    PLOTVERTIC="10"
    PLOTHORIZ="7.5"
fi

echo ""
echo "--> `basename $0` is running. "
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

hskip=`echo "${PLOTVERTIC}/($((VERTICNUM-1))+${VERTICPER})" | bc -l`
wskip=`echo "${PLOTHORIZ}/($((HORIZNUM-1))+${HORIZPER})" | bc -l`
height=`echo "${hskip}*${VERTICPER}" | bc -l`
width=`echo "${wskip}*${HORIZPER}" | bc -l`

gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 10p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.25p,gray,-

for EQ in ${EQnames}
do

    # Check calculation result.
    if ! [ -e ${WORKDIR_ESFAll}/${EQ}_${ReferencePhase}/INFILE ]
    then
        echo "    !=> Run ESF_All first on ${EQ}..."
        continue
    fi

    echo "    ==> Plotting Smoothed Misfit Distribution of ${EQ}..."

    # Gather information.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select evde from Master_a10 where eq=${EQ} limit 1;
EOF
	read evde < tmpfile_$$

	# Misfit.
	mysql -N -u shule ${DB} > tmpfile_stlo_stla_MisfitS_MisfitScS << EOF
select stlo,stla,Misfit_S_All,Misfit_ScS_All from Master_a10 where eq=${EQ} and wantit=1;
EOF

	# Make grid smoothed Misfit.
	${EXECDIR}/Smoothed_dT.out 0 3 6 << EOF
tmpfile_stlo_stla_MisfitS_MisfitScS
tmpfile_stlo_stla_Smoothed_MisfitS
tmpfile_stlo_stla_Smoothed_MisfitScS
-130
-60
1
20
50
1
EOF

	awk '{if ($3<=0) print $1,$2,-$3}' tmpfile_stlo_stla_Smoothed_MisfitS > tmpfile_stlo_stla_MisfitS_Thin
	awk '{if ($3>0) print $1,$2,$3}' tmpfile_stlo_stla_Smoothed_MisfitS > tmpfile_stlo_stla_MisfitS_Fat

	awk '{if ($3<=0) print $1,$2,-$3}' tmpfile_stlo_stla_Smoothed_MisfitScS > tmpfile_stlo_stla_MisfitScS_Thin
	awk '{if ($3>0) print $1,$2,$3}' tmpfile_stlo_stla_Smoothed_MisfitScS > tmpfile_stlo_stla_MisfitScS_Fat


    # Plot Begin.

	OUTFILE=${EQ}.ps

	title="${EQ}. Event depth: ${evde} km."
	PROJ="-JX${PLOTHORIZ}i/0.3i"
	REG="-R-1/1/-1/1"

	cat > tmpfile_$$ << EOF
0 0 ${title}
EOF

	gmt pstext tmpfile_$$ -F+jCB+f16p ${REG} ${PROJ} -Xf0.65i -Yf${YMOVE}i ${PLOTORIENT} -N -K > ${OUTFILE}

	gmt psxy -J -R -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

	# SubPlots.
	for count2 in `seq 1 $((VERTICNUM*HORIZNUM))`
	do
		if [ -e ${PLOTSRCDIR}/plot_${count2}.sh ]
		then
			${PLOTSRCDIR}/plot_${count2}.sh
		fi

		if [ $((count2%HORIZNUM)) -eq 0 ]
		then
			gmt psxy -J -R -X`echo "-$((HORIZNUM-1))*${wskip}" | bc -l`i -Y-${hskip}i -O -K >> ${OUTFILE} << EOF
EOF
		else
			gmt psxy -J -R -X${wskip}i -O -K >> ${OUTFILE} << EOF
EOF
		fi

	done

	# Seal it.
	rm -f tmpfile*
	gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

done # done EQ loop.


# Gather information.

# Misfit.
mysql -N -u shule ${DB} > tmpfile_stlo_stla_MisfitS_MisfitScS << EOF
select stlo,stla,Misfit_S_All,Misfit_ScS_All from Master_a10 where wantit=1;
EOF

NR=`wc -l < tmpfile_stlo_stla_MisfitS_MisfitScS`

# Make grid smoothed Misfit.
${EXECDIR}/Smoothed_dT.out 0 3 6 << EOF
tmpfile_stlo_stla_MisfitS_MisfitScS
tmpfile_stlo_stla_Smoothed_MisfitS
tmpfile_stlo_stla_Smoothed_MisfitScS
-130
-60
1
20
50
1
EOF

awk '{if ($3<=0) print $1,$2,-$3}' tmpfile_stlo_stla_Smoothed_MisfitS > tmpfile_stlo_stla_MisfitS_Thin
awk '{if ($3>0) print $1,$2,$3}' tmpfile_stlo_stla_Smoothed_MisfitS > tmpfile_stlo_stla_MisfitS_Fat

awk '{if ($3<=0) print $1,$2,-$3}' tmpfile_stlo_stla_Smoothed_MisfitScS > tmpfile_stlo_stla_MisfitScS_Thin
awk '{if ($3>0) print $1,$2,$3}' tmpfile_stlo_stla_Smoothed_MisfitScS > tmpfile_stlo_stla_MisfitScS_Fat


# Plot Begin.

OUTFILE=All.ps

title="All Events. Nrecord: ${NR}"
PROJ="-JX${PLOTHORIZ}i/0.3i"
REG="-R-1/1/-1/1"

cat > tmpfile_$$ << EOF
0 0 ${title}
EOF
gmt pstext tmpfile_$$ -F+jCB+f16p ${REG} ${PROJ} -Xf0.65i -Yf${YMOVE}i ${PLOTORIENT} -N -K > ${OUTFILE}

gmt psxy -J -R -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

# SubPlots.
for count2 in `seq 1 $((VERTICNUM*HORIZNUM))`
do
	if [ -e ${PLOTSRCDIR}/plot_${count2}.sh ]
	then
		${PLOTSRCDIR}/plot_${count2}.sh
	fi

	if [ $((count2%HORIZNUM)) -eq 0 ]
	then
		gmt psxy -J -R -X`echo "-$((HORIZNUM-1))*${wskip}" | bc -l`i -Y-${hskip}i -O -K >> ${OUTFILE} << EOF
EOF
	else
		gmt psxy -J -R -X${wskip}i -O -K >> ${OUTFILE} << EOF
EOF
	fi

done

# Seal it.
rm -f tmpfile*
gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF

# Make PDF.
Title=${0}
Title=${Title%/plot.sh}
Title=${Title##*/}
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title}.pdf

cd ${WORKDIR}

exit 0
