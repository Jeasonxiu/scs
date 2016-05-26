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

    enum PIenum {NRecord,TraceLength};
    enum PSenum {infile,outfile};
    enum Penum  {DELTA};

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
    int    *shift,count2;
    char   INFILE[100];
    FILE   *fpin,*fpout,*fp;
    double **data,*weight,time,*stack,*std;

    data=(double **)malloc(PI[NRecord]*sizeof(double *));
    for (count=0;count<PI[NRecord];count++){
        data[count]=(double *)malloc(PI[TraceLength]*sizeof(double));
    }
    weight=(double *)malloc(PI[NRecord]*sizeof(double));
    stack=(double *)malloc(PI[TraceLength]*sizeof(double));
    std=(double *)malloc(PI[TraceLength]*sizeof(double));
	shift=NULL;

    // Read in traces (data).
    fpin=fopen(PS[infile],"r");
    for (count=0;count<PI[NRecord];count++){
        fscanf(fpin,"%s%lf",INFILE,weight+count);

        fp=fopen(INFILE,"r");
        for (count2=0;count2<PI[TraceLength];count2++){
            fscanf(fp,"%lf%lf",&time,&data[count][count2]);
        }
        fclose(fp);
    }
    fclose(fpin);


    shift_stack(data,PI[NRecord],PI[TraceLength],0,shift,1,weight,stack,std);

    fpout=fopen(PS[outfile],"w");
    for (count=0;count<PI[TraceLength];count++){
        fprintf(fpout,"%.8e\t%.8e\t%.8e\n",count*P[DELTA],stack[count],std[count]);
    }
    fclose(fpout);

    // Free spaces.
    for (count=0;count<PI[NRecord];count++){
        free(data[count]);
    }

    free(stack);
    free(std);
    free(data);
    free(weight);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
