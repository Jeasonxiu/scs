#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<assert.h>
#include<string.h>
#include<ASU_tools.h>

/***********************************************************
 * Weighted stack the FRS within each bin, calculate std.
 * Output series of *.frstack files contains the stack result.
 * Output series of *.stackSig files contains the std result.
***********************************************************/

int main(int argc, char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {NRecord,nptsy,Adaptive};
    enum PSenum {infile,outfile1,outfile1_un,outfile2,outfile3,outfile4};
    enum Penum  {DELTA,StdSig,sigma};

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

    int    count2,flag_high,flag_low,*shift;
    char   filename[200];
    FILE   *fpin,*fpout,*fpin2;
    double **frs,*stack,*std,*weight,dist;

    frs=(double **)malloc(PI[NRecord]*sizeof(double *));
    weight=(double *)malloc(PI[NRecord]*sizeof(double));
	shift=NULL;

    for (count=0;count<PI[NRecord];count++){
        frs[count]=(double *)malloc(PI[nptsy]*sizeof(double));
    }
    stack=(double *)malloc(PI[nptsy]*sizeof(double));
    std=(double *)malloc(PI[nptsy]*sizeof(double));


    // Read in station info and frs traces.
    fpin=fopen(PS[infile],"r");
    for (count=0;count<PI[NRecord];count++){
        fscanf(fpin,"%s%lf%lf",filename,&weight[count],&dist);

        // Weight the stack with a distance to the bin center.
		if (P[sigma]>0){
			weight[count]*=(P[sigma]*sqrt(2*M_PI)*gaussian(dist,P[sigma],0));
		}

        fpin2=fopen(filename,"r");
        for (count2=0;count2<PI[nptsy];count2++){
            fscanf(fpin2,"%*f%lf",&frs[count][count2]);
        }
        fclose(fpin2);
    }
    fclose(fpin);

	// Output  *.frstack_unweighted files.
    shift_stack(frs,PI[NRecord],PI[nptsy],0,shift,0,weight,stack,std);
    fpout=fopen(PS[outfile1_un],"w");
    for (count=0;count<PI[nptsy];count++){
        fprintf(fpout,"%.4e\t%.4e\t%.4e\n",count*P[DELTA],stack[count],std[count]);
    }
    fclose(fpout);

    // Get job done.
    shift_stack(frs,PI[NRecord],PI[nptsy],0,shift,1,weight,stack,std);

	// If we need it to be adaptive.
	// Correlate each frs with the weigthed stack.
	// Use the correlation coefficients as new weight.
	int loop;
	if (PI[Adaptive]==1){
		for (loop=0;loop<3;loop++){

			sprintf(filename,"AdaptiveCC_%d",loop);
			fpout=fopen(filename,"w");
			for (count=0;count<PI[NRecord];count++){
				fprintf(fpout,"%.4lf\n",weight[count]);
			}
			fclose(fpout);


			for (count=0;count<PI[NRecord];count++){
				CC_static(stack,PI[nptsy],frs[count],PI[nptsy],weight+count);
				if (weight[count]<0){
					weight[count]=0;
				}
			}


			shift_stack(frs,PI[NRecord],PI[nptsy],0,shift,1,weight,stack,std);
		}

		sprintf(filename,"AdaptiveCC_%d",loop);
		fpout=fopen(filename,"w");
		for (count=0;count<PI[NRecord];count++){
			fprintf(fpout,"%.4lf\n",weight[count]);
		}
		fclose(fpout);

	}

    // Find upper / lower bound , then output.

    // Output *.frstack files.
    fpout=fopen(PS[outfile1],"w");
    for (count=0;count<PI[nptsy];count++){
        fprintf(fpout,"%.4e\t%.4e\t%.4e\n",count*P[DELTA],stack[count],std[count]);
    }
    fclose(fpout);


    // Output newly assigned weight.
    fpout=fopen(PS[outfile4],"w");
    for (count=0;count<PI[NRecord];count++){
        fprintf(fpout,"%.3lf\n",weight[count]);
    }
    fclose(fpout);


    // Output small std traces.
    flag_low=0;
    flag_high=0;
    for (count=0;count<PI[nptsy];count++){
        if (stack[count]-std[count]>P[StdSig]){
            flag_low=1;
        }
        if (stack[count]+std[count]<-P[StdSig]){
            flag_high=1;
        }

    }

    if (flag_low==1){
        fpout=fopen(PS[outfile2],"w");
        assert(fpout);
        for (count=0;count<PI[nptsy];count++){
            if (stack[count]-std[count]>0){
                fprintf(fpout,"%.4e\t%.4e\n",count*P[DELTA],stack[count]-std[count]);
            }
            else{
                fprintf(fpout,"%.4e\t%.4e\n",count*P[DELTA],0.0);
            }
        }
        fclose(fpout);
    }

    if (flag_high==1){
        fpout=fopen(PS[outfile3],"w");
        for (count=0;count<PI[nptsy];count++){
            fprintf(fpout,"%.4e\t%.4e\n",count*P[DELTA],stack[count]+std[count]<0?stack[count]+std[count]:0.0);
        }
        fclose(fpout);
    }

    // Free spaces.

    for (count=0;count<PI[NRecord];count++){
        free(frs[count]);
    }
    free(stack);
    free(std);
    free(frs);
    free(weight);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
