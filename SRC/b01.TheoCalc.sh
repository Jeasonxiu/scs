#!/bin/bash

echo ""
echo "--> `basename $0` is running. (`date`)"
mkdir -p ${WORKDIR_Plot}/tmpdir_$$
cd ${WORKDIR_Plot}/tmpdir_$$
trap "rm -rf ${WORKDIR_Plot}/tmpdir_$$; exit 1" SIGINT EXIT

# Plot parameters.
gmtset PAPER_MEDIA = letter
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 10p
gmtset LABEL_OFFSET = 0.05c
gmtset GRID_PEN_PRIMARY = 0.25p,200/200/200


# Test calculation result.
mysql -u shule ${DB} >/dev/null 2>&1 << EOF
select * from Master_a01;
EOF

if [ $? -ne 0 ]
then
    echo "ScS.Master_a01 doesn't exists ..."
    exit 1
fi

# ================================================
#         ! Work Begin !
# ================================================

mysql -N -u shule ${DB} > tmpfile_master << EOF
select evde,gcarc,vs,thickness,inangle,transangle,rayp_ScS,P_SvS,P_ScS_ULVZ,P_ScS_ULVZ_In,P_ScscS,P_ScscS_Up,P_ScscS_In from Master_a01;
EOF

XMIN=-80
XMAX=80
YMIN=0
YMAX=124.444444

count=1
while read evde gcarc vs thickness inangle transangle rayp_scs p_svs p_scs_ulvz p_scs_ulvz_in p_scscs p_scscs_up p_scscs_in
do
    inangle_rad=`echo ${inangle}*3.1415926/180 | bc -l`
    deg2km_CMB=`echo "2*3.1415926*3480/360" | bc -l`
    deg2km_ULVZ=`echo "2*3.1415926*(6371.0-2891.0+${thickness})/360" | bc -l`

    OUTFILE=${count}.ps

    REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"
    PROJ="-JX9i/7i"


    psxy -Ggray ${REG} ${PROJ} -X1i -K -L -m > ${OUTFILE} << EOF
${XMIN} ${thickness}
${XMAX} ${thickness}
${XMAX} 0
${XMIN} 0
${XMIN} ${thickness}
EOF

    psxy -Sc0.4i -Gred -R -J -O -K >> ${OUTFILE} << EOF
0 0 
EOF

    # ScS.
    psxy -Wthick,green -R -J -O -K -m >> ${OUTFILE} << EOF
0 0 
${XMIN} `echo ${XMIN} ${inangle_rad} | awk '{print -$1*sqrt(1-sin($2)^2)/sin($2)}'`
>
0 0 
${XMAX} `echo ${XMIN} ${inangle_rad} | awk '{print -$1*sqrt(1-sin($2)^2)/sin($2)}'`
EOF

    # SvS.
    psxy -Wthick,red -R -J -O -K -m >> ${OUTFILE} << EOF
`echo "${p_svs} ${deg2km_ULVZ}" | awk '{print $1*$2}'` ${thickness}
${XMIN} `echo ${XMIN} ${inangle_rad} ${p_svs} ${deg2km_ULVZ} ${thickness} | awk '{print $5+(-$1+$3*$4)*sqrt(1-sin($2)^2)/sin($2)}'`
>
`echo "${p_svs} ${deg2km_ULVZ}" | awk '{print $1*$2}'` ${thickness}
${XMAX} `echo ${XMIN} ${inangle_rad} ${p_svs} ${deg2km_ULVZ} ${thickness} | awk '{print $5+(-$1+$3*$4)*sqrt(1-sin($2)^2)/sin($2)}'`
EOF

    # ScS_ULVZ.
    ScS_Bounce=`echo "${p_scs_ulvz} ${deg2km_CMB}" | awk '{print $1*$2}'`
    ScS_In=`echo "${p_scs_ulvz_in} ${deg2km_ULVZ}" | awk '{print $1*$2}'`
    ScS_Out=`echo "${p_scs_ulvz} ${p_scs_ulvz_in} ${deg2km_ULVZ}" | awk '{print ($1*2-$2)*$3}'`
    psxy -Wthick,blue -R -J -O -K -m >> ${OUTFILE} << EOF
${ScS_Bounce} ${YMIN}
${ScS_In} ${thickness}
>
${ScS_Bounce} ${YMIN}
${ScS_Out} ${thickness}
>
${ScS_In} ${thickness}
${XMIN} `echo ${ScS_In} ${XMIN} ${inangle_rad} ${thickness} | awk '{print $4+($1-$2)*sqrt(1-sin($3)^2)/sin($3)}'`
>
${ScS_Out} ${thickness}
${XMAX} `echo ${ScS_Out} ${XMAX} ${inangle_rad} ${thickness} | awk '{print $4+($2-$1)*sqrt(1-sin($3)^2)/sin($3)}'`
EOF

    # ScscS.
    ScscS_right=`echo "${p_scscs_up} ${p_scscs} ${deg2km_CMB}" | awk '{print ($1*2-$2)*$3 }'`
    ScscS_Out=`echo "${p_scscs_up} ${p_scscs} ${deg2km_ULVZ}" | awk '{print (3*$1-2*$2)*$3}'`
    psxy -Wthick,purple -R -J -O -K -m >> ${OUTFILE} << EOF
`echo "${p_scscs_in} ${deg2km_ULVZ}" | awk '{print $1*$2}' ` ${thickness}
`echo "${p_scscs} ${deg2km_CMB}" | awk '{print $1*$2}' ` ${YMIN}
>
`echo "${p_scscs} ${deg2km_CMB}" | awk '{print $1*$2}' ` ${YMIN}
`echo "${p_scscs_up} ${deg2km_ULVZ}" | awk '{print $1*$2}' ` ${thickness}
>
`echo "${p_scscs_up} ${deg2km_ULVZ}" | awk '{print $1*$2}' ` ${thickness}
${ScscS_right} ${YMIN}
>
${ScscS_right} ${YMIN}
${ScscS_Out} ${thickness}
>
`echo "${p_scscs_in} ${deg2km_ULVZ}" | awk '{print $1*$2}' ` ${thickness}
${XMIN} `echo ${p_scscs_in} ${XMIN} ${inangle_rad} ${thickness} ${deg2km_ULVZ} | awk '{print $4+($1*$5-$2)*sqrt(1-sin($3)^2)/sin($3)}'`
>
${ScscS_Out} ${thickness}
${XMAX} `echo ${ScscS_Out} ${XMAX} ${inangle_rad} ${thickness} | awk '{print $4+($2-$1)*sqrt(1-sin($3)^2)/sin($3)}'`
EOF

    pstext -R -J -O -K >> ${OUTFILE} << EOF
0 `echo ${YMIN} ${YMAX} | awk '{print $1+($2-$1)*0.8}'` 8 0 0 CB dVs: `echo ${vs} | awk '{print ($1-1)*100"%"}'`
0 `echo ${YMIN} ${YMAX} | awk '{print $1+($2-$1)*0.75}'` 8 0 0 CB Thickness: ${thickness} km.
0 `echo ${YMIN} ${YMAX} | awk '{print $1+($2-$1)*0.60}'` 8 0 0 CB Distance: ${gcarc} deg.
EOF

    psbasemap -R -J -Ba20f5:"Distance ( km. )":/a20f5:"Distance ( km. )":WSne -O >> ${OUTFILE}

    count=$((count+1))

done < tmpfile_master

# Make PDFs.
Title=`basename $0`
cat `ls -rt *.ps` > tmp.ps
ps2pdf tmp.ps ${WORKDIR_Plot}/${Title%.sh}.pdf

exit 0
