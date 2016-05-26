#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Flip-Reverse-Sum every deconed trace at the peak of ScS.
***********************************************************/

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile};
    enum Penum  {Time,DELTA};

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
    int    npts;
    FILE   *fp,*fpin,*fpout;
    char   in[200],out[200];
    double time,*amp;

    amp=(double *)malloc((int)ceil(P[Time]/P[DELTA])*sizeof(double));

    fp=fopen(PS[infile],"r");
    while (fscanf(fp,"%s%s",in,out)==2){

        // Read in deconed trace, count the trace length.
        fpin=fopen(in,"r");
        count=0;
        while (fscanf(fpin,"%lf%lf",&time,&amp[count])==2){
            if (fabs(time)<P[Time]/2){
                count++;
            }
        }
        fclose(fpin);

		npts=count;

        // Output.
        fpout=fopen(out,"w");
        for (count=0;count<npts;count++){
            fprintf(fpout,"%.4lf\t%.5e\n",count*P[DELTA],amp[count]);
        }
        fclose(fpout);

    }
    fclose(fp);

    // Free spaces.

    free(amp);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
