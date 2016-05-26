#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Create Weight from input 14 crazy measurement.
***********************************************************/

int main(int argc,char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {weightscheme,key_num,st_num};
    enum PSenum {infile,outfile};
//     enum Penum  {};

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
    int    count2;
    double *W;
    enum   Weights {CCC_S,SNR_S,Weight_S,Misfit_S,Rad_Pat_S,Norm2_S,CCC_ScS,SNR_ScS,Weight_ScS,Misfit_ScS,Rad_Pat_ScS,Norm2_ScS,SNR_1,SNR_2,SNR_D,CCC_St,Misfit_St,WaterLevel};

    W=(double *)malloc(PI[key_num]*sizeof(double));

    fpin=fopen(PS[infile],"r");
    fpout=fopen(PS[outfile],"w");
    for (count=0;count<PI[st_num];count++){

        // Read inputs.

        for (count2=0;count2<PI[key_num];count2++){
            fscanf(fpin,"%lf",&W[count2]);
        }

        // Calculation and outputs.

        switch(PI[weightscheme]){

			case 0 :

				fprintf(fpout,"%11.3lf\n",1.0);
				break;

            case 1 :
				fprintf(fpout,"%11.3lf\n",ramp_function(W[SNR_ScS],0,15));
                break;
            
            case 2 :
                fprintf(fpout,"%11.3lf\n",W[Weight_ScS]);
                break;

            case 3 :
                fprintf(fpout,"%11.3lf\n",W[Weight_S]*W[Weight_ScS]);
                break;

            case 4 :
                fprintf(fpout,"%11.3lf\n",W[SNR_1]*W[SNR_2]/(W[SNR_1]+W[SNR_2]));
                break;
            
            case 5 :
                fprintf(fpout,"%11.3lf\n",fabs(W[CCC_St]));
                break;

            case 6 :
                fprintf(fpout,"%11.3lf\n",W[Rad_Pat_ScS]/W[Rad_Pat_S]);
                break;

            case 7 :
                fprintf(fpout,"%11.3lf\n",W[Weight_ScS]);
                break;

            case 8 :
                fprintf(fpout,"%11.3lf\n",fabs(1/W[Misfit_St]));
                break;

            case 9 :
                fprintf(fpout,"%11.3lf\n",W[Weight_ScS]*W[Weight_S]*(1-ramp_function(W[Norm2_S],0,0.8))*(1-ramp_function(W[Norm2_ScS],0,0.8))*(1-ramp_function(fabs(W[Misfit_S]),0.25,0.5))*(1-ramp_function(fabs(W[Misfit_ScS]),0.25,0.5)));
                break;

            case 10 :
                fprintf(fpout,"%11.3lf\n",W[SNR_1]*W[SNR_2]/(W[SNR_1]+W[SNR_2])*(W[CCC_S]>0.9?1:0)*(W[CCC_ScS]>0.85?1:0)*(W[Misfit_ScS]>-0.05?1:0)*(W[Misfit_ScS]<0.1?1:0));
                break;

            case 11 :
                fprintf(fpout,"%11.3lf\n",W[WaterLevel]);
                break;

            default :
                fprintf(fpout,"%11.3lf\n",1.0);
        }
    }

    fclose(fpin);
    fclose(fpout);

	// Free Spaces.

	free(W);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
