#include<stdio.h>
#include<stdlib.h>
#include<assert.h>
#include<string.h>
#include<math.h>
#include<sac.h>
#include<sacio.h>
#include<ASU_tools.h>

/*************************************************************************
 * 1. Use CC to make a measurement between Stretched S and ScS trace.
 * 2. Subtract the stretched S esf from every ScS waveform.
 *
 * Shule Yu
 * Nov 03 2014
*************************************************************************/


int main(int argc, char **argv){

    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {cate,fileN};
    enum PSenum {infile,ESFfile};
    enum Penum  {delta,C1,C2,N1,N2,S1,S2,AN,Ratio};

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
    int    NPTS_signal,NPTS_source,count2,*shift,P0,*P2,P3,P4,Pes1,Pes2,polarity;
    FILE   *fp,*fpin,*fpout;
    char   outfile[200],ScSfile[200],**stnm;
    double time,peak,**scs,*esf,**subtract,ccc,misfit,snr,snr_1,snr_2,*Nanchor;

    // Set up trace length.
    NPTS_signal=(int)ceil((P[C2]-P[C1])/P[delta]);


    P2=(int *)malloc(PI[fileN]*sizeof(int));
    scs=(double **)malloc(PI[fileN]*sizeof(double *));
    subtract=(double **)malloc(PI[fileN]*sizeof(double *));
    stnm=(char **)malloc(PI[fileN]*sizeof(char *));
    shift=(int *)malloc(PI[fileN]*sizeof(int));

    for (count=0;count<PI[fileN];count++){
        scs[count]=(double *)malloc(NPTS_signal*sizeof(double));
        subtract[count]=(double *)malloc(NPTS_signal*sizeof(double));
        stnm[count]=(char *)malloc(20*sizeof(char));
    }

    esf=(double *)malloc(NPTS_signal*sizeof(double));

    Nanchor=(double *)malloc(PI[fileN]*sizeof(double));

    // Read in E.S.F.
    // Find its peak position.
    fp=fopen(PS[ESFfile],"r");
    NPTS_source=0;
    while (fscanf(fp,"%lf%lf",&time,&esf[NPTS_source])==2){
        if ( -20 <= time && time <= 25 ){
            NPTS_source++;
        }
    }
    fclose(fp);

    max_ampd(esf,NPTS_source,&P0);

	// Do Tstar on ScS if it is required.

	int NPTS_TS=8000,tmpP,BP;
	double *ts=(double *)malloc(NPTS_TS*sizeof(double));
	double *ans=(double *)malloc((NPTS_TS+NPTS_signal)*sizeof(double));


	if (P[Ratio]<0){
		tstar(P[delta],NPTS_TS,-P[Ratio],ts);
		normalized(ts,NPTS_TS);
	}



    // Read in ScS traces.
// 	int dosnr;

    fp=fopen(PS[infile],"r");
//     dosnr=1;
    for (count=0;count<PI[fileN];count++){

        fscanf(fp,"%s%s%lf%lf",stnm[count],ScSfile,&peak,&Nanchor[count]);

        Nanchor[count]-=peak;

//         if ( P[C1] > Nanchor[count]+P[N1] ){
//             dosnr=0;
//         }

        // Read in ScS traces, shift to ScS peak @ time=0.
        fpin=fopen(ScSfile,"r");

        count2=0;
        while (fscanf(fpin,"%lf%lf",&time,&scs[count][count2])==2){


            if ( P[C1] <= time-peak ){
                count2++;
            }

            if ( count2==NPTS_signal ){
                break;
            }
        }

        fclose(fpin);

        // Find the peak position on ScS:
        P2[count]=(int)ceil(-P[C1]/P[delta]);


		// Convolve ScS with Tstar if we wanted to do so.
		if (P[Ratio]<0){

			convolve(scs[count],ts,NPTS_signal,NPTS_TS,ans);

			// find tstarred ScS peak, shift it to time=0.
			BP=(int)((1-P[C1])/P[delta]);
			max_ampd(ans+BP,560,&tmpP);


			for (count2=0;count2<NPTS_signal;count2++){
				scs[count][count2]=ans[BP+tmpP-P2[count]+count2];
			}

			// normalize it.
			normalize_window(scs[count],NPTS_signal,P2[count]-5,400);

		}


    }
    fclose(fp);

    /*************************************
       Do CC and other estimations first.
    *************************************/

    // Find Half-height position on ESF.
    for (count=P0;count>0;count--){
        if (fabs(esf[count])<0.5){
            Pes1=count;
            break;
        }
    }
    for (count=P0;count<NPTS_source;count++){
        if (fabs(esf[count])<0.5){
            Pes2=count;
            break;
        }
    }

    sprintf(outfile,"tmpfile_%d_StretchDeconInfo",PI[cate]);
    fpout=fopen(outfile,"w");
    fprintf(fpout,"<STNM> <SNR_1> <SNR_2> <SNR> <Shift_St> <CCC_St> <Misfit_St> <Cate> <N1Time> <S1Time> <N2Time> <N3Time>\n");

	int P1=(int)(P[AN]/P[delta]);

    for (count=0;count<PI[fileN];count++){


        // Do CCC estimation betweeen the stretched S esf and ScS traces.
        P3=(int)ceil(10/P[delta]);
        P4=(int)ceil(15/P[delta]);
        polarity=scs[count][P2[count]]>0?1:-1;
        CC_positive(scs[count]+P2[count]-P3,P3+P4,esf+P0-P3,P3+P4,&shift[count],&ccc,polarity);

        // Do Misfit estimation betweeen the stretched and tapered S esf and ScS traces.
        for (count2=P2[count];count2>0;count2--){
            if (fabs(scs[count][count2])<0.5){
                P3=count2;
                break;
            }
        }
        for (count2=P2[count];count2<NPTS_signal;count2++){
            if (fabs(scs[count][count2])<0.5){
                P4=count2;
                break;
            }
        }
        misfit=1.0*(P4-P3)/(Pes2-Pes1)-1;

        // Do SNR estimation on subtracted trace.
        snr=0.0/0.0;
        snr_1=0.0/0.0;
        snr_2=0.0/0.0;

        // Output estimations.
        fprintf(fpout,"%s\t%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf\t%d%11.3lf%11.3lf%11.3lf%11.3lf\n"
        ,stnm[count],snr_1,snr_2,snr,P[delta]*shift[count],ccc,misfit,PI[cate],Nanchor[count]+P[N1],P[S1],P[S1]-P1*P[delta],P[S2]);
    fprintf(fpout,"<STNM> <SNR_1> <SNR_2> <SNR> <Shift_St> <CCC_St> <Misfit_St> <Cate> <N1Time> <S1Time> <N2Time> <N3Time>\n");

    }
    fclose(fpout);

    /******************************************
       Now Just Shift ScS.
    ******************************************/

    for (count=0;count<PI[fileN];count++){

        polarity=scs[count][P2[count]]>0?1:-1;

        for (count2=0;count2<NPTS_signal;count2++){
            subtract[count][count2]=scs[count][count2]*polarity;
        }

    }


    // Output source, shift the peak to time=0.
    sprintf(outfile,"%d.esf",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<NPTS_source;count++){
        fprintf(fpout,"%.4lf\t%.5e\n",(count-P0)*P[delta],esf[count]);
    }
    fclose(fpout);


    // Output signal.
    for (count=0;count<PI[fileN];count++){
        sprintf(outfile,"%s.tapered",stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<NPTS_signal;count2++){
            fprintf(fpout,"%.4lf\t%.5e\n",P[C1]+count2*P[delta],scs[count][count2]);
        }
        fclose(fpout);
    }

    // Output subtract result. (shift to Original ScS peak at zero.)
    for (count=0;count<PI[fileN];count++){
        sprintf(outfile,"%s.trace",stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<NPTS_signal;count2++){
            fprintf(fpout,"%.4lf\t%.5e\n",(count2-P2[count])*P[delta],subtract[count][count2]);
        }
        fclose(fpout);
    }


    /************************
     *  Free spaces.
    ************************/
    for (count=0;count<PI[fileN];count++){
        free(scs[count]);
        free(stnm[count]);
        free(subtract[count]);
    }
    free(scs);
    free(stnm);
    free(subtract);
    free(shift);
    free(esf);
    free(P2);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
