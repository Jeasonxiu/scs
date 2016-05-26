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

    enum PIenum {CMTflag};
    enum PSenum {infile,outfile,EQ};
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
    FILE   *fpin,*fpout;
    char   *stnm;
    double evlo,evla,evde,stlo,stla,rayp,rayp2,ans,ans2;
    double u,v,w,x,y,a,t,s,d,r;

    // Convert parameters into rad unit.
    s=P[strike]*M_PI/180;
    d=P[dip]*M_PI/180;
    r=P[rake]*M_PI/180;

    stnm=(char *)malloc(20*sizeof(char));
    fpin=fopen(PS[infile],"r");
    fpout=fopen(PS[outfile],"w");
    while (fscanf(fpin,"%s%lf%lf%lf%lf%lf%lf%lf",stnm,&evlo,&evla,&evde,&stlo,&stla,&rayp,&rayp2)==8){
        if (PI[CMTflag]==0){
            fprintf(fpout,"%s_%s\t%11.2lf\t%11.2lf\n",PS[EQ],stnm,1.0,1.0);
        }
        else{
            if (evde>1000){
                evde/=1000;
            }

            // Calculate azimuth (in rad).
            u=evla*M_PI/180;
            v=stla*M_PI/180;
            w=(stlo-evlo)*M_PI/180;
            y=sin(w);
            x=cos(u)*tan(v)-sin(u)*cos(w);
            a=atan2(y,x);

            t=asin(d_vs(evde)*rayp/(6371-evde));
            ans=cos(r)*cos(d)*cos(t)*sin(a-s)+
                cos(r)*sin(d)*sin(t)*cos(2*(a-s))+
                sin(r)*cos(2*d)*cos(t)*cos(a-s)-
                0.5*sin(r)*sin(2*d)*sin(t)*sin(2*(a-s));

            t=asin(d_vs(evde)*rayp2/(6371-evde));
            ans2=cos(r)*cos(d)*cos(t)*sin(a-s)+
                cos(r)*sin(d)*sin(t)*cos(2*(a-s))+
                sin(r)*cos(2*d)*cos(t)*cos(a-s)-
                0.5*sin(r)*sin(2*d)*sin(t)*sin(2*(a-s));

            fprintf(fpout,"%s_%s\t%11.4lf%11.4lf\n",PS[EQ],stnm,ans,ans2);
        }
    }

    fclose(fpin);
    fclose(fpout);
    free(stnm);

    // Free spaces.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
