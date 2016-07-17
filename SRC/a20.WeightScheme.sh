#!/bin/bash

#==============================================================
# This script apply a weigting scheme on each traces.
#
# Outputs:
#
# create ScS.Master_a20
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
echo "    ==> Applying weighting scheme ${WeightScheme}..."
trap "rm -f ${WORKDIR}/tmpfile*$$ ${WORKDIR}/*_${RunNumber}; exit 1" SIGINT

# Continue from last modification.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a17;
EOF

case "${WeightScheme}" in

	1 ) # Use a ramp function on ScS SNR.

		mysql -u shule ${DB} << EOF
create table tmptable$$ as (select PairName,if(SNR_ScS>15.0,convert(1.0,double),SNR_ScS/15.0) as Weight_Final from Master_$$ where wantit=1 );
EOF

		;;

	2 ) # Use ScS ESW constructor weight.

		mysql -u shule ${DB} << EOF
create table tmptable$$ as (select PairName,Weight_ScS as Weight_Final from Master_$$ where wantit=1 );
EOF

		;;

	3 ) # Use CC between Subtraction FRS and Water Decon FRS.

		mysql -N -u shule ${DB} > tmpfile_$$ << EOF
select PairName,concat("${WORKDIR_WaterFRS}/",PairName,".frs"),concat("${WORKDIR_SubtractFRS}/",PairName,".frs") from Master_$$ where wantit=1;
EOF

		${EXECDIR}/SchemeCC.out 0 2 0 << EOF
tmpfile_$$
tmpfile_Cout_$$
EOF

		if [ $? -ne 0 ]
		then
			echo "    !=> SchemeCC.out Error!"
			rm -f tmpfile*$$
			exit 1;
		fi

		mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
create table tmptable$$(
PairName     varchar(22) not null unique primary key,
Weight_Final double comment "Final Given weight"
);
load data local infile "tmpfile_Cout_$$" into table tmptable$$
fields terminated by "," lines terminated by "\n"
(PairName,Weight_Final);
EOF

		;;

	4 ) # Use SNR measured on deconed ScS trace. SNR_D in Master_$$.
		
		Higher=15.0
		Lower=7.0

		mysql -u shule ${DB} << EOF
create table tmptable$$ as (select PairName,if(SNR_D>=${Higher},convert(1.0,double),if(SNR_D<${Lower},convert(0.0,double),(SNR_D-${Lower})/(${Higher}-${Lower}))) as Weight_Final from Master_$$ where wantit=1 );
EOF


		;;

	* ) # All is 1.

		mysql -u shule ${DB} << EOF
create table tmptable$$ as (select PairName,convert(1.0,double) as Weight_Final from Master_$$ where wantit=1 );
EOF

		;;

esac


case "${WeightNormalize}" in

	EQ )

		for EQ in ${EQnames}
		do

			# Check number of valid traces.
			cat > tmpfile_CheckValid_$$ << EOF
select count(*) from Master_$$ where eq=${EQ} and wantit=1;
EOF
			NR=`mysql -N -u shule ${DB} < tmpfile_CheckValid_$$`
			rm -f tmpfile_CheckValid_$$
			if [ ${NR} -eq 0 ]
			then
				continue
			fi

			echo "select max(Weight_Final) from tmptable$$ where pairname like \"${EQ}%\"" > tmpfile_$$
			Max=`mysql -N -u shule ${DB} < tmpfile_$$`
			mysql -u shule ${DB} << EOF
update tmptable$$ set Weight_Final=Weight_Final/${Max} where pairname like "${EQ}%";
EOF
		done

		;;

	All )

		echo "select max(Weight_Final) from tmptable$$" > tmpfile_$$
		Max=`mysql -N -u shule ${DB} < tmpfile_$$`
		mysql -u shule ${DB} << EOF
update tmptable$$ set Weight_Final=Weight_Final/${Max};
EOF

		;;

	* )
		;;

esac

# update Master.
${BASHCODEDIR}/UpdateTable.sh ${DB} Master_$$ tmptable$$ PairName

mysql -u shule ${DB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a20;
create table Master_a20 as select * from Master_$$;
drop table if exists Master_$$;
EOF


# Clean up.
rm -f ${WORKDIR}/tmpfile*$$

cd ${WORKDIR}

exit 0
