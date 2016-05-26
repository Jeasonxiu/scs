#!/bin/bash

cd ..

while read depth
do
    
    ./mkmap 4 ${depth} >/dev/null

    tail -n 2 map.${depth}km.xyz > poles.xyz

    while read lon lat dvs
    do
        for count in `seq -180 -1`
        do
            echo "${count} ${lat} ${dvs}" >> map.${depth}km.xyz
        done

        for count in `seq 1 179`
        do
            echo "${count} ${lat} ${dvs}" >> map.${depth}km.xyz
        done

    done < poles.xyz

    sort -k2,2 -k1,1 -g map.${depth}km.xyz > makeNC/${depth}.xyz

done << EOF
25
30
34
36
50
75
100
125
150
175
200
225
250
275
300
325
350
375
400
414
416
425
450
475
500
525
550
575
600
625
650
675
700
725
750
775
800
825
850
875
900
925
950
975
1000
1050
1100
1150
1200
1250
1300
1350
1400
1450
1500
1550
1600
1650
1700
1750
1800
1850
1900
1950
2000
2050
2100
2150
2200
2250
2300
2350
2400
2450
2500
2550
2600
2650
2700
2750
2800
2850
2891
EOF

rm *.ps 2>/dev/null

exit 0
