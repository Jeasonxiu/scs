#!/bin/bash

#==============================================================
# SYNTHESIS
# This script apply a weigting scheme on each traces.
#
# Outputs:
#
# create ScS.Master_a41
#
# Shule Yu
# Jun 22 2014
#==============================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
echo "    ==> Applying weighting scheme... because this is synthesis, we set every trace to 1."


# Continue from last modification.
mysql -u shule ${SYNDB} << EOF
drop table if exists Master_a41;
create table Master_a41 as select * from Master_a38;
EOF

mysql -u shule ${SYNDB} << EOF
alter table Master_a41 add column Weight_Final double(8,3) comment "Weight assigned by Scheme Number ${WeightScheme}";
update Master_a41 set Weight_Final=1.0 where wantit=1;
EOF

cd ${WORKDIR}

exit 0
