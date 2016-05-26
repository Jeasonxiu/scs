#!/bin/bash

#==============================================================
# SYNTHESIS
# This script apply a weigting scheme on each traces.
#
# Outputs:
#
#  update   ${WORKDIR_FRS}/INFO_All
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. "
echo "    ==> Applying weighting scheme... because this is synthesis, we set every trace to 1."


# Continue from last modification.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_$$;
create table Master_$$ as select * from Master_a38;
EOF

mysql -u shule ${SYNDB} << EOF
create table tmptable$$ as (select PairName,convert(1.0,double) as Weight_Final from Master_$$ where wantit=1 );
EOF

# update Master.
${BASHCODEDIR}/UpdateTable.sh ${SYNDB} Master_$$ tmptable$$ PairName


mysql -u shule ${SYNDB} << EOF
drop table if exists tmptable$$;
drop table if exists Master_a41;
create table Master_a41 as select * from Master_$$;
drop table if exists Master_$$;
EOF

# Clean up.
rm -f ${WORKDIR_FRS}/tmpfile*

cd ${CODEDIR}

exit 0
