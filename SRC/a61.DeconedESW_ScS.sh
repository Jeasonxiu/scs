#!/bin/bash

#==============================================================
# This script make ESF of de-convolved ScS traces, which lives
# in ${WORKDIR_Decon}
#
# Shule Yu
# Apr 22 2015
#==============================================================

echo ""
echo "--> `basename $0` is running. "

# Work Begins.
for EQ in ${EQnames}
do

	echo "    ==> ${EQ} Make ESW on deconed ScS ..."
    # EQ specialized parameters.

	rm -rf ${WORKDIR_Decon}/ESW_ScS/${EQ}
	mkdir -p ${WORKDIR_Decon}/ESW_ScS/${EQ}
    cd ${WORKDIR_Decon}/ESW_ScS/${EQ}
	cp ${WORKDIR}/tmpfile_INFILE_${RunNumber} ${WORKDIR_Decon}/ESW_ScS/${EQ}/INFILE
    trap "rm -rf ${WORKDIR_Decon}/ESW_ScS/${EQ} ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

    # I/O for C Code.

	mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select concat("${WORKDIR_Decon}/${EQ}/",STNM,".trace"),STNM,0.0,1.0 from Master_a17 where wantit=1 and eq=${EQ};
EOF
	mysql -N -u shule ${DB} > tmpfile_POLARITY << EOF
select STNM,1 from Master_a17 where wantit=1 and eq=${EQ};
EOF

    # C code.
    ${EXECDIR}/DeconedESW.out 3 6 20 << EOF
2
2
2
${EQ}
ScS
${WORKDIR_Decon}/ESW_ScS/${EQ}
tmpfile_$$
STDOUT
${EQ}.DeconedESW.DT
-50
50
-15
15
0.0
0.0
-1
1
-1
1
0.0
${DELTA}
0.0
0.0
0.0
1
-5
10
-5
10
EOF

    if [ $? -ne 0 ]
    then
        echo "    !=> ESW on Deconed ScS C code failed ..."
        rm -rf ${WORKDIR_Decon}/ESW_ScS/${EQ}
        exit 1;
    fi

	# Clean up.
	rm -f ${WORKDIR_Decon}/ESW_ScS/${EQ}/tmpfile*

done # Done EQ loop.

cd ${WORKDIR}

exit 0
