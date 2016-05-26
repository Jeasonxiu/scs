#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<assert.h>
#include<ASU_tools.h>

/***********************************************************
 * Make Geographic bins.
***********************************************************/

int main(int argc, char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    int_num=atoi(argv[1]);
    string_num=atoi(argv[2]);
    double_num=atoi(argv[3]);

    PI=(int *)malloc(int_num*sizeof(int));
    PS=(char **)malloc(string_num*sizeof(char *));
    P=(double *)malloc(double_num*sizeof(double));

    for (count=0;count<string_num;count++){
        PS[count]=(char *)malloc(200*sizeof(char *));
    }

    for (count=0;count<int_num;count++){
        if (scanf("%d",PI+count)!=1){
            printf("In C : Int parameter reading Error !\n");
            return 1;
        }
    }
//     enum PIenum {};

    for (count=0;count<string_num;count++){
        if (scanf("%s",PS[count])!=1){
            printf("In C : String parameter reading Error !\n");
            return 1;
        }
    }
    enum PSenum {BinFile};

    for (count=0;count<double_num;count++){
        if (scanf("%lf",P+count)!=1){
            printf("In C : Double parameter reading Error !\n");
            return 1;
        }
    }
    enum Penum {LOMIN,LOMAX,LOINC,LAMIN,LAMAX,LAINC,Radius};

    // Job begin.

    int    lonum,lanum,count2;
    FILE   *fpout;
    double lat,lon;

    // Adjust maximum lon/lat value according to increment and radius.
    lonum=(int)ceil((P[LOMAX]-P[LOMIN]-2*P[Radius])/P[LOINC]);
    lanum=(int)ceil((P[LAMAX]-P[LAMIN]-2*P[Radius])/P[LAINC]);
    P[LOMAX]=P[LOMIN]+(lonum-1)*P[LOINC]+2*P[Radius];
    P[LAMAX]=P[LAMIN]+(lanum-1)*P[LAINC]+2*P[Radius];

    // Print out bin center lat/lon and radius.
    fpout=fopen(PS[BinFile],"w");
    lat=P[LAMAX]-P[Radius];
    for (count=0;count<lonum;count++){
        lon=P[LOMIN]+P[Radius];
        for (count2=0;count2<lanum;count2++){
            fprintf(fpout,"%.2lf\t%.2lf\t%.2lf\n",lon,lat,P[Radius]);
            lon+=P[LOINC];
        }
        lat-=P[LAINC];
    }
    fclose(fpout);

    // Free space.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
