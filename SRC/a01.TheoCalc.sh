#!/bin/bash

# ====================================================================
# This script calculate the reflection / transmission of ScS interact
# with ULVZ.
# Output: time delay / polarity change / amplitude ratio information.
#
# sds  : pre-cursor.
# scs2 : post-cursor.
#
# Shule Yu
# Nov 12 2014
# ====================================================================

echo ""
echo "--> `basename $0` is running. (`date`)"
cd ${WORKDIR}

# ==================================================
#              ! Work Begin !
# ==================================================


# C code.
${EXECDIR}/TheoCalc.out 0 1 15 << EOF
tmpfile_$$
${MinEvde}
${MaxEvde}
${EvdeInc}
${MinDist}
${MaxDist}
${DistInc}
${MinHeight}
${MaxHeight}
${HeightInc}
${Min_dVs}
${Max_dVs}
${dVsInc}
${MinRho}
${MaxRho}
${RhoInc}
EOF

if [ $? -ne 0 ]
then
    echo "    !=> Theo C code failed ..."
    exit 1
fi


# format infile.
sed 's/[[:blank:]]\+/,/g' tmpfile_$$ > tmpfile_in_$$

# Make Master_$$.
mysql -u shule ${DB} << EOF
drop table if exists Master_$$;
create table Master_$$(
EVDE         double comment "event depth in km",
GCARC        double comment "great circle distance",
Vs           double comment "fraction of actual S wave velocity",
Rho          double comment "fraction of actual density",
Thickness    double comment "ULVZ height",
InAngle      double comment "Incident Angle on ULVZ",
TransAngle   double comment "Transition Angle after ray propagate into ULVZ",
SvS          double comment "ULVZ top side amplitude reflection coefficient",
SuS          double comment "ULVZ underneath top side amplitude reflection coefficient",
StS          double comment "ULVZ top side downward amplitude transimission coefficient",
SttS         double comment "ULVZ top side upward amplitude transimission coefficient",
Amp_SdS      double comment "pre-cursor amplitude (relative to ScS)",
Amp_ScS2     double comment "post-cursor amplitude (relative to ScS)",
Amp_FRS      double comment "FRS amplitude (relative to ScS)",
dT           double comment "FRS arrival time (relative to ScS peak)",
ratio        double comment "Vs,Rho scaling factor",
rayp_ScS     double comment "PREM ScS ray parameter (by TauP)",
rayp_SvS     double comment "SdS ray parameter (in deg/sec., by grid search)",
rayp_ScS_ULVZ double comment "ScS ray parameter (in deg/sec., by grid search)",
rayp_ScscS   double comment "ScS2 ray parameter (in deg/sec., by grid search)",
P_SvS        double comment "SdS bouncing position (relative to ScS_PREM bouncing position, by grid search)",
P_ScS_ULVZ   double comment "ScS_ULVZ bouncing position (relative to ScS_PREM bouncing position, by grid search)",
P_ScS_ULVZ_In double comment "ScS_ULVZ incident position (relative to ScS_PREM bouncing position, by grid search)",
P_ScscS      double comment "ScS2 CMB bouncing position (relative to ScS_PREM bouncing position, by grid search)",
P_ScscS_Up   double comment "ScS2 ULVZ bouncing position (relative to ScS_PREM bouncing position, by grid search)",
P_ScscS_In   double comment "ScS2 ULVZ incident position (relative to ScS_PREM bouncing position, by grid search)"
);
load data local infile "tmpfile_in_$$" into table Master_$$
fields terminated by "," lines terminated by "\n"
(EVDE,GCARC,Vs,Rho,Thickness,InAngle,TransAngle,SvS,SuS,StS,SttS,Amp_SdS,Amp_ScS2,Amp_FRS,dT,ratio,rayp_ScS,rayp_SvS,rayp_ScS_ULVZ,rayp_ScscS,P_SvS,P_ScS_ULVZ,P_ScS_ULVZ_In,P_ScscS,P_ScscS_Up,P_ScscS_In);
EOF


# update Master_a01.
mysql -u shule ${DB} << EOF
drop table if exists Master_a01;
create table Master_a01 as select * from Master_$$;
drop table if exists Master_$$;
EOF



# Clean up.
rm -f ${WORKDIR}/tmpfile*$$

cd ${WORKDIR}

exit 0








