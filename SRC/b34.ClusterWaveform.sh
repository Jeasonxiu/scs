#!/bin/bash

# ===========================================================
# Plot Category result.
#
# Shule Yu
# Oct 27 2014
# ===========================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow

# Plot parameters.
gmt gmtset PS_MEDIA letter
gmt gmtset FONT_ANNOT_PRIMARY 8p
gmt gmtset FONT_LABEL 10p
gmt gmtset MAP_LABEL_OFFSET 6p
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_GRID_PEN_PRIMARY 0.25p,gray,-

# ===========================
#         ! Plot !
# ===========================
REG="-R${CateB}/`echo "${CateB}+${CateWidth}"|bc -l`/-1/1.1"
PROJ="-JX3.5i/`echo "10 * 4 / 5 / ${PLOTPERPAGE_Cate}" | bc -l`i"

page=0
plot=$(($PLOTPERPAGE_Cate+1))
for EQ in ${EQnames}
do

    # Gather information.
    mysql -N -u shule ${SYNDB} > tmpfile_station_list << EOF
select stnm,category from Master_a34 where eq=${EQ} and wantit=1 order by category DESC;
EOF
    for cate in `seq 1 ${CateN}`
    do
        NR[${cate}]=`awk -v C=${cate} '{ if ($2==C) print $1 }' tmpfile_station_list | wc -l`
    done

    ## check if need to plot on a new page.
    if [ ${plot} -eq $(($PLOTPERPAGE_Cate+1)) ]
    then

        ### if this isn't first page, seal the last page.
        if [ ${page} -gt 0 ]
        then
            gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF
        fi

        ### plot titles and legends
        plot=1
        page=$(($page+1))
        OUTFILE=${page}.ps

		cat > tmpfile_$$ << EOF
0 -0.3 S waveform clustering result. Page: ${page}
EOF
		gmt pstext tmpfile_$$ -F+jCB+f16p,Helvetica-Bold -JX7i/0.7i -R-1/1/-1/1 -X0.75i -Y10.45i -P -N -K > ${OUTFILE}

		cat > tmpfile_$$ << EOF
-0.5 -1.1 Tapered S
0.5 -1.1 Original S
EOF
		gmt pstext tmpfile_$$ -F+jCB+f13p -J -R -N -O -K >> ${OUTFILE}

        gmt psxy ${PROJ} ${REG} -Y-`echo "10 / ${PLOTPERPAGE_Cate}" | bc -l`i -O -K >> ${OUTFILE} << EOF
EOF
    fi # end new page test.


    # Plot title.
	cat > tmpfile_$$ << EOF
${CateB} 1.2 ${EQ}. Number of traces: @;${color[1]};${NR[1]}@;; @;${color[2]};${NR[2]}@;; @;${color[3]};${NR[3]}@;;
EOF
    gmt pstext tmpfile_$$ -F+jLB+f10p ${REG} ${PROJ} -N -O -K >> ${OUTFILE}

    gmt psbasemap -R -J -Ba5g5f1/a0.5g0.1f0.1WSne -O -K >> ${OUTFILE}
    gmt psbasemap -R -J -Ba5g5f1/g0.1f0.1WSne -X3.7i -O -K >> ${OUTFILE}
    gmt psxy ${PROJ} ${REG} -X-3.7i -O -K >> ${OUTFILE} << EOF
EOF

    # Plot data.
    while read stnm cate
    do
        gmt psxy ${PROJ} ${REG} ${WORKDIR_Category}/${EQ}/${stnm}.tapered -W0.5p,${color[${cate}]} -N -O -K >> ${OUTFILE}
        gmt psxy ${PROJ} ${REG} ${WORKDIR_Category}/${EQ}/${stnm}.traces -W0.5p,${color[${cate}]} -X3.7i -N -O -K >> ${OUTFILE}
        gmt psxy ${PROJ} ${REG} -X-3.7i -O -K >> ${OUTFILE} << EOF
EOF
    done < tmpfile_station_list

    gmt psxy ${PROJ} ${REG} -Y-`echo "10 / ${PLOTPERPAGE_Cate}" | bc -l`i -O -K >> ${OUTFILE} << EOF
EOF

    plot=$(($plot+1))

done # done EQ loop.

# Make PDF.
gmt psxy -J -R -O >> ${OUTFILE} << EOF
EOF
Title=`basename $0`
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

cd ${WORKDIR}

exit 0
