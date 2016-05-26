#!/bin/bash


color[1]=red
color[2]=green
color[3]=blue
color[4]=purple
color[5]=darkgreen
color[6]=cyan
color[7]=darkblue
color[8]=gold
color[9]=yellow


xlabel="Misfit (ScS)."
ylabel="Misfit (S)."
XMIN=-1
XMAX=1
XNUM=0.5
XINC=0.1
YMIN=-1
YMAX=1
YNUM=0.5
YINC=0.1

PROJ=-JX${width}i/${height}i
REG="-R${XMIN}/${XMAX}/${YMIN}/${YMAX}"

psbasemap ${REG} ${PROJ} -Ba${XNUM}f${XINC}:"${xlabel}":/a${YNUM}f${YINC}:"${ylabel}":WS -O -K >> ${OUTFILE}

psxy ${REG} ${PROJ} -W0.01p,black -O -K >> ${OUTFILE} << EOF
-1 -1
1 1
EOF

# ${BASHCODEDIR}/Findrow.sh tmpfile_stnm_cate_scs_misfit_s_misfit ${WORKDIR_Stations}/SpecialList | awk '{print $2,$3,$4,$5}' > tmpfile_cate_scs_misfit_s_misfit_$$

for count in `seq 1 ${CateN}`
do
#     awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_scs_misfit_s_misfit_$$ > tmpfile_$$
    awk -v C=${count} '{if ($1==C) print $2,$3}' tmpfile_cate_scs_misfit_s_misfit > tmpfile_$$
    psxy tmpfile_$$ ${REG} ${PROJ} -Sp0.05i -W${color[$count]} -O -K >> ${OUTFILE} << EOF
EOF

done



exit 0
