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

    enum PIenum {phase};
    enum PSenum {infile,outfile};
    enum Penum  {evde,strike,dip,rake};

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

    /****************************************************************

                              Job begin.

    ****************************************************************/

    FILE   *fpin,*fpout;
    double rayp,az,takeoff,angle,phi,theta;
    char   stnm[10];

    fpin=fopen(PS[infile],"r");
    fpout=fopen(PS[outfile],"w");

    fprintf(fpout,"<STNM> <Angle>\n");

    while (fscanf(fpin,"%s%lf%lf",stnm,&rayp,&az)==3){

        rayp*=(M_PI/180);

        takeoff=rayp2takeoff(rayp,P[evde],PI[phase]);

        cmt2tp(P[strike],P[dip],P[rake],&phi,&theta);

        angle=tpangle(phi,theta,az,M_PI-takeoff);

        fprintf(fpout,"%s\t%lf\n",stnm,angle*180/M_PI);

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
