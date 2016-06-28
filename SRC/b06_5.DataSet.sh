#!/bin/bash

# ===========================================================
# Plot Earthquake-Station Distribution with ScS bounce points.
#
# Shule Yu
# Nov 10 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

# Plot each EQ.
rm -f tmpfile*
plot=1
for EQ in ${EQnames}
do

    echo "        Calculating lowermost ${Depth_Data} km of ${EQ} ScS raypath ..."

	echo "select count(*) from Master_a06 where eq=${EQ} and wantit=1;" > tmpfile_$$
	NSTA=`mysql -N -u shule ${DB} < tmpfile_$$`
    if [ "${NSTA}" -eq 0 ]
    then
        continue
    fi


    # EQ info.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select evlo,evla,evde from Master_a06 where eq=${EQ} limit 1;
EOF
	read EVLO EVLA EVDE < tmpfile_$$


    # CMT info.
    CMT=`grep ${EQ} ${CMTINFO} | awk 'NR==1 {print $0}'`
    if ! [ -z "${CMT}" ]
    then
        STRIKE=`echo "${CMT}" | awk '{print $3}'`
        DIP=`echo "${CMT}" | awk '{print $4}'`
        RAKE=`echo "${CMT}" | awk '{print $5}'`
        STRIKE1=`echo "${CMT}" | awk '{print $6}'`
        DIP1=`echo "${CMT}" | awk '{print $7}'`
        RAKE1=`echo "${CMT}" | awk '{print $8}'`
        HaveCMT=1
    else
        HaveCMT=0
    fi

    # Station positions.
	mysql -N -u shule ${DB} > tmpfile_Stations_${EQ} << EOF
select stlo,stla from Master_a06 where eq=${EQ} and wantit=1;
EOF


    # Station Hitposition.
	mysql -N -u shule ${DB} > tmpfile_bounce_${EQ} << EOF
select hitlo,hitla from Master_a06 where eq=${EQ} and wantit=1;
EOF


    # Station rayp.
	mysql -N -u shule ${DB} > tmpfile_Cin << EOF
select stlo,stla,evlo,evla,evde from Master_a06 where eq=${EQ} and wantit=1;
EOF


    # Ray path below ${Depth_Data}
    ${EXECDIR}/dataset.out 0 2 1 << EOF
tmpfile_Cin
tmpfile_paths_${EQ}
${Depth_Data}
EOF
    if [ $? -ne 0 ]
    then
        echo "    !=> dataset.out C code failed on ${EQ}..."
        exit 1
    fi


    # ===================================
    #        ! Plot Begin !
    # ===================================

    OUTFILE=${plot}.ps
    echo "    ==> ${EQ} Total event-staion pair number: ${NSTA}..."

    title="Data Distribution. ${EQ}. Event-Station Pair: ${NSTA}"
    pstext -R-1/1/-1/1 -JX7i/1i -Y10i -N -P -K > ${OUTFILE} << EOF
0 0 14 0 0 CB ${title}
EOF

    PROJ="-JG${CLON_Data}/${CLAT_Data}/${PROJ_Data}i"
    REG="-R-180/180/-90/90"

    REG1="-R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX}"
    xscale=`echo "3.5/(${RLOMAX} - ${RLOMIN})" | bc -l`
    yscale=`echo "3.5/(${RLAMAX} - ${RLAMIN})" | bc -l`
    PROJ1="-Jx${xscale}i/${yscale}i"
    PROJ2="-Jx${xscale}id/${yscale}id"

    # 1. Tomography S20.
    xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:
    grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -Y-3.5i -X-0.5i -O -K >> ${OUTFILE} 2>/dev/null
    psscale -C${BASHCODEDIR}/ritsema.cpt -D2i/-0.2i/3.0i/0.13ih -B2/:"@~\144@~Vs (%)": -N300 -O -K >> ${OUTFILE}
    pscoast ${REG} ${PROJ} -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
    psbasemap ${REG} ${PROJ} -Bg60/g45 -O -K >> ${OUTFILE}
    psxy ${REG} ${PROJ} -Wthick,purple -O -K -Ap >> ${OUTFILE} << EOF
${RLOMIN} ${RLAMAX}
${RLOMAX} ${RLAMAX}
${RLOMAX} ${RLAMIN}
${RLOMIN} ${RLAMIN}
${RLOMIN} ${RLAMAX}
EOF

    # 2. Distribution.
    pscoast ${REG} ${PROJ} -Gdarkgreen -Slightblue -Dl -A40000 -W2,gray,faint -X4i -O -K >> ${OUTFILE}
    psxy tmpfile_bounce_${EQ} ${PROJ} ${REG} -Sc0.01i -Gyellow -O -K >> ${OUTFILE}

    if [ ${HaveCMT} -eq 1 ]
    then
		psmeca -R -J -Sc0.4 -H1 -N -O -K >> ${OUTFILE} << EOF
lon lat depth str dip slip st dip slip mant exp plon plat
${EVLO} ${EVLA} ${EVDE} ${STRIKE} ${DIP} ${RAKE} ${STRIKE1} ${DIP1} ${RAKE1} 5.5 1 0 0
EOF
    fi

    psxy ${PROJ} ${REG} -Sa0.1i -Gred -O -K >> ${OUTFILE} << EOF
${EVLO} ${EVLA}
EOF

    psxy tmpfile_Stations_${EQ} ${PROJ} ${REG} -Si0.03i -Gblue -O -K >> ${OUTFILE}
    psbasemap ${REG} ${PROJ} -Ba60f90/a45f45 -O -K >> ${OUTFILE}


    # 3. Path.
    psbasemap ${REG1} ${PROJ1} -Ba20g20f5/a20g20f5WS -X-4i -Y-5i -O -K >> ${OUTFILE}
    pscoast ${REG1} ${PROJ2} -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
    psxy tmpfile_paths_${EQ} ${PROJ1} ${REG1} -Wblack -m -O -K >> ${OUTFILE}


    # 4. Color scale & ScS hit count (2x2 deg).
    rm -f tmpfile_bounce_grid
    lat=${RLAMIN}
    while [ `echo "${lat}<${RLAMAX}" | bc` -eq 1 ]
    do
        lon=${RLOMIN}
        while [ `echo "${lon}<${RLOMAX}" | bc` -eq 1 ]
        do
            count=`awk -v LA=${lat} -v LO=${lon} '{ if ( LO-1 < $1 && $1< LO+1 && LA-1 < $2 && $2 < LA+1 ) print $0}' tmpfile_bounce_${EQ} | wc -l`
            echo "${lon} ${lat} ${count}" >> tmpfile_bounce_grid

            lon=`echo "${lon}+2" | bc -l`
        done
        lat=`echo "${lat}+2" | bc -l`
    done
    MINVAL=`minmax -C tmpfile_bounce_grid | awk '{print $5}'`
    MAXVAL=`minmax -C tmpfile_bounce_grid | awk '{print $6}'`
    makecpt -I -Chot -T${MINVAL}/${MAXVAL}/`echo "(${MAXVAL}-${MINVAL})/10" | bc -l` -Z > tmpfile.cpt
    xyz2grd tmpfile_bounce_grid -G2880.grd -I2 ${REG1} -N0
    grdimage 2880.grd -Ctmpfile.cpt ${REG1} ${PROJ1} -X4i -E40 -O -K >> ${OUTFILE} 2>/dev/null
    pscoast ${REG1} ${PROJ2}  -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
    psbasemap ${REG1} ${PROJ1} -Ba20g20f5/a20g20f5WS -O -K >> ${OUTFILE}
    psscale -Ctmpfile.cpt -D1.8i/-0.3i/3.0i/0.13ih -B`echo "(${MAXVAL}-${MINVAL})/10" | bc`/:"Hit Count": -N300 -O -K >> ${OUTFILE}

    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

    plot=$((plot+1))


    # Merge ray paths info for the final plot.
    cat tmpfile_paths_${EQ} >> tmpfile_paths

done # done EQ loop.

# ===================================
#        ! Plot All !
# ===================================

mysql -N -u shule ${DB} > tmpfile_EQs << EOF
select distinct evlo,evla from Master_a06 where wantit=1;
EOF

mysql -N -u shule ${DB} > tmpfile_Stations << EOF
select distinct stlo,stla from Master_a06 where wantit=1;
EOF

mysql -N -u shule ${DB} > tmpfile_bounce << EOF
select distinct hitlo,hitla from Master_a06 where wantit=1;
EOF

echo "select count(*) from Master_a06 where wantit=1;" > tmpfile_$$
NSTA=`mysql -N -u shule ${DB} < tmpfile_$$`

OUTFILE=DataSet.ps
echo "    ==> Total traces: ${NSTA}."

title="Data Distribution. Event-Station Pair: ${NSTA}"
pstext -R-1/1/-1/1 -JX7i/1i -Y10i -N -P -K > ${OUTFILE} << EOF
0 0 14 0 0 CB ${title}
EOF

PROJ="-JG${CLON_Data}/${CLAT_Data}/${PROJ_Data}i"
REG="-R-180/180/-90/90"

REG1="-R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX}"
xscale=`echo "3.5/(${RLOMAX} - ${RLOMIN})" | bc -l`
yscale=`echo "3.5/(${RLAMAX} - ${RLAMIN})" | bc -l`
PROJ1="-Jx${xscale}i/${yscale}i"
PROJ2="-Jx${xscale}id/${yscale}id"

# 1. Tomography S20.
xyz2grd ${BASHCODEDIR}/ritsema.2880 -G2880.grd -I2 ${REG} -:
grdimage 2880.grd -C${BASHCODEDIR}/ritsema.cpt ${REG} ${PROJ} -E40 -Y-3.5i -X-0.5i -O -K >> ${OUTFILE} 2>/dev/null
psscale -C${BASHCODEDIR}/ritsema.cpt -D2i/-0.2i/3.0i/0.13ih -B2/:"@~\144@~Vs (%)": -N300 -O -K >> ${OUTFILE}
pscoast ${REG} ${PROJ} -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
psbasemap ${REG} ${PROJ} -Bg60/g45 -O -K >> ${OUTFILE}
psxy ${REG} ${PROJ} -Wthick,purple -O -K -Ap >> ${OUTFILE} << EOF
${RLOMIN} ${RLAMAX}
${RLOMAX} ${RLAMAX}
${RLOMAX} ${RLAMIN}
${RLOMIN} ${RLAMIN}
${RLOMIN} ${RLAMAX}
EOF

# 2. Distribution.
pscoast ${REG} ${PROJ} -Gdarkgreen -Slightblue -Dl -A40000 -W2,gray,faint -X4i -O -K >> ${OUTFILE}
psxy tmpfile_bounce ${PROJ} ${REG} -Sc0.01i -Gyellow -O -K >> ${OUTFILE}
psxy tmpfile_EQs ${PROJ} ${REG} -Sa0.1i -Gred -O -K >> ${OUTFILE}
psxy tmpfile_Stations ${PROJ} ${REG} -Si0.03i -Gblue -O -K >> ${OUTFILE}
psbasemap ${REG} ${PROJ} -Ba60f90/a45f45 -O -K >> ${OUTFILE}

# 3. Path.
psbasemap ${REG1} ${PROJ1} -Ba20g20f5/a20g20f5WS -X-4i -Y-5i -O -K >> ${OUTFILE}
pscoast ${REG1} ${PROJ2} -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
psxy tmpfile_paths ${PROJ1} ${REG1} -Wblack -m -O -K >> ${OUTFILE}

# 4. Color scale, hit count.
rm -f tmpfile_bounce_grid
lat=${RLAMIN}
while [ `echo "${lat}<${RLAMAX}" | bc` -eq 1 ]
do
    lon=${RLOMIN}
    while [ `echo "${lon}<${RLOMAX}" | bc` -eq 1 ]
    do
        count=`awk -v LA=${lat} -v LO=${lon} '{ if ( LO-1 < $1 && $1< LO+1 && LA-1 < $2 && $2 < LA+1 ) print $0}' tmpfile_bounce | wc -l`
        echo "${lon} ${lat} ${count}" >> tmpfile_bounce_grid

        lon=`echo "${lon}+2" | bc -l`
    done
    lat=`echo "${lat}+2" | bc -l`
done
MINVAL=`minmax -C tmpfile_bounce_grid | awk '{print $5}'`
MAXVAL=`minmax -C tmpfile_bounce_grid | awk '{print $6}'`
makecpt -I -Chot -T${MINVAL}/${MAXVAL}/`echo "(${MAXVAL}-${MINVAL})/10" | bc -l` -Z > tmpfile.cpt
xyz2grd tmpfile_bounce_grid -G2880.grd -I2 ${REG1} -N0
grdimage 2880.grd -Ctmpfile.cpt ${REG1} ${PROJ1} -X4i -E40 -O -K >> ${OUTFILE} 2>/dev/null
pscoast ${REG1} ${PROJ2}  -Dl -A40000 -W3,gray,faint -O -K >> ${OUTFILE}
psbasemap ${REG1} ${PROJ1} -Ba20g20f5/a20g20f5WS -O -K >> ${OUTFILE}
psscale -Ctmpfile.cpt -D1.8i/-0.3i/3.0i/0.13ih -B`echo "(${MAXVAL}-${MINVAL})/10" | bc`/:"Hit Count": -N300 -O -K >> ${OUTFILE}

# Make PDF.
psxy -J -R -O >> ${OUTFILE} << EOF
EOF

Title=`basename $0`
cat `ls -rt *ps` > ${WORKDIR_Plot}/${Title%.sh}.ps
ps2pdf ${WORKDIR_Plot}/${Title%.sh}.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${WORKDIR}

exit 0
