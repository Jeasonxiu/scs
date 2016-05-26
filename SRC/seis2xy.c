#include<stdio.h>
#include<stdlib.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile,outfile};
    enum Penum  {range,timemin,timemax};

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
//
//
//     for (count=0;count<int_num;count++){
//             printf("%d\n",PI[count]);
//     }
//     for (count=0;count<string_num;count++){
//             printf("%s\n",PS[count]);
//     }
//     for (count=0;count<double_num;count++){
//             printf("%lf\n",P[count]);
//     }
//     return 1;

    // Job begin.
    double gcarc,time,amp,dt,xposition,yposition;
    char   filename[300];
    FILE   *fp,*fpin,*fpout;
    int    polarity;

    fp=fopen(PS[infile],"r");
    fpout=fopen(PS[outfile],"w");
    while (fscanf(fp,"%lf%lf%d%s",&gcarc,&dt,&polarity,filename)==4){

        fpin=fopen(filename,"r");
        while (fscanf(fpin,"%lf%lf",&time,&amp)==2){
            amp*=polarity;
            if (time-dt>P[timemin] && time-dt<P[timemax]){
                xposition=P[timemin]+time-dt-P[timemin];
                yposition=gcarc+P[range]/2*amp;
                fprintf(fpout,"%lf\t%lf\n",xposition,yposition);
            }
        }
		fclose(fpin);
        fprintf(fpout,">\n");

    }
    fclose(fp);
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
