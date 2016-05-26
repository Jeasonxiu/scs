#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Generate ScS bouncing point path (3 deg around bouncing point)
***********************************************************/

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile,outfile};
    enum Penum  {depth};

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
    char   *phase="ScS";
    FILE   *fpin,*fpout;
    double EVLO,EVLA,EVDP,STLO,STLA,plo1,pla1,plo2,pla2;
    fpin=fopen(PS[infile],"r");
    fpout=fopen(PS[outfile],"a");

    while (fscanf(fpin,"%lf%lf%lf%lf%lf",&STLO,&STLA,&EVLO,&EVLA,&EVDP)==5){
        if (EVDP>1000){
            EVDP=EVDP/1000;
        }
        waypoint_deeppath(phase,EVLO,EVLA,EVDP,STLO,STLA,P[depth],&plo1,&pla1,&plo2,&pla2);
        fprintf(fpout,"%11.3lf%11.3lf\n%11.3lf%11.3lf\n>\n",plo1,pla1,plo2,pla2);
    }

    fclose(fpin);
    fclose(fpout);

    return 0;
}
