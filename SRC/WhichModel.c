#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<assert.h>
#include<ASU_tools.h>

/***********************************************************
 * Weighted stack the FRS within each bin of each model,
 * calculate std.
***********************************************************/

int main(int argc, char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {TraceLength,binN};
    enum PSenum {infile1,infile2,outfile,model};
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
    FILE   *fpin1,*fpin2,*fpout;
    double *amp1,*amp2,time,CCC,tmp,PNorm,PNorm1,CCC_new;

    amp1=(double *)malloc(PI[TraceLength]*sizeof(double));
    amp2=(double *)malloc(PI[TraceLength]*sizeof(double));

    // Read in traces (data).
    fpin1=fopen(PS[infile1],"r");
    fpin2=fopen(PS[infile2],"r");

    for (count=0;count<PI[TraceLength];count++){
        fscanf(fpin1,"%lf%lf%lf",&time,&amp1[count],&tmp);
        fscanf(fpin2,"%lf%lf%lf",&time,&amp2[count],&tmp);
    }
    fclose(fpin1);
    fclose(fpin2);

    // Method 1.
    CC_static(amp1,PI[TraceLength],amp2,PI[TraceLength],&CCC);

    // amp2 is model stack, amp1 is the same throughout model.
    // Method 2. norm_2 difference.
    PNorm=p_norm_err(amp2,amp1,PI[TraceLength],2);

    // Method 3. norm_1 difference.
    PNorm1=p_norm_err(amp2,amp1,PI[TraceLength],1);

    // Method 4.
    CC_static_energy(amp1,PI[TraceLength],amp2,PI[TraceLength],&CCC_new);

    fpout=fopen(PS[outfile],"a");
    fprintf(fpout,"%d\t%s\t%.4lf\t%.4lf\t%.4lf\t%.4lf\n",PI[binN],PS[model],CCC,PNorm,PNorm1,CCC_new);
    fclose(fpout);

    // Free spaces.
    free(amp1);
    free(amp2);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
