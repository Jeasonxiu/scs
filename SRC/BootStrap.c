#include<stdio.h>
#include<stdlib.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {nptsx,nptsy,BootN,binN};
    enum PSenum {infile,outfile,outfile2,outfile3};
    enum Penum  {DELTA,BootSigLevel};

    int_num=atoi(argv[1]);
    string_num=atoi(argv[2]);
    double_num=atoi(argv[3]);

    PI=(int *)malloc(int_num*sizeof(int));
    PS=(char **)malloc(string_num*sizeof(char *));
    P=(double *)malloc(double_num*sizeof(double));

    for (count=0;count<string_num;count++){
        PS[count]=(char *)malloc(200*sizeof(char));
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

    int    count2,flag_high,flag_low;
    FILE   *fp,*fpin;
    char   filename[100];
    double **frs,**Boot,*weight,*maxval,*minval,*avr,*sigma;

    frs=(double **)malloc(PI[nptsx]*sizeof(double *));
    Boot=(double **)malloc(PI[BootN]*sizeof(double *));
    weight=(double *)malloc(PI[nptsx]*sizeof(double));
    minval=(double *)malloc(PI[nptsy]*sizeof(double));
    maxval=(double *)malloc(PI[nptsy]*sizeof(double));
    avr=(double *)malloc(PI[nptsy]*sizeof(double));
    sigma=(double *)malloc(PI[nptsy]*sizeof(double));

    for (count=0;count<PI[nptsx];count++){
        frs[count]=(double *)malloc(PI[nptsy]*sizeof(double));
    }
    for (count=0;count<PI[BootN];count++){
        Boot[count]=(double *)malloc(PI[nptsy]*sizeof(double));
    }

    // Read in data.
    fp=fopen(PS[infile],"r");
    for(count=0;count<PI[nptsx];count++){
        fscanf(fp,"%s%lf",filename,&weight[count]);

        fpin=fopen(filename,"r");
        for (count2=0;count2<PI[nptsy];count2++){
            fscanf(fpin,"%*f%lf",&frs[count][count2]);
        }
        fclose(fpin);
    }
    fclose(fp);

    // Bootstrap Test.
    bootstrap(frs,PI[nptsx],PI[nptsy],1,weight,PI[BootN],Boot,sigma);

    // Find upper / lower bound  and average, then output.
    fp=fopen(PS[outfile],"w");
    flag_high=0;
    flag_low=0;

    for (count=0;count<PI[nptsy];count++){
        maxval[count]=-1;
        minval[count]=1;
        avr[count]=0;

        //  Find bounds and average.
        for (count2=0;count2<PI[BootN];count2++){
            if (maxval[count]<Boot[count2][count]){
                maxval[count]=Boot[count2][count];
            }
            if (minval[count]>Boot[count2][count]){
                minval[count]=Boot[count2][count];
            }
            avr[count]+=Boot[count2][count];
        }

        avr[count]/=PI[BootN];

        // Output.
        fprintf(fp,"%11.3lf%15.5e%15.5e%15.5e%15.5e\n",count*P[DELTA],avr[count],sigma[count],maxval[count],minval[count]);

        if (minval[count]>P[BootSigLevel]){
            flag_low=1;
        }

        if (maxval[count]<-P[BootSigLevel]){
            flag_high=1;
        }
    }
    fclose(fp);

	// Output All BootStrap result. ${binN}_{BootN}.boot
	for (count=0;count<PI[BootN];count++){
		sprintf(filename,"%d_%d.trace",PI[binN],count);
		fp=fopen(filename,"w");
		for (count2=0;count2<PI[nptsy];count2++){
            fprintf(fp,"%.4e\t%.4e\n",count2*P[DELTA],Boot[count][count2]);
		}
		fclose(fp);
	}

    // Output lower > BootSigLevel.
    if (flag_low==1){
        fp=fopen(PS[outfile2],"w");
        for (count=0;count<PI[nptsy];count++){
            fprintf(fp,"%.4e\t%.4e\n",count*P[DELTA],minval[count]>0?minval[count]:0.0);
        }
        fclose(fp);
    }

    // Output upper < -BootSigLevel.
    if (flag_high==1){
        fp=fopen(PS[outfile3],"w");
        for (count=0;count<PI[nptsy];count++){
            fprintf(fp,"%.4e\t%.4e\n",count*P[DELTA],maxval[count]<0?maxval[count]:0.0);
        }
        fclose(fp);
    }

    // Free spaces.
    for (count=0;count<PI[nptsx];count++){
        free(frs[count]);
    }
    for (count=0;count<PI[BootN];count++){
        free(Boot[count]);
    }
    free(avr);
    free(maxval);
    free(minval);
    free(weight);
    free(Boot);
    free(frs);
    free(sigma);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
