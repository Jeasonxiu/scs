#!/bin/bash

set -a

# =========================================================================
# Plot S Profile from final selection, calling dude.
#
# Shule Yu
# Mar 17 2015
# =====================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$/PLOTS
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200

for EQ in ${EQnames}
do

	echo "    ==> Plotting ${EQ} ${ReferencePhase} profile..."

    F1=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`

    # EQ info.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select evde,evlo,evla,mag from Master_a06 where eq=${EQ} limit 1;
EOF
	read EVDE EVLO EVLA EVMA < tmpfile_$$
    YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`


	# Prepare data.
	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select file from Master_a06 where eq=${EQ} and wantit=1;
EOF
    mkdir ${EQ}
    cp `cat tmpfile_$$` ${EQ}


    # Plot Begin.
    INPUT="${EQ} ${SRCDIR} `pwd` ${WORKDIR_Plot}/tmpdir_$$/PLOTS"
    MGMT="-m"
    SACLIBs="${SACDIR}/lib/libsac.a ${SACDIR}/lib/libsacio.a"
    PATH="${PATH}:."

    cd ${EQ}

	# Make eventStation file required by DUDE.
	echo "" > eventStation.${EQ}
	mysql -N -u shule ${DB} >> eventStation.${EQ} << EOF
select stnm,netwk,gcarc,"deg",az,"deg",baz,"deg",stla,stlo,evla,evlo,evde,"km Mw",mag,"Multiple Centers",eq from Master_a06 where eq=${EQ} and wantit=1;
EOF

    csh ${SRCDIR}/c08.profile_zoom  ${INPUT} ${DISTMIN} ${DISTMAX} -100 200 ${ReferencePhase} T

    cd ..

done # done EQ loop.

# Make PDFs.
Title=`basename $0`
rm -f tmp1.ps tmp2.ps
for EQ in ${EQnames}
do
    cat ${WORKDIR_Plot}/tmpdir_$$/PLOTS/${EQ}*c08*T.ps >> tmp1.ps
    cat ${WORKDIR_Plot}/tmpdir_$$/PLOTS/${EQ}*c08*Tlp.ps >> tmp2.ps
done

ps2pdf tmp1.ps ${WORKDIR_Plot}/${Title%.sh}_${ReferencePhase}.pdf
ps2pdf tmp2.ps ${WORKDIR_Plot}/${Title%.sh}_${ReferencePhase}_LowPass.pdf

cd ${WORKDIR}

exit 0
