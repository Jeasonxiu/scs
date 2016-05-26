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
    enum PSenum {outfile};
    enum Penum  {strike,dip,rake};

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
    FILE   *fpout;
    double ans,a,t,s,d,r,take,az;

    // Convert parameters into rad unit.
    s=P[strike]*M_PI/180;
    d=P[dip]*M_PI/180;
    r=P[rake]*M_PI/180;

    fpout=fopen(PS[outfile],"w");
    for (az=0;az<=360;az=az+1){
        for (take=0;take<=90;take=take+1){

            a=az*(M_PI/180);
            t=take*(M_PI/180);

            // Calculate raddiation. (T component)
            ans=cos(r)*cos(d)*cos(t)*sin(a-s)+
                cos(r)*sin(d)*sin(t)*cos(2*(a-s))+
                sin(r)*cos(2*d)*cos(t)*cos(a-s)-
                0.5*sin(r)*sin(2*d)*sin(t)*sin(2*(a-s));

            fprintf(fpout,"%11.4lf%11.4lf%11.4lf\n",az,take,ans);
        }
    }

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
