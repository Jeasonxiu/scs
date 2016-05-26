#!/bin/bash

# ===========================================================
# Plot BootStrap results.
#
# Shule Yu
# Oct 27 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# ===============================================
#     ! Check the calculation results !
# ===============================================

if ! [ -e ${WORKDIR_Geo}/INFILE ]
then
    echo "    !=> Run GeoBin first ..."
    exit 1
fi

if ! [ -e ${WORKDIR_BootStrap}/INFILE ]
then
    echo "    !=> Run BootStrap first ..."
    exit 1
fi

# Plot parameters.

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.1p,200/200/200,-

BinCenter="-W0.02i,green -S+0.13i"

REG="-R${LOMIN}/${LOMAX}/${LAMIN}/${LAMAX}"
xscale=`echo "${PLOTWIDTH_Map}/(${LOMAX} - ${LOMIN})" | bc -l`
yscale=`echo "${PLOTHEIGHT_Map}/(${LAMAX} - ${LAMIN})" | bc -l`
PROJ="-Jx${xscale}i/${yscale}i"

xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:

# =========================================================
#    ! Plot1: FRS stack v.s BootStrap.
# =========================================================
OUTFILE=1.ps

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

keys="<binLon> <binLat> <binR>"
# Plot FRS stacks.
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}
    file=${WORKDIR_Geo}/${BinN}.grid
    FRSfile=${WORKDIR_Geo}/${BinN}.frstack
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    # Amplitude line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
    # Amplitude tick.
    psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
EOF

    # Time zero line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

    # Time tick.
    for time in `seq -5 5`
    do
        psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
    done

    # CMB position.
    psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF

    # BootStrap result.
    awk '{print $1,$2}' ${file1} | psxy ${REG1} ${PROJ1} -W0.5p,black -O -K >> ${OUTFILE}

    # FRS stack.
    awk '{print $1,$2}' ${FRSfile} | psxy ${REG1} ${PROJ1} -W0.5p,red -O -K >> ${OUTFILE}

    # Go back to original.
    psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# =========================================================
#    ! Plot2: BootStrap result with STD.
# =========================================================

OUTFILE=2.ps

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

keys="<binLon> <binLat> <binR>"
# Plot FRS stacks.
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    # Amplitude line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
    # Amplitude tick.
    psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
EOF

    # Time zero line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

    # Time tick.
    for time in `seq -5 5`
    do
        psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
    done

    # CMB position.
    psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF

    # FRS BootStrap stack.
    awk '{print $1,$2}' ${file1} | psxy ${REG1} ${PROJ1} -O -K >> ${OUTFILE}

    # FRS BootStrap std.
    awk '{print $1,$2-$3}' ${file1} | psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}
    awk '{print $1,$2+$3}' ${file1} | psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}

    # Bin info.
    pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${Time}*0.1" | bc -l` -1 5 0 0 LB #${BinN}: ${NR}
EOF

    # Go back to original.
    psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# =========================================================
#    ! Plot3: FRS BootStrap with Upper / Lower Bound !
# =========================================================
OUTFILE=3.ps

REG1="-R0/${Time}/-1/1"
xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
PROJ1="-Jx${xscale1}i/${yscale1}i"

psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}
pscoast ${REG} -Jx${xscale}id/${yscale}id -Dl -A40000 -W0.3p,black -O -K >> ${OUTFILE}

# Plot FRS stacks.
for file1 in `ls ${WORKDIR_BootStrap}/*bootstrap`
do
    BinN=${file1%.bootstrap}
    BinN=${BinN##*/}

    file=${WORKDIR_Geo}/${BinN}.grid
    NR=`wc -l < ${file} | awk '{print $1-1}'`
    INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
    lon=`echo ${INFO} | awk '{print $1}'`
    lat=`echo ${INFO} | awk '{print $2}'`

    # Go to right position.
    psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF

    # Amplitude line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 -1
0 1
EOF
    # Amplitude tick.
    psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
0 -0.5
0 0.5
EOF

    # Time zero line.
    psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF

    # Time tick.
    for time in `seq -5 5`
    do
        psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
    done

    # CMB position.
    psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF

    # FRS stack.
    awk '{print $1,$2}' ${file1} | psxy ${REG1} ${PROJ1} -Wpurple -O -K >> ${OUTFILE}

    # FRS stack Upper & Lower Bound.
    awk '{print $1,$4}' ${file1} | psxy ${REG1} ${PROJ1} -Wblue -O -K >> ${OUTFILE}
    awk '{print $1,$5}' ${file1} | psxy ${REG1} ${PROJ1} -Wred -O -K >> ${OUTFILE}

    # Bin info.
    pstext -R -J -N -O -K >> ${OUTFILE} << EOF
`echo "${Time}*0.1" | bc -l` -1 5 0 0 LB #${BinN}: ${NR}
EOF

    # Go back to original.
    psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

done

psxy -R -J -O >> ${OUTFILE} << EOF
EOF

# ====================================
#     ! Plot4: Lower bound > 0 !
# ====================================
ls ${WORKDIR_BootStrap}/*bootSig_low >/dev/null 2>&1

if [ $? -eq 0 ]
then

    OUTFILE=4.ps

    REG1="-R0/${Time}/-1/1"
    xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
    yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
    PROJ1="-Jx${xscale1}i/${yscale1}i"

    psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
    grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}

    # Plot FRS stacks.
    for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
    do
        BinN=${file%.*}
        BinN=${BinN##*/}

        NR=`wc -l < ${file} | awk '{print $1-1}'`
        INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
        lon=`echo ${INFO} | awk '{print $1}'`
        lat=`echo ${INFO} | awk '{print $2}'`

        if [ -e ${WORKDIR_BootStrap}/${BinN}.bootSig_low ]
        then
            file1=${WORKDIR_BootStrap}/${BinN}.bootSig_low
        else
            continue
        fi

        # Go to right position.
        psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF
        # Amplitude line.
#         psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
# 0 -1
# 0 1
# EOF
        # Amplitude tick.
#         psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
# 0 -0.5
# 0 0.5
# EOF
        # Time zero line.
        psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
        # Time tick.
        for time in `seq -5 5`
        do
            psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
        done

        # Upper Bound < 0
        tac ${file1} | awk '{print $1,0}' > tmpfile_$$
        awk '{print $1,2*$2}' ${file1} >> tmpfile_$$
        psxy tmpfile_$$ ${REG1} ${PROJ1} -Gred -L -O -K >> ${OUTFILE}

        # CMB position.
        psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF
        # Go back to origin.
        psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

    done

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

fi # if there is an lower bound greater than 0.

# ====================================
#     ! Plot5: Upper bound < 0 !
# ====================================
ls ${WORKDIR_BootStrap}/*bootSig_high >/dev/null 2>&1

if [ $? -eq 0 ]
then

    OUTFILE=5.ps

    REG1="-R0/${Time}/-1/1"
    xscale1=`echo "${xscale}*${LOINC}*0.8/${Time}" | bc -l`
    yscale1=`echo "${yscale}*${LAINC}*0.8/2" | bc -l`
    PROJ1="-Jx${xscale1}i/${yscale1}i"

    psbasemap ${REG} ${PROJ} -Ba${LOINC}f0.5g1:"Longitude":/a${LAINC}f0.5g1:"Latitude":WS -K > ${OUTFILE}
    grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -O -K >> ${OUTFILE}

    # Plot FRS stacks.
    for file in `ls ${WORKDIR_Geo}/*.grid | sort -n`
    do
        BinN=${file%.*}
        BinN=${BinN##*/}

        NR=`wc -l < ${file} | awk '{print $1-1}'`
        INFO=`${BASHCODEDIR}/Findfield.sh ${file} "${keys}" | head -n 1`
        lon=`echo ${INFO} | awk '{print $1}'`
        lat=`echo ${INFO} | awk '{print $2}'`

        if [ -e ${WORKDIR_BootStrap}/${BinN}.bootSig_high ]
        then
            file1=${WORKDIR_BootStrap}/${BinN}.bootSig_high
        else
            continue
        fi

        # Go to right position.
        psxy -R -J -X`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i -O -K >> ${OUTFILE} << EOF
EOF
#         # Amplitude line.
#         psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
# 0 -1
# 0 1
# EOF
#         # Amplitude tick.
#         psxy -J -R -S-0.02i -Wblack -O -K >> ${OUTFILE} << EOF
# 0 -0.5
# 0 0.5
# EOF
        # Time zero line.
        psxy ${REG1} ${PROJ1} -Wblack,. -O -K >> ${OUTFILE} << EOF
0 0
${Time} 0
EOF
        # Time tick.
        for time in `seq -5 5`
        do
            psxy -J -R -Sy0.02i -Wblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${TickMap}" | bc -l` 0
EOF
        done

        # Upper Bound < 0
        tac ${file1} | awk '{print $1,0}' > tmpfile_$$
        awk '{print $1,2*$2}' ${file1} >> tmpfile_$$
        psxy tmpfile_$$ ${REG1} ${PROJ1} -Gblue -L -O -K >> ${OUTFILE}

        # CMB position.
        psxy ${REG1} ${PROJ1} ${BinCenter} -N -O -K >> ${OUTFILE} << EOF
0 -1
EOF
        # Go back to origin.
        psxy -R -J -O -K -X-`echo "${lon} ${LOMIN} ${xscale}" | awk '{print ($1-$2)*$3}'`i -Y-`echo "${lat} ${LAMIN} ${yscale}"  | awk '{print ($1-$2)*$3}'`i >> ${OUTFILE} << EOF
EOF

    done

    psxy -R -J -O >> ${OUTFILE} << EOF
EOF

fi # if there is an upper bound smaller than 0.

# ====================================
#     ! Make PDF !
# ====================================
Title=`basename $0`
cat `ls -rt *.ps` > tmpfile.ps
ps2pdf tmpfile.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
