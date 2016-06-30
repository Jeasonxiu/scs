#!/bin/bash

# =================================================================
# Just Plot S and ScS Profile for/from selection.
# (If there is a human selection list, put good traces on the top,
# bad traces on the bottom. information is collected from table ScS.a06)
#
# Outputs:
#
#           ${WORKDIR_HandPick}/${EQ}_S_HandPick.pdf
#           ${WORKDIR_HandPick}/${EQ}_ScS_HandPick.pdf
#
# Shule Yu
# Oct 19 2014
# =================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
mkdir -p ${WORKDIR_HandPick}
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$ ${WORKDIR}/*_${RunNumber}; exit 1" EXIT SIGINT

# Plot parameters.

height=`echo ${PLOTHEIGHT_Select} / ${PLOTPERPAGE_Select} | bc -l`
halfh=` echo ${height} / 2 | bc -l`
quarth=`echo ${height} / 4 | bc -l`
xscale=`echo "${height}/(${RLOMAX} - ${RLOMIN})" | bc -l`
yscale=`echo "${height}/(${RLAMAX} - ${RLAMIN})" | bc -l`

gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 9p
gmtset LABEL_OFFSET = 0.1c

cat > tmpfile_ticks.lst << EOF
0    P,Pdiff    yellow
1    pP         cyan
2    S,Sdiff    green
3    sS         blue
4    PP         gold
5    SS         darkblue
6    SKKS       pink
7    PKP        purple
8    SKS        orange
9    ScS        red
EOF

# Work Begins.

# Check do we have previous selection result?
mysql -u shule ${DB} > /dev/null 2>&1 << EOF
select * from a06 limit 1
EOF
if [ $? -ne 0 ]
then
	Fresh=1
else
	Fresh=0
fi

for EQ in ${EQnames}
do

	# Check number of valid traces.
	cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_a04 where eq=${EQ} and wantit=1;
EOF
	NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
	rm -f tmpfile_CheckValid_$$
	if [ ${NR} -eq 0 ]
	then
		continue
	fi


	echo "    ==> Gathering ${EQ} Information (`date +%H:%M:%S`) ..."
    # EQ specialized parameters.

    F1=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $2}'`
    F2=`grep ${EQ} ${WORKDIR}/EQ_Freq_${RunNumber} | awk '{print $3}'`

	! [ -z ${F1} ] || F1="0.033"
	! [ -z ${F2} ] || F2="0.3"


	# Information collection.
	mysql -N -u shule ${DB} > tmpfile_Cin_S_$$ << EOF
select file,stnm,S from Master_a04 where eq=${EQ} and WantIt=1 order by netwk,gcarc;
EOF
	mysql -N -u shule ${DB} > tmpfile_Cin_ScS_$$ << EOF
select file,stnm,ScS from Master_a04 where eq=${EQ} and WantIt=1 order by netwk,gcarc;
EOF
	mysql -N -u shule ${DB} > tmpfile_pairname_$$ << EOF
select pairname from Master_a04 where eq=${EQ} and WantIt=1 order by netwk,gcarc;
EOF

	echo "select evlo,evla,evde,mag from Master_a04 where eq=${EQ} limit 1" > tmpfile_$$
	INFO=`mysql -N -u shule ${DB} < tmpfile_$$`
    EVLO=`echo "${INFO}" | awk '{printf "%.2lf",$1}'`
    EVLA=`echo "${INFO}" | awk '{printf "%.2lf",$2}'`
    EVDE=`echo "${INFO}" | awk '{printf "%.1lf",$3}'`
    EVMA=`echo "${INFO}" | awk '{printf "%.1lf",$4}'`
	YYYY=`echo ${EQ} | cut -b 1-4`
    MM=`echo ${EQ}   | cut -b 5-6`
    DD=`echo ${EQ}   | cut -b 7-8`


    # Put human-picked bad traces at the bottom of the station list.

	if [ ${Fresh} -eq 0 ]
	then

		mysql -u shule ${DB} > /dev/null 2>&1 << EOF
alter table a06 drop primary key, add primary key (PairName);
EOF

		rm -f tmpfile_bads_$$ tmpfile_badscs_$$
		rm -f tmpfile_goods_$$ tmpfile_goodscs_$$
		while read pairname
		do
			mysql -u shule ${DB} > /dev/null 2>&1 << EOF
insert ignore into a06 (PairName) values ("${pairname}");
EOF

			echo "select count(*) from a06 where keeps=0 and pairname=\"${pairname}\"" > tmpfile_$$
			if [ `mysql -N -u shule ${DB} < tmpfile_$$` -eq 0 ]
			then
				mysql -N -u shule ${DB} >> tmpfile_goods_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,1,P-S,xpP-S,S-S,xsS-S,PP-S,SS-S,SKKS-S,PKP-S,SKS-S,ScS-S from Master_a04 where pairname="${pairname}";
EOF
			else
				mysql -N -u shule ${DB} >> tmpfile_bads_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,0,P-S,xpP-S,S-S,xsS-S,PP-S,SS-S,SKKS-S,PKP-S,SKS-S,ScS-S from Master_a04 where pairname="${pairname}";
EOF
			fi

			echo "select count(*) from a06 where keepscs=0 and pairname=\"${pairname}\"" > tmpfile_$$
			if [ `mysql -N -u shule ${DB} < tmpfile_$$` -eq 0 ]
			then
				mysql -N -u shule ${DB} >> tmpfile_goodscs_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,1,P-ScS,xpP-ScS,S-ScS,xsS-ScS,PP-ScS,SS-ScS,SKKS-ScS,PKP-ScS,SKS-ScS,ScS-ScS from Master_a04 where pairname="${pairname}";
EOF
			else
				mysql -N -u shule ${DB} >> tmpfile_badscs_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,0,P-ScS,xpP-ScS,S-ScS,xsS-ScS,PP-ScS,SS-ScS,SKKS-ScS,PKP-ScS,SKS-ScS,ScS-ScS from Master_a04 where pairname="${pairname}";
EOF
			fi

		done < tmpfile_pairname_$$

		cat tmpfile_goods_$$ tmpfile_bads_$$ > tmpfile_s_$$
		cat tmpfile_goodscs_$$ tmpfile_badscs_$$ > tmpfile_scs_$$

	else

		mysql -N -u shule ${DB} >> tmpfile_s_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,1,P-S,xpP-S,S-S,xsS-S,PP-S,SS-S,SKKS-S,PKP-S,SKS-S,ScS-S from Master_a04 where pairname="${pairname}";
EOF

		mysql -N -u shule ${DB} >> tmpfile_scs_$$ << EOF
select stnm,gcarc,KCMPNM,stlo,stla,netwk,az,baz,hitlo,hitla,1,P-ScS,xpP-ScS,S-ScS,xsS-ScS,PP-ScS,SS-ScS,SKKS-ScS,PKP-ScS,SKS-ScS,ScS-ScS from Master_a04 where pairname="${pairname}";
EOF

	fi


    # ==================================
    #         ! Make S Plot data !
    # ==================================

	echo "        ==> Processing ${EQ} ${ReferencePhase} (`date +%H:%M:%S`) ..."

	${EXECDIR}/SAC2Signal.out 0 2 6 << EOF
tmpfile_Cin_S_$$
${WORKDIR_Plot}/tmpdir_$$/
-190
380
${DELTA}
${F1}
${F2}
0.05
EOF

	if [ $? -ne 0 ]
	then
		echo "    !=> SAC2Signal.out failed ..."
		exit 1
	fi


    # ===================================
    #        ! Plot S !
    # ===================================

	echo "        ==> Plotting ${EQ} ${ReferencePhase} profile for HandSelection (`date +%H:%M:%S`) ..."

    NSTA=`wc -l < tmpfile_s_$$`
    page=0
    plot=$((PLOTPERPAGE_Select+1))

    while read STNM GCARC KCMPNM STLO STLA NETWK AZ BAZ HITLO HITLA good Times
    do
        file="${STNM}.waveform"

        ## new page test.
        if [ ${plot} -eq $((PLOTPERPAGE_Select+1)) ]
        then

            ### seal old page.
            if [ ${page} -gt 0 ]
            then
                psxy -J -R -O >> ${OUTFILE} << EOF
EOF
            fi

            ### plot titles and legends
            plot=1
            page=$((page+1))
            OUTFILE=${page}.ps
            title1="EQ: ${MM}/${DD}/${YYYY}  DATA_CENTER: Merged COMPONENT: T  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE}km  Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_Select} sec."
            title4="GCARC  COMP  STLA/STLO"
            title5="STNM  NETWK  AZ  BAZ"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${title2}
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF
            ### add color of seismic phases.
            psxy -JX${PLOTWIDTH_Select}i/${height}i -R-10/10/-1/1 -Y-0.2i -O -K >> ${OUTFILE} << EOF
EOF

            xp="-9"
            while read num phase color
            do
                psxy -JX${PLOTWIDTH_Select}i/0.4i -R -W0.5p/"${color}" -O -K>> ${OUTFILE} << EOF
${xp} 0
`echo "${xp}+0.5" | bc -l` 0
EOF
                if [ "${phase}" = "S,Sdiff" ]; then
                    pstext -JX${PLOTWIDTH_Select}i/0.4i -R -Wored -O -K >> ${OUTFILE} << EOF
${xp} 0.9 8 0 0 LT ${phase}
EOF
                else
                    pstext -JX${PLOTWIDTH_Select}i/0.4i -R -O -K >> ${OUTFILE} << EOF
${xp} 0.9 8 0 0 LT ${phase}
EOF
                fi

                xp=$((xp+2))

            done < tmpfile_ticks.lst

            ### add legends of station info.
            pstext -JX${TEXTWIDTH_Select}i/0.7i -R -X${PLOTWIDTH_Select}i -Y0.1i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title3}
EOF
            pstext -JX -R -Y-0.175i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title4}
EOF
            pstext -JX -R -Y-0.175i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title5}
EOF
            pstext -JX -R -Y0.25i -O -K >> ${OUTFILE} << EOF
EOF
        fi # end of new page test.

        ## go to next correct position to plot seismograms.

        psxy -JX${PLOTWIDTH_Select}i/${height}i -R${PLOTTIMEMIN_Select}/${PLOTTIMEMAX_Select}/-1/1 -X-${PLOTWIDTH_Select}i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        ## plot traveltime ticks.
		echo ${Times} | sed -s 's/ /\n/g' > tmpfile_$$
		paste tmpfile_ticks.lst tmpfile_$$ > tmpfile2_$$
        while read num phase color Ttime
        do
            psxy -JX -R -W0.3p,${color},- -O -K >> ${OUTFILE} << EOF
${Ttime} -1
${Ttime} 1
EOF
        done < tmpfile2_$$

        ## plot Checkbox.
        if [ ${page} -eq 1 ] && [ ${plot} -eq 1 ]
        then
            cat >> ${OUTFILE} << EOF
[ /_objdef {ZaDb} /type /dict /OBJ pdfmark
[ {ZaDb} <<
    /Type /Font
    /Subtype /Type1
    /Name /ZaDb
    /BaseFont /ZapfDingbats
>> /PUT pdfmark
[ /_objdef {Helv} /type /dict /OBJ pdfmark
[ {Helv} <<
    /Type /Font
    /Subtype /Type1
    /Name /Helv
    /BaseFont /Helvetica
>> /PUT pdfmark
[ /_objdef {aform} /type /dict /OBJ pdfmark
[ /_objdef {afields} /type /array /OBJ pdfmark
[ {aform} <<
    /Fields {afields}
    /DR << /Font << /ZaDb {ZaDb} /Helv {Helv} >> >>
    /DA (/Helv 0 Tf 0 g)
    /NeedAppearances true
>> /PUT pdfmark
[ {Catalog} << /AcroForm {aform} >> /PUT pdfmark
EOF
        fi

        if [ "${good}" -eq 1 ]
        then
            cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/FT /Btn
/Rect [-180 23 -50 153]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (8) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 1 0 0 rg)
/AP << /N << /${EQ}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF
        else
            cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/V /${EQ}_${STNM}
/FT /Btn
/Rect [-180 23 -50 153]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (8) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 1 0 0 rg)
/AP << /N << /${EQ}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF
        fi

        ## plot zero line
        psxy -JX -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Select} 0
${PLOTTIMEMAX_Select} 0
EOF
        for time in `seq -50 50`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_Select}" | bc -l` 0
EOF
        done

        ## plot waveform.
        psxy ${file} -JX -R -W0.5p -O -K >> ${OUTFILE}

        ## add station info.

        pstext -JX -R -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Select} 1 8 0 0 LT `echo "(${page}-1)*${PLOTPERPAGE_Select}+${plot}" | bc`
EOF
        pstext -JX${TEXTWIDTH_Select}i/${halfh}i -R/-1/1/-1/1 -X${PLOTWIDTH_Select}i -Y${quarth}i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${GCARC}  ${COMP}  ${STLA} ${STLO}
EOF
        pstext -JX -R/-1/1/-1/1 -Y-${quarth}i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${STNM}  ${NETWK}  ${AZ}  ${BAZ}
EOF
        ## a little scs hit map.
        pscoast -Jx${xscale}id/${yscale}id -R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX} -Dl -A40000 -W3,gray,faint -X${TEXTWIDTH_Select}i -O -K >> ${OUTFILE}
        psxy -J -R -Sa0.06i -Gblue -O -K >> ${OUTFILE} << EOF
${HITLO} ${HITLA}
EOF
        ## move to next position.
        psxy -J -R -X-${TEXTWIDTH_Select}i -O -K >> ${OUTFILE} << EOF
EOF

        plot=$((plot+1))

    done < tmpfile_s_$$ # Done S plotting loop.

    # seal the last page.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

    # Make PDF.
    cat `ls -rt *.ps` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_HandPick}/${EQ}_${ReferencePhase}_HandPick.pdf
    rm -f *.ps

    # ==================================
    #         ! Make ScS Plot data !
    # ==================================

	echo "        ==> Processing ${EQ} ${MainPhase} (`date +%H:%M:%S`) ..."

	${EXECDIR}/SAC2Signal.out 0 2 6 << EOF
tmpfile_Cin_ScS_$$
${WORKDIR_Plot}/tmpdir_$$/
-190
380
${DELTA}
${F1}
${F2}
0.05
EOF

	if [ $? -ne 0 ]
	then
		echo "    !=> SAC2Signal.out failed ..."
		exit 1
	fi


    # ===================================
    #        ! Plot ScS !
    # ===================================

	echo "        ==> Plotting ${EQ} ${MainPhase} profile for HandSelection (`date +%H:%M:%S`) ..."

    NSTA=`wc -l < tmpfile_s_$$`
    page=0
    plot=$((PLOTPERPAGE_Select+1))

    while read STNM GCARC KCMPNM STLO STLA NETWK AZ BAZ HITLO HITLA good Times
    do
        file="${STNM}.waveform"

        ## new page test.
        if [ ${plot} -eq $((PLOTPERPAGE_Select+1)) ]
        then

            ### seal old page.
            if [ ${page} -gt 0 ]
            then
                psxy -J -R -O >> ${OUTFILE} << EOF
EOF
            fi

            ### plot titles and legends
            plot=1
            page=$((page+1))
            OUTFILE=${page}.ps
            title1="EQ: ${MM}/${DD}/${YYYY}  DATA_CENTER: Merged COMPONENT: T  Page: ${page}"
            title2="${EQ}  ELAT/ELON: ${EVLA} ${EVLO}  Depth: ${EVDE}km  Mag: ${EVMA}  NSTA: ${NSTA}"
            title3="Time tick interval: ${Tick_Select} sec."
            title4="GCARC  COMP  STLA/STLO"
            title5="STNM  NETWK  AZ  BAZ"

            pstext -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -K > ${OUTFILE} << EOF
0 -0.5 14 0 0 CB ${title1}
EOF
            pstext -JX -R -Y-0.35i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${title2}
EOF
            pstext -JX -R -Y-0.15i -Wored -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB bp co ${F1} ${F2} n ${order} p ${passes}
EOF
            ### add color of seismic phases.
            psxy -JX${PLOTWIDTH_Select}i/${height}i -R-10/10/-1/1 -Y-0.2i -O -K >> ${OUTFILE} << EOF
EOF

            xp="-9"
            while read num phase color
            do
                psxy -JX${PLOTWIDTH_Select}i/0.4i -R -W0.5p/"${color}" -O -K>> ${OUTFILE} << EOF
${xp} 0
`echo "${xp}+0.5" | bc -l` 0
EOF
                if [ "${phase}" = "ScS" ]; then
                    pstext -JX${PLOTWIDTH_Select}i/0.4i -R -Wored -O -K >> ${OUTFILE} << EOF
${xp} 0.9 8 0 0 LT ${phase}
EOF
                else
                    pstext -JX${PLOTWIDTH_Select}i/0.4i -R -O -K >> ${OUTFILE} << EOF
${xp} 0.9 8 0 0 LT ${phase}
EOF
                fi

                xp=$((xp+2))

            done < tmpfile_ticks.lst

            ### add legends of station info.
            pstext -JX${TEXTWIDTH_Select}i/0.7i -R -X${PLOTWIDTH_Select}i -Y0.1i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title3}
EOF
            pstext -JX -R -Y-0.175i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title4}
EOF
            pstext -JX -R -Y-0.175i -O -K >> ${OUTFILE} << EOF
0 0 8 0 0 CB ${title5}
EOF
            pstext -JX -R -Y0.25i -O -K >> ${OUTFILE} << EOF
EOF
        fi # end of new page test.

        ## go to next correct position to plot seismograms.

        psxy -JX${PLOTWIDTH_Select}i/${height}i -R${PLOTTIMEMIN_Select}/${PLOTTIMEMAX_Select}/-1/1 -X-${PLOTWIDTH_Select}i -Y-${height}i -O -K >> ${OUTFILE} << EOF
EOF

        ## plot traveltime ticks.
		echo ${Times} | sed -s 's/ /\n/g' > tmpfile_$$
		paste tmpfile_ticks.lst tmpfile_$$ > tmpfile2_$$
        while read num phase color Ttime
        do
            psxy -JX -R -W0.3p,${color},- -O -K >> ${OUTFILE} << EOF
${Ttime} -1
${Ttime} 1
EOF
        done < tmpfile2_$$

        ## plot Checkbox.
        if [ ${page} -eq 1 ] && [ ${plot} -eq 1 ]
        then
            cat >> ${OUTFILE} << EOF
[ /_objdef {ZaDb} /type /dict /OBJ pdfmark
[ {ZaDb} <<
    /Type /Font
    /Subtype /Type1
    /Name /ZaDb
    /BaseFont /ZapfDingbats
>> /PUT pdfmark
[ /_objdef {Helv} /type /dict /OBJ pdfmark
[ {Helv} <<
    /Type /Font
    /Subtype /Type1
    /Name /Helv
    /BaseFont /Helvetica
>> /PUT pdfmark
[ /_objdef {aform} /type /dict /OBJ pdfmark
[ /_objdef {afields} /type /array /OBJ pdfmark
[ {aform} <<
    /Fields {afields}
    /DR << /Font << /ZaDb {ZaDb} /Helv {Helv} >> >>
    /DA (/Helv 0 Tf 0 g)
    /NeedAppearances true
>> /PUT pdfmark
[ {Catalog} << /AcroForm {aform} >> /PUT pdfmark
EOF
        fi

        if [ "${good}" -eq 1 ]
        then
            cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/FT /Btn
/Rect [-180 23 -50 153]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (8) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 1 0 0 rg)
/AP << /N << /${EQ}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF
        else
            cat >> ${OUTFILE} << EOF
[
/T (${EQ}_${STNM})
/V /${EQ}_${STNM}
/FT /Btn
/Rect [-180 23 -50 153]
/F 4 /H /O
/BS << /W 1 /S /S >>
/MK << /CA (8) /BC [ 0 ] /BG [ 1 ] >>
/DA (/ZaDb 0 Tf 1 0 0 rg)
/AP << /N << /${EQ}_${STNM} /null >> >>
/Subtype /Widget
/ANN pdfmark
EOF
        fi

        ## plot zero line
        psxy -JX -R -W0.3p,. -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Select} 0
${PLOTTIMEMAX_Select} 0
EOF
        for time in `seq -50 50`
        do
            psxy -J -R -Sy0.02i -Gblack -O -K >> ${OUTFILE} << EOF
`echo "${time} * ${Tick_Select}" | bc -l` 0
EOF
        done

        ## plot waveform.
        psxy ${file} -JX -R -W0.5p -O -K >> ${OUTFILE}

        ## add station info.

        pstext -JX -R -O -K >> ${OUTFILE} << EOF
${PLOTTIMEMIN_Select} 1 8 0 0 LT `echo "(${page}-1)*${PLOTPERPAGE_Select}+${plot}" | bc`
EOF
        pstext -JX${TEXTWIDTH_Select}i/${halfh}i -R/-1/1/-1/1 -X${PLOTWIDTH_Select}i -Y${quarth}i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${GCARC}  ${COMP}  ${STLA} ${STLO}
EOF
        pstext -JX -R/-1/1/-1/1 -Y-${quarth}i -O -K >> ${OUTFILE} << EOF
0 0 10 0 0 CB ${STNM}  ${NETWK}  ${AZ}  ${BAZ}
EOF
        ## a little scs hit map.
        pscoast -Jx${xscale}id/${yscale}id -R${RLOMIN}/${RLOMAX}/${RLAMIN}/${RLAMAX} -Dl -A40000 -W3,gray,faint -X${TEXTWIDTH_Select}i -O -K >> ${OUTFILE}
        psxy -J -R -Sa0.06i -Gblue -O -K >> ${OUTFILE} << EOF
${HITLO} ${HITLA}
EOF
        ## move to next position.
        psxy -J -R -X-${TEXTWIDTH_Select}i -O -K >> ${OUTFILE} << EOF
EOF

        plot=$((plot+1))

    done < tmpfile_scs_$$ # Done S plotting loop.



    # seal the last page.
    psxy -J -R -O >> ${OUTFILE} << EOF
EOF

    # Make PDF.
    cat `ls -rt *.ps` > tmp.ps
    ps2pdf tmp.ps ${WORKDIR_HandPick}/${EQ}_${MainPhase}_HandPick.pdf
    rm -f *.ps


done # done EQ loop.

cd ${WORKDIR}

exit 0
