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
 * 2. Decon the stretched S esf from every ScS waveform.
 * 3. Make ESF of deconed trace to get CCC, Misfit ..
 * 4. Reconstruct ScS and Measure the difference between
 *    original ScS and reconstructed trace.
 *
 * Shule Yu
 * Nov 03 2014
*************************************************************************/

int main(int argc, char **argv){

    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {cate,fileN,MoreInfo};
    enum PSenum {infile,ESFfile};
    enum Penum  {waterlevel,sigma,gwidth,delta,Taper_source,Taper_signal,C1,C2,N1,N2,S1,S2,AN,filter1,filter2,Ratio};

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
    int    NPTS_signal,NPTS_source,count2,shift,P0,P1,*P2,P3,P4,Pes1,Pes2,dosnr,polarity;
    FILE   *fp,*fpin,*fpout;
    char   outfile[200],ScSfile[200],**stnm;
    double time,peak,**scs,**scs_fft_amp,**scs_fft_phase,**scs_divide_amp,**scs_divide_phase,*esf,*filled_esf_fft_amp,*filled_esf_fft_phase,**decon,*Nanchor,ccc,misfit,snr,snr_1,snr_2,df,AMP;


    // Set up trace length.
    NPTS_signal=(int)ceil((P[C2]-P[C1])/P[delta]);
    df=1.0/(2*NPTS_signal-1)/P[delta];

    P2=(int *)malloc(PI[fileN]*sizeof(int));
    scs=(double **)malloc(PI[fileN]*sizeof(double *));
    decon=(double **)malloc(PI[fileN]*sizeof(double *));
    scs_fft_amp=(double **)malloc(PI[fileN]*sizeof(double *));
    scs_fft_phase=(double **)malloc(PI[fileN]*sizeof(double *));
    scs_divide_amp=(double **)malloc(PI[fileN]*sizeof(double *));
    scs_divide_phase=(double **)malloc(PI[fileN]*sizeof(double *));
    stnm=(char **)malloc(PI[fileN]*sizeof(char *));

    Nanchor=(double *)malloc(PI[fileN]*sizeof(double));

    for (count=0;count<PI[fileN];count++){
        scs[count]=(double *)malloc(NPTS_signal*sizeof(double));
        decon[count]=(double *)malloc(2*NPTS_signal*sizeof(double));
        scs_fft_amp[count]=(double *)malloc((NPTS_signal+1)*sizeof(double));
        scs_fft_phase[count]=(double *)malloc((NPTS_signal+1)*sizeof(double));
        scs_divide_amp[count]=(double *)malloc((NPTS_signal+1)*sizeof(double));
        scs_divide_phase[count]=(double *)malloc((NPTS_signal+1)*sizeof(double));
        stnm[count]=(char *)malloc(10*sizeof(char));
    }

    esf=(double *)malloc(NPTS_signal*sizeof(double));
    filled_esf_fft_amp=(double *)malloc((NPTS_signal+1)*sizeof(double));
    filled_esf_fft_phase=(double *)malloc((NPTS_signal+1)*sizeof(double));

    // Read in E.S.F.
    // Taper the edges and find its peak position.
    fp=fopen(PS[ESFfile],"r");
    NPTS_source=0;
    while (fscanf(fp,"%lf%lf",&time,&esf[NPTS_source])==2){
        if ( -20 <= time && time <= 25 ){
            NPTS_source++;
        }
    }
    fclose(fp);

    taperd(esf,NPTS_source,P[Taper_source]);
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
    fp=fopen(PS[infile],"r");
    dosnr=1;
    for (count=0;count<PI[fileN];count++){

        fscanf(fp,"%s%s%lf%lf",stnm[count],ScSfile,&peak,&Nanchor[count]);


        Nanchor[count]-=peak;

        if ( P[C1] > Nanchor[count]+P[N1] ){
            dosnr=0;
        }

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


        // Taper the edges.
        taperd(scs[count],NPTS_signal,P[Taper_signal]);
		// Modified taperd:
// 		taperd_section(scs[count],NPTS_signal,0.5,P[Taper_signal]);

    }
    fclose(fp);


    // Decon.
    waterlevel_decon(scs,PI[fileN],NPTS_signal,esf,NPTS_source,P0,P2,decon,P[waterlevel],P[delta],1,filled_esf_fft_amp,filled_esf_fft_phase,scs_fft_amp,scs_fft_phase,scs_divide_amp,scs_divide_phase);

    // BandPass the decon result.
	butterworth_bp(decon,PI[fileN],2*NPTS_signal,P[delta],2,2,P[filter1],P[filter2],decon);

    for (count=0;count<PI[fileN];count++){

        // Flip it to pulse up.
		// Normalize it to the pulse.
		// peak is searched within a 10 sec. window.
        P4=(int)ceil(5/P[delta]);
        AMP=max_ampd(decon[count]+NPTS_signal-P4,P4*2,&P3);
        shift_array(decon[count],2*NPTS_signal,P4-P3);
        P3+=(NPTS_signal-P4);
        AMP=decon[count][P3];

        AMP=decon[count][NPTS_signal];
        for (count2=0;count2<2*NPTS_signal;count2++){
            decon[count][count2]/=AMP;
        }
    }


    // Output tapered source, shift the peak to time=0.
    sprintf(outfile,"%d.esf",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<NPTS_source;count++){
        fprintf(fpout,"%.4lf\t%.5e\n",(count-P0)*P[delta],esf[count]);
    }
    fclose(fpout);


    // Output tapered signal.
    for (count=0;count<PI[fileN];count++){
        sprintf(outfile,"%s.tapered",stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<NPTS_signal;count2++){
            fprintf(fpout,"%.4lf\t%.5e\n",P[C1]+count2*P[delta],scs[count][count2]);
        }
        fclose(fpout);
    }


    // Output deconed result. (Peak is at the center, t=0)
    for (count=0;count<PI[fileN];count++){
        sprintf(outfile,"%s.trace",stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<2*NPTS_signal;count2++){
            fprintf(fpout,"%.4lf\t%.5e\n",(count2-NPTS_signal)*P[delta],decon[count][count2]);
        }
        fclose(fpout);
    }

	if (PI[MoreInfo]){

		// Output frequency domain information, filled zero-padded esf.
		sprintf(outfile,"%d.filled_fft_amp",PI[cate]);
		fpout=fopen(outfile,"w");
		for (count=0;count<NPTS_signal+1;count++){
			fprintf(fpout,"%.4lf\t%.5e\n",count*df,filled_esf_fft_amp[count]);
		}
		fclose(fpout);


		sprintf(outfile,"%d.filled_fft_phase",PI[cate]);
		fpout=fopen(outfile,"w");
		for (count=0;count<NPTS_signal+1;count++){
			fprintf(fpout,"%.4lf\t%.5e\n",count*df,filled_esf_fft_phase[count]);
		}
		fclose(fpout);


		// Output frequency domain information, zero-padded ScS traces.
		for (count=0;count<PI[fileN];count++){
			sprintf(outfile,"%s.scs_fft_amp",stnm[count]);
			fpout=fopen(outfile,"w");
			for (count2=0;count2<NPTS_signal+1;count2++){
				fprintf(fpout,"%.4lf\t%.5e\n",count2*df,scs_fft_amp[count][count2]);
			}
			fclose(fpout);


			sprintf(outfile,"%s.scs_fft_phase",stnm[count]);
			fpout=fopen(outfile,"w");
			for (count2=0;count2<NPTS_signal+1;count2++){
				fprintf(fpout,"%.4lf\t%.5e\n",count2*df,scs_fft_phase[count][count2]);
			}
			fclose(fpout);
		}

		// Output frequency domain information, divided ScS traces.
		for (count=0;count<PI[fileN];count++){
			sprintf(outfile,"%s.scs_divide_amp",stnm[count]);
			fpout=fopen(outfile,"w");
			for (count2=0;count2<NPTS_signal+1;count2++){
				fprintf(fpout,"%.4lf\t%.5e\n",count2*df,scs_divide_amp[count][count2]);
			}
			fclose(fpout);


			sprintf(outfile,"%s.scs_divide_phase",stnm[count]);
			fpout=fopen(outfile,"w");
			for (count2=0;count2<NPTS_signal+1;count2++){
				fprintf(fpout,"%.4lf\t%.5e\n",count2*df,scs_divide_phase[count][count2]);
			}
			fclose(fpout);
		}
	}


    /****************************
       Do some other estimations.
    ****************************/

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

    for (count=0;count<PI[fileN];count++){

        // Do CCC estimation betweeen the stretched-tapered S esf and ScS traces, first align them at their peak.
        P3=(int)ceil(10/P[delta]);
        P4=(int)ceil(15/P[delta]);
        polarity=scs[count][P2[count]]>0?1:-1;
        CC_positive(scs[count]+P2[count]-P3,P3+P4,esf+P0-P3,P3+P4,&shift,&ccc,polarity);

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

        // Do SNR estimation on deconed trace.


        if ( dosnr==1 ){
            P1=NPTS_signal+(int)((Nanchor[count]+P[N1])/P[delta]);
            P3=NPTS_signal+(int)(P[S1]/P[delta]);
            P4=(int)((P[S2]-P[S1])/P[delta]);
            snr=snr_envelope(decon[count],2*NPTS_signal,P1,(int)((P[N2]-P[N1])/P[delta]),P3,P4);
        }
        else{
            snr=0.0/0.0;
        }

        // Do Adjacent Noise estimation on deconed trace.
        P1=(int)(P[AN]/P[delta]);
        snr_1=snr_envelope(decon[count],2*NPTS_signal,P3-P1,P1,P3,P4);
        snr_2=snr_envelope(decon[count],2*NPTS_signal,P3+P4,P1,P3,P4);

        // Output estimations.
        fprintf(fpout,"%s\t%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf\t%d%11.3lf%11.3lf%11.3lf%11.3lf\n"
        ,stnm[count],snr_1,snr_2,snr,P[delta]*shift,ccc,misfit,PI[cate],Nanchor[count]+P[N1],P[S1],P[S1]-P1*P[delta],P[S2]);

    }
    fclose(fpout);


    /************************
     *  Free spaces.
    ************************/
    for (count=0;count<PI[fileN];count++){
        free(scs[count]);
        free(stnm[count]);
        free(decon[count]);
    }
    free(scs);
    free(stnm);
    free(decon);

    free(esf);
    free(Nanchor);

	free(ts);
	free(ans);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
