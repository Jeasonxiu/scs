#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/* Compare the difference between two input arrays. */
/* output file has two numbers in two rows: CCC and |diff|/npts. */


int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile1,infile2,outfile};
    enum Penum  {delta};

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
    double *signal1,*signal2;
    int    npts1,npts2,NPTS;

	npts1=filenr(PS[infile1]);
	npts2=filenr(PS[infile2]);
	NPTS=npts1>npts2?npts2:npts1;

    signal1=(double *)malloc(NPTS*sizeof(double));
    signal2=(double *)malloc(NPTS*sizeof(double));

	// Read in traces.
	double time;
	FILE *fpin;
    fpin=fopen(PS[infile1],"r");
    for (count=0;count<NPTS;count++){
        fscanf(fpin,"%lf%lf",&time,&signal1[count]);
    }
    fclose(fpin);

    fpin=fopen(PS[infile2],"r");
    for (count=0;count<NPTS;count++){
        fscanf(fpin,"%lf%lf",&time,&signal2[count]);
    }
    fclose(fpin);

	// Cross-correlaion.
	double ccc;
	int shift;
    CC_limitshift(signal1,npts1,signal2,npts2,&shift,&ccc,0,P[delta]);

	// ABS difference.
	double DIFF=0;
    for (count=0;count<NPTS;count++){
		DIFF+=fabs(signal1[count]-signal2[count]);
	}
	DIFF/=NPTS;

	// Output.
    FILE *fpout;
    fpout=fopen(PS[outfile],"w");
    fprintf(fpout,"%.5lf\t%.5lf",ccc,DIFF);
    fclose(fpout);

    // Free spaces.
	free(signal1);
	free(signal2);
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
