#include<stdio.h>
#include<stdlib.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile1,infile2};
    enum Penum  {limit,delta};

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
    
    /****************************************************************

                              Job begin.

    ****************************************************************/
    FILE   *fpin;
    double *signal1,*signal2,time,ccc;
    int    shift,npts1,npts2;


	npts1=filenr(PS[infile1]);
	npts2=filenr(PS[infile2]);
	
    signal1=(double *)malloc(PI[npts1]*sizeof(double));
    signal2=(double *)malloc(PI[npts2]*sizeof(double));

    fpin=fopen(PS[infile1],"r");
    for (count=0;count<PI[npts1];count++){
        fscanf(fpin,"%lf%lf",&time,&signal1[count]);
    }
    fclose(fpin);

    fpin=fopen(PS[infile2],"r");
    for (count=0;count<PI[npts2];count++){
        fscanf(fpin,"%lf%lf",&time,&signal2[count]);
    }
    fclose(fpin);

    CC_limitshift(signal1,PI[npts1],signal2,PI[npts2],&shift,&ccc,P[limit],P[delta]);

	// Output to stdout.
    printf("%.5lf",ccc);

    // Free spaces.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
