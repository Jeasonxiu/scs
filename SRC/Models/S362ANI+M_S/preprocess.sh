#!/bin/bash

# extract data from this model.
ncdump S362ANI+M_kmps.nc > all.ncdump

# velocity data
d1=`grep -n "vs =" all.ncdump | awk 'BEGIN {FS=":"} {print $1+1}'`
d2=`grep -n "vsv =" all.ncdump | awk 'BEGIN {FS=":"} {print $1-1}'`

sed -n ${d1},${d2}p all.ncdump > v.dat
ed -s v.dat << EOF
%s/;/,/g
wq
EOF

# locate data begin/end
a=`grep -n ";" all.ncdump | awk 'BEGIN {FS=":"} {print $1}'`
e=`echo ${a} |awk '{print $NF}'`

# depth data.
dp1=`grep -n "depth =" all.ncdump | grep ,| awk 'BEGIN {FS=":"} {print $1}'`
count=${dp1}
while [ "${count}" -lt "$e" ]
do
    echo $a | grep "[[:blank:]]${count}[[:blank:]]" > /dev/null
    if [ $? -eq 0 ]
    then
        dp2=${count}
        break
    fi
    count=$((${count}+1))
done

sed -n ${dp1},${dp2}p all.ncdump > depth.dat
ed -s depth.dat << EOF
%s/;/,/g
%s/depth =//g
wq
EOF

# lat data
lat1=`grep -n "latitude =" all.ncdump | grep ,| awk 'BEGIN {FS=":"} {print $1}'`
count=${lat1}
while [ $count -lt "$e" ]
do
    echo $a | grep "[[:blank:]]${count}[[:blank:]]" > /dev/null
    if [ $? -eq 0 ]
    then
        lat2=${count}
        break
    fi
    count=$((${count}+1))
done

sed -n ${lat1},${lat2}p all.ncdump > lat.dat
ed -s lat.dat << EOF
%s/;/,/g
%s/latitude =//g
wq
EOF

# lon data
lon1=`grep -n "longitude =" all.ncdump | grep ,| awk 'BEGIN {FS=":"} {print $1}'`
count=${lon1}
while [ $count -lt "$e" ]
do
    echo $a | grep "[[:blank:]]${count}[[:blank:]]" > /dev/null
    if [ $? -eq 0 ]
    then
        lon2=${count}
        break
    fi
    count=$((${count}+1))
done

sed -n ${lon1},${lon2}p all.ncdump > lon.dat
ed -s lon.dat << EOF
%s/;/,/g
%s/longitude =//g
wq
EOF

exit 0
