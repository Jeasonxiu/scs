#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {INFILE,OUTFILE,PHASE,PHASE2,EQ};
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
    FILE   *fpin,*fpout;
    char   kstnm[10],tmpstr[100];
    double evlo,evla,evdp,stlo,stla,plo,pla,pdepth;

    fpin=fopen(PS[INFILE],"r");
    fpout=fopen(PS[OUTFILE],"w");
    fprintf(fpout,"<STNM> <HITLO> <HITLA> <PairName> <WantIt>\n");
    while (fscanf(fpin,"%lf%lf%lf%lf%lf%s",&evlo,&evla,&evdp,&stlo,&stla,kstnm)==6){
        if (evdp>1000){
            evdp/=1000;
        }

        sprintf(tmpstr,"%s_%s_%s.path",PS[EQ],kstnm,PS[PHASE]);
        if (bottom_location_fp(evlo,evla,evdp,stlo,stla,PS[PHASE],&plo,&pla,&pdepth,0.5,tmpstr)==0){
            fprintf(fpout,"%10s%10.2lf%10.2lf\t%s_%s\t%d\n",kstnm,plo,pla,PS[EQ],kstnm,1);
        }
		else{
            fprintf(fpout,"%10s\tNULL\tNULL\t%s_%s\t%d\n",kstnm,PS[EQ],kstnm,0);
		}

        sprintf(tmpstr,"%s_%s_%s.path",PS[EQ],kstnm,PS[PHASE2]);
        bottom_location_fp(evlo,evla,evdp,stlo,stla,PS[PHASE2],&plo,&pla,&pdepth,0.5,tmpstr);
    }

    fclose(fpin);
    fclose(fpout);

    // Free spaces.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);
    
    return 0;    
}
