#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ASU_tools.h>

/***********************************************************
 * Find each records belongs to which bin.
 * Output series of *.grid files contains stations within
 * this bin.
***********************************************************/

int main(int argc, char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {Threshold};
    enum PSenum {infile,BinFile};
//     enum Penum  {};

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

    for (count=0;count<string_num;count++){
        if (scanf("%s",PS[count])!=1){
            printf("In C : String parameter reading Error !\n");
            return 1;
        }
    }

    for (count=0;count<double_num;count++){
        if (scanf("%lf",P+count)!=1){
            printf("In C : Double parameter reading Error !\n");
            return 1;
        }
    }

    // Job begin.


    int    **index,count2,count3,npts;
	int    NRecord=filenr(PS[infile]),NBin=filenr(PS[BinFile]);
    char   **EQ,**STNM,outfile[200];
    FILE   *fpin,*fpout;
    double *hitlo,*hitla,*binlo,*binla,*binr,*binlo_before,*binla_before;

    index=(int **)malloc(NRecord*sizeof(int *));
    EQ=(char **)malloc(NRecord*sizeof(char *));
    STNM=(char **)malloc(NRecord*sizeof(char *));

    for (count=0;count<NRecord;count++){
        index[count]=(int *)malloc(NBin*sizeof(int));
        EQ[count]=(char *)malloc(20*sizeof(char));
        STNM[count]=(char *)malloc(10*sizeof(char));
    }

    hitlo=(double *)malloc(NRecord*sizeof(double));
    hitla=(double *)malloc(NRecord*sizeof(double));
    binlo=(double *)malloc(NBin*sizeof(double));
    binla=(double *)malloc(NRecord*sizeof(double));
    binlo_before=(double *)malloc(NBin*sizeof(double));
    binla_before=(double *)malloc(NBin*sizeof(double));
    binr=(double *)malloc(NBin*sizeof(double));

    // Read in station info and data.
    fpin=fopen(PS[infile],"r");
    for (count=0;count<NRecord;count++){
        fscanf(fpin,"%s%s%lf%lf",EQ[count],STNM[count],&hitlo[count],&hitla[count]);
    }
    fclose(fpin);

    // Read in grid info.
    fpin=fopen(PS[BinFile],"r");
    for (count=0;count<NBin;count++){
        fscanf(fpin,"%lf%lf%lf",&binlo[count],&binla[count],&binr[count]);
        binlo_before[count]=binlo[count];
        binla_before[count]=binla[count];
    }
    fclose(fpin);

    // Get job done.
    cbin_update(hitlo,hitla,NRecord,binlo,binla,binr,NBin,index);

    // Output qualified stack ( # of traces greater than Threshold).
    count3=0;
    for (count=0;count<NBin;count++){

        // Count each bin have how many number of record.
        npts=0;
        for (count2=0;count2<NRecord;count2++){
            npts+=index[count2][count];
        }

        if (npts>PI[Threshold]){

            count3++;

            // Output *.grid files.
            sprintf(outfile,"%d.grid",count3);
            fpout=fopen(outfile,"w");
            fprintf(fpout,"<EQ> <STNM> <DIST> <binR> <binLon> <binLat> <binLon_Before> <binLat_Before>\n");
            for (count2=0;count2<NRecord;count2++){
                if (index[count2][count]==1){
                    fprintf(fpout,"%s\t%s\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\n",EQ[count2],STNM[count2],gcpdistance(hitlo[count2],hitla[count2],binlo[count],binla[count]),binr[count],binlo[count],binla[count],binlo_before[count],binla_before[count]);
                }
            }
            fclose(fpout);
        }
    }

    // Free spaces.

    for (count=0;count<NRecord;count++){
        free(EQ[count]);
        free(STNM[count]);
        free(index[count]);
    }

    free(index);
    free(EQ);
    free(STNM);

    free(hitlo);
    free(hitla);
    free(binlo);
    free(binla);
    free(binr);
    free(binlo_before);
    free(binla_before);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
