#!/bin/bash

# ==============================================================
# SYNTHESIS
# This script runs ScS-Stripping project.
#
# Shule Yu
# Feb 08 2015
# ==============================================================

# Export variables to all sub scripts.
set -a
CODEDIR=${PWD}
SRCDIR=${PWD}/SRC
RunNumber=$$
BranchName=`git branch | grep "*" | awk '{print $2}'`

#============================================
#            ! Test Files !
#============================================
if ! [ -e ${CODEDIR}/INFILE ]
then
    echo "INFILE not found ..."
    exit 1
fi

#============================================
#            ! Parameters !
#============================================


# DIRs
WORKDIR=`grep "<SYNWORKDIR>" ${CODEDIR}/INFILE | awk '{print $2}'`
trap "rm -f ${WORKDIR}/tmpfile*_$$; exit 1" SIGINT
mkdir -p ${WORKDIR}/LIST
mkdir -p ${WORKDIR}/INPUT
cp ${CODEDIR}/INFILE ${WORKDIR}/tmpfile_INFILE_$$
cp ${CODEDIR}/INFILE ${WORKDIR}/INPUT/INFILE_`date +%m%d_%H%M`
cp ${CODEDIR}/list_syn.sh ${WORKDIR}/tmpfile_list_$$
cp ${CODEDIR}/list_syn.sh ${WORKDIR}/LIST/LIST_`date +%m%d_%H%M`
chmod -x ${WORKDIR}/LIST/*
cd ${WORKDIR}

# Deal with parameters for plotting.
grep -n "<" ${CODEDIR}/INFILE_Plot     \
| grep ">" | grep -v "BEGIN" | grep -v "END" \
| awk 'BEGIN {FS="<"} {print $2}'            \
| awk 'BEGIN {FS=">"} {print $1,$2}' > tmpfile_$$
awk '{print $1}' tmpfile_$$ > tmpfile1_$$
awk '{$1="";print "\""$0"\""}' tmpfile_$$ > tmpfile2_$$
sed 's/\"[[:blank:]]/\"/' tmpfile2_$$ > tmpfile3_$$
paste -d= tmpfile1_$$ tmpfile3_$$ > tmpfile_$$
source ${WORKDIR}/tmpfile_$$

# Deal with parameters.
grep -n "<" ${WORKDIR}/tmpfile_INFILE_$$     \
| grep ">" | grep -v "BEGIN" | grep -v "END" \
| awk 'BEGIN {FS="<"} {print $2}'            \
| awk 'BEGIN {FS=">"} {print $1,$2}' > tmpfile_$$
awk '{print $1}' tmpfile_$$ > tmpfile1_$$
awk '{$1="";print "\""$0"\""}' tmpfile_$$ > tmpfile2_$$
sed 's/\"[[:blank:]]/\"/' tmpfile2_$$ > tmpfile3_$$
paste -d= tmpfile1_$$ tmpfile3_$$ > tmpfile_$$
source ${WORKDIR}/tmpfile_$$
WORKDIR=${SYNWORKDIR}
DATADIR=${SYNDATADIR}

grep -n "<" ${WORKDIR}/tmpfile_INFILE_$$ \
| grep ">" | grep "_BEGIN"               \
| awk 'BEGIN {FS=":<"} {print $2,$1}'    \
| awk 'BEGIN {FS="[> ]"} {print $1,$NF}' \
| sed 's/_BEGIN//g'                      \
| sort -g -k 2,2 > tmpfile1_$$

grep -n "<" ${WORKDIR}/tmpfile_INFILE_$$ \
| grep ">" | grep "_END"                 \
| awk 'BEGIN {FS=":<"} {print $2,$1}'    \
| awk 'BEGIN {FS="[> ]"} {print $1,$NF}' \
| sed 's/_END//g'                        \
| sort -g -k 2,2 > tmpfile2_$$

paste tmpfile1_$$ tmpfile2_$$ | awk '{print $1,$2,$4}' > tmpfile_parameters_$$

while read Name line1 line2
do
    Name=${Name%_*}
    awk -v N1=${line1} -v N2=${line2} '{ if ( $1!="" && N1<NR && NR<N2 ) print $0}' ${WORKDIR}/tmpfile_INFILE_$$ \
	| sed 's/^[[:blank:]]*//g' > ${WORKDIR}/tmpfile_${Name}_$$
done < tmpfile_parameters_$$

# Model names.
EQnames=`cat ${WORKDIR}/tmpfile_EQsSYN_$$`

# Additional DIRs and files.
EXECDIR=${WORKDIR}/bin
WORKDIR_Plot=${WORKDIR}/PLOTS
WORKDIR_Basicinfo=${WORKDIR}/Basicinfo
WORKDIR_Sampling=${WORKDIR}/Sampling
WORKDIR_AutoSelect=${WORKDIR}/AutoSelect
WORKDIR_HandPick=${WORKDIR}/HandPick
WORKDIR_ESFAll=${WORKDIR}/ESFAll
WORKDIR_Category=${WORKDIR}/Category
WORKDIR_ESF=${WORKDIR}/ESF
WORKDIR_Stretch=${WORKDIR}/Stretch
WORKDIR_WaterDecon=${WORKDIR}/WaterDecon
WORKDIR_WaterSDecon=${WORKDIR}/WaterSDecon
WORKDIR_WaterHalfSDecon=${WORKDIR}/WaterHalfSDecon
WORKDIR_AmmonDecon=${WORKDIR}/AmmonDecon
WORKDIR_SubtractDecon=${WORKDIR}/SubtractDecon
WORKDIR_RawDecon=${WORKDIR}/RawDecon
WORKDIR_WaterWL=${WORKDIR}/WaterWL
WORKDIR_WaterFRS=${WORKDIR}/WaterFRS
WORKDIR_WaterSFRS=${WORKDIR}/WaterSFRS
WORKDIR_WaterHalfSFRS=${WORKDIR}/WaterHalfSFRS
WORKDIR_AmmonFRS=${WORKDIR}/AmmonFRS
WORKDIR_SubtractFRS=${WORKDIR}/SubtractFRS
WORKDIR_WaterWLFRS=${WORKDIR}/WaterWLFRS
WORKDIR_RawFRS=${WORKDIR}/RawFRS
WORKDIR_Geo=${WORKDIR}/Geo
WORKDIR_Cluster=${WORKDIR}/Cluster
WORKDIR_Model=${WORKDIR}/Modeling
WORKDIR_Freq=${WORKDIR}/Frequency
WORKDIR_Game=${WORKDIR}/Game
WORKDIR_Resolution=${WORKDIR}/Resolution
WORKDIR_Amplitude=${WORKDIR}/Amplitude

case "${DeconMethod}" in

	Waterlevel )

		WORKDIR_Decon=${WORKDIR_WaterDecon}
		WORKDIR_FRS=${WORKDIR_WaterFRS}

		;;

	Ammon )

		WORKDIR_Decon=${WORKDIR_AmmonDecon}
		WORKDIR_FRS=${WORKDIR_AmmonFRS}

		;;


	WaterWL )

		WORKDIR_Decon=${WORKDIR_WaterWL}
		WORKDIR_FRS=${WORKDIR_WaterWLFRS}

		;;

	Subtract )

		WORKDIR_Decon=${WORKDIR_SubtractDecon}
		WORKDIR_FRS=${WORKDIR_SubtractFRS}

		;;

	Raw )

		WORKDIR_Decon=${WORKDIR_RawDecon}
		WORKDIR_FRS=${WORKDIR_RawFRS}

		;;

	WaterHalfS )

		WORKDIR_Decon=${WORKDIR_WaterHalfSDecon}
		WORKDIR_FRS=${WORKDIR_WaterHalfSFRS}

		;;

	WaterS )

		WORKDIR_Decon=${WORKDIR_WaterSDecon}
		WORKDIR_FRS=${WORKDIR_WaterSFRS}

		;;

	* )

		echo "Decon Method Error !"
		exit 1

esac



#============================================
#            ! Test Dependencies !
#============================================
CommandList="${FCOMP} ${CCOMP} sac psxy taup ps2pdf bc mlpack_kmeans"
for Command in ${CommandList}
do
    command -v ${Command} >/dev/null 2>&1 || { echo >&2 "Command ${Command} is not found. Exiting ... "; exit 1; }
done

#============================================
#            ! Compile !
#============================================
mkdir -p ${EXECDIR}
trap "rm -f ${EXECDIR}/*.o ${WORKDIR}/*_$$; exit 1" SIGINT

# Inclusions and Libraries.
INCLUDEDIR="-I${CPPCODEDIR} -I${CCODEDIR} -I${SACDIR}/include -I${SRCDIR} -I/home/shule/.local/include -I/usr/include -I/opt/local/include -I${GMTHDIR}"
LIBRARYDIR="-L${CPPCODEDIR} -L${CCODEDIR} -L${SACDIR}/lib -L/home/shule/.local/lib -L/opt/local/lib -L. -L${GMTLIBDIR}"
# Note the order of the libraries:
# If libA.a depends on libB.a, then -lA should appears before -lB.
LIBRARIES="-lt041 -lASU_tools -lsac -lsacio -lgmt -lmlpack -lfftw3 -larmadillo -lm"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${GMTLIBDIR}

# ASU_tools Functions.
cd ${CCODEDIR}
make
cd ${EXECDIR}

# Project Functions.
${CCOMP} -c ${SRCDIR}/*.fun.c ${INCLUDEDIR}
rm -f libt041.a libASU_tools.a
ar cr libt041.a *.o

# Executables (c) .
for code in `ls -rt ${SRCDIR}/*.c 2>/dev/null | grep -v fun.c`
do
    name=`basename ${code}`
    name=${name%.c}

    ${CCOMP} -Wall -Wimplicit -o ${EXECDIR}/${name}.out ${code} ${INCLUDEDIR} ${LIBRARYDIR} ${LIBRARIES}

    if [ $? -ne 0 ]
    then
        echo "${name} C code is not compiled ..."
        rm -f ${EXECDIR}/*.o ${WORKDIR}/*_$$
        exit 1
    fi
done

# Executables (c++).
for code in `ls -rt ${SRCDIR}/*.cpp 2>/dev/null | grep -v fun.cpp`
do
    name=`basename ${code}`
    name=${name%.cpp}

    ${CPPCOMP} ${CPPFLAG} -o ${EXECDIR}/${name}.out ${code} ${INCLUDEDIR} ${LIBRARYDIR} ${LIBRARIES}

    if [ $? -ne 0 ]
    then
        echo "${name} C++ code is not compiled ..."
        rm -f ${EXECDIR}/*.o ${WORKDIR}/*_$$
        exit 1
    fi
done

# Ammon's Decon code.
${FCOMP} -o ${EXECDIR}/iterdecon ${SRCDIR}/iterdeconfd.f ${SRCDIR}/recipes00.f ${SACDIR}/lib/sacio.a 2>/dev/null
if [ $? -ne 0 ]
then
    echo "Ammon's code is not compiled ..."
    rm -f ${EXECDIR}/*.o ${WORKDIR}/*_$$
    exit 1
fi

# Clean up.
rm -f ${EXECDIR}/*fun.o ${EXECDIR}/*a

# ==============================================
#           ! Work Begin !
# ==============================================

cat >> ${WORKDIR}/stdout << EOF

=============================================
Run Date: `date`; On branch: ${BranchName}.
EOF

bash ${WORKDIR}/tmpfile_list_$$ >> ${WORKDIR}/stdout 2>&1

cat >> ${WORKDIR}/stdout << EOF

End Date: `date`
=============================================
EOF

# grep -v "^#" ${WORKDIR}/tmpfile_list_$$ | awk '{if ($1!="") print $0}' | mail -s "${CODEDIR} Job Done !" ysl6.626@gmail.com

# Clean up.
rm -f ${WORKDIR}/*_$$

exit 0
