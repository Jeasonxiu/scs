#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Tstar S/ScS esf to best match ScS/S esf.
 * comparison position is decided by portion above certain
 * amplitude level.
 * then comparison value is decided by comparing within certain
 * time window.
***********************************************************/

int main(int argc,char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {nXStretch,nYStretch,cate};
    enum PSenum {Sesf,ScSesf,NewESW,NewScS,InfoOut,plotfile,InfoBest};
    enum Penum  {C1,C2,R1,R2,V1,V2,AMPlevel,delta};

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

	// Step 1. Read in two ESW traces.
    int    NPTS_Cut;
    FILE   *fpin;
    double time,amp;
    double *esf1_time,*esf1_amp,*esf2_time,*esf2_amp;


    // Count NPTS_Cut. (read in only t = -100 ~ 100 sec.)
    fpin=fopen(PS[Sesf],"r");
    NPTS_Cut=0;
    while (fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            NPTS_Cut++;
        }
    }
    fclose(fpin);


    // Malloc spaces.
    esf1_time=(double *)malloc(NPTS_Cut*sizeof(double));
    esf1_amp=(double *)malloc(NPTS_Cut*sizeof(double));
    esf2_time=(double *)malloc(NPTS_Cut*sizeof(double));
    esf2_amp=(double *)malloc(NPTS_Cut*sizeof(double));



    // Read in S and ScS esf fullstack. ( only between -100 ~ 100 sec. )
    fpin=fopen(PS[Sesf],"r");
	for (count=0;count<NPTS_Cut;){
		fscanf(fpin,"%lf%lf",&esf1_time[count],&esf1_amp[count]);
        if (-100.0<esf1_time[count] && esf1_time[count]<100.0){
            count++;
        }
    }
    fclose(fpin);

    fpin=fopen(PS[ScSesf],"r");
	for (count=0;count<NPTS_Cut;){
		fscanf(fpin,"%lf%lf",&esf2_time[count],&esf2_amp[count]);
        if (-100.0<esf2_time[count] && esf2_time[count]<100.0){
            count++;
        }
    }
    fclose(fpin);


    // Step 2. Pre-process two traces.

	// Find their peaks within t = -10 ~ 20.
	int Peak1,Peak2,PeakWB=(int)(90/P[delta]),PeakWL=(int)(30/P[delta]),flip1,flip2;
	double PeakT1,PeakT2,NormalizeFactor1,NormalizeFactor2;

	flip1=max_ampd(esf1_amp+PeakWB,PeakWL,&Peak1);
	Peak1+=PeakWB;
    PeakT1=esf1_time[Peak1];

	flip2=max_ampd(esf2_amp+PeakWB,PeakWL,&Peak2);
	Peak2+=PeakWB;
    PeakT2=esf1_time[Peak2];

    // Normlize two traces according to the peak amplitude.
    // Shift time on two esf to make their peaks at t=0.
    NormalizeFactor1=esf1_amp[Peak1]*flip1;
    NormalizeFactor2=esf2_amp[Peak2]*flip2;
    for (count=0;count<NPTS_Cut;count++){
        esf1_amp[count]/=NormalizeFactor1;
        esf2_amp[count]/=NormalizeFactor2;
        esf1_time[count]-=PeakT1;
        esf2_time[count]-=PeakT2;
    }



	// Step 3. Spaces for tstar operator.
	int NPTS_tstar=8000,NPTS_run;
	double *ts,*tstar_amp,*tstar_time;

	// Will convovle tstar with t = -30 ~ 30 sec of running esf.
	NPTS_run=(int)(60/P[delta]);

	// Make spaces for tstar operator.
	ts=(double *)malloc(NPTS_tstar*sizeof(double));
	tstar_amp=(double *)malloc((NPTS_tstar+NPTS_run-1)*sizeof(double));
	tstar_time=(double *)malloc((NPTS_tstar+NPTS_run-1)*sizeof(double));



	// Step 4. Begin Stretching process.
	// (vertical stretch only on S)

	FILE *fpout=fopen(PS[InfoOut],"w");
	double dTs,dV,V,Ts,MinDiff=1/0.0;

    dTs=(P[R2]-P[R1])/(PI[nXStretch]-1);
    dV=(P[V2]-P[V1])/(PI[nYStretch]-1);

	for (count=0;count<PI[nYStretch];count++){

		V=P[V1]+count*dV;

		int count2;

		// Stretch S vertically.
		for (count2=0;count2<NPTS_Cut;count2++){
			esf1_amp[count2]=(esf1_amp[count2]+V)/(1+V);
		}

		for (count2=0;count2<PI[nXStretch];count2++){

			Ts=P[R1]+count2*dTs;

			int count3;


			double *fix_time=(Ts<0?esf1_time:esf2_time);
			double *run_time=(Ts>=0?esf1_time:esf2_time);

			double *fix_amp=(Ts<0?esf1_amp:esf2_amp);
			double *run_amp=(Ts>=0?esf1_amp:esf2_amp);

			int fix_peak=(Ts<0?Peak1:Peak2);
			int run_peak=(Ts>=0?Peak1:Peak2);

			double fix_peak_time=(Ts<0?PeakT2:PeakT1);


			// Step 5. Define the absolute difference window.
			// Find the window on the non-tstar trace.
			int WB,WE,NPTS_DIFF;

			for (count3=0;count3<NPTS_Cut;count3++){
				if (fix_time[count3]>P[C1]){
					WB=count3;
					break;
				}
			}
			for (count3=0;count3<NPTS_Cut;count3++){
				if (fix_time[count3]>P[C2]){
					WE=count3;
					break;
				}
			}

			NPTS_DIFF=WE-WB;


			// Step 6. Make target CC trace.
			// (above certain amplitude level)


			// 1. Down-hill search fix trace AMP level position.

			int fix_B=0,fix_E=NPTS_Cut;

			for (count3=fix_peak;count3>0;count3--){
				if (fix_amp[count3]<P[AMPlevel]){
					fix_B=count3;
					break;
				}
			}

			for (count3=fix_peak;count3<NPTS_Cut;count3++){
				if (fix_amp[count3]<P[AMPlevel]){
					fix_E=count3;
					break;
				}
			}

			// 2. First Use interpolation to get target CC amp value.
			// then get rid of part below AMPlevel and then normalize peak to 1.

			int NPTS_fix_CC=1000;
			double *fix_amp_CC,*fix_time_CC;
			double dt_CC;

			dt_CC=(fix_time[fix_E]-fix_time[fix_B])/(NPTS_fix_CC-1);

			fix_amp_CC=(double *)malloc(NPTS_fix_CC*sizeof(double));
			fix_time_CC=(double *)malloc(NPTS_fix_CC*sizeof(double));

			for (count3=0;count3<NPTS_fix_CC;count3++){
				fix_time_CC[count3]=fix_time[fix_B]+dt_CC*count3;
			}

			wiginterpd(fix_time,fix_amp,NPTS_Cut,fix_time_CC,fix_amp_CC,NPTS_fix_CC,0);

			for (count3=0;count3<NPTS_fix_CC;count3++){
				fix_amp_CC[count3]-=P[AMPlevel];
			}

			normalized(fix_amp_CC,NPTS_fix_CC);

			free(fix_time_CC);


			// Step 7. Operate Tstar on running esf.
			tstar(P[delta],NPTS_tstar,fabs(Ts),ts);
			convolve(run_amp+run_peak-NPTS_run/2,ts,NPTS_run,NPTS_tstar,tstar_amp);
			normalized(tstar_amp,NPTS_tstar+NPTS_run-1);

			// Find peak on the T starred trace.
			int TstarPeak;
			max_ampd(tstar_amp,NPTS_tstar+NPTS_run-1,&TstarPeak);


			// print out the stretch boundary result for ploting. ( overlap running peak with ScS esf peak)
			FILE *fpplot;
			char outfile[200];

			if ( ( count==0 && count2==0) ||
				 ( count==0 && count2==PI[nXStretch]-1 ) ||
				 ( count==PI[nYStretch]-1 && count2==0 ) ||
				 ( count==PI[nYStretch]-1 && count2==PI[nXStretch]-1 ) ){

				sprintf(outfile,"plotfile_%d_%d_%d.Tstarred",PI[cate],count+1,count2+1);
				fpplot=fopen(outfile,"w");
				for (count3=0;count3<NPTS_run;count3++){
					fprintf(fpplot,"%.4e\t%.4e\n",(count3-NPTS_run/2)*P[delta]+fix_peak_time,tstar_amp[TstarPeak+count3-NPTS_run/2]);
				}
				fclose(fpplot);

			}


			// Step 8. Make compare CC trace.
			// (above certain amplitude level)

			// 1. Down-hill search running (tstared) trace AMP level position.

			int run_B=0,run_E=NPTS_tstar+NPTS_run-1;

			for (count3=TstarPeak;count3>0;count3--){
				if (tstar_amp[count3]<P[AMPlevel]){
					run_B=count3;
					break;
				}
			}

			for (count3=TstarPeak;count3<NPTS_tstar+NPTS_run-1;count3++){
				if (tstar_amp[count3]<P[AMPlevel]){
					run_E=count3;
					break;
				}
			}


			if (run_B==run_E){ // If tstar is too dramatic.

				fprintf(fpout,"%.4lf\t%.4lf\t%.6lf\t%.6lf\t%.6lf\n",Ts,V,0.5,0.0,1.0);
				continue;

			}


			// 2. First Use interpolation to get running CC amp value, make sampling rate the same as fix_CC.
			// then get rid of part below AMPlevel and then normalize peak to 1.

			double *run_time_CC,*run_amp_CC;
			int NPTS_run_CC=(int)ceil((run_E-run_B)*P[delta]/dt_CC);

			run_time_CC=(double *)malloc(NPTS_run_CC*sizeof(double));
			run_amp_CC=(double *)malloc(NPTS_run_CC*sizeof(double));

			// Set time axis for tstared trace for interpolation. (run_B=0)
			for (count3=0;count3<NPTS_tstar+NPTS_run-1;count3++){
				tstar_time[count3]=P[delta]*(count3-run_B);
			}

			for (count3=0;count3<NPTS_run_CC;count3++){
				run_time_CC[count3]=dt_CC*count3;
			}

			wiginterpd(tstar_time,tstar_amp,NPTS_tstar+NPTS_run-1,run_time_CC,run_amp_CC,NPTS_run_CC,0);

			for (count3=0;count3<NPTS_run_CC;count3++){
				run_amp_CC[count3]-=P[AMPlevel];
			}

			normalized(run_amp_CC,NPTS_run_CC);

			free(run_time_CC);


			// Step 9. Find the proper shift using CC.

			double ccc;
			int shift;
			CC(run_amp_CC,NPTS_run_CC,fix_amp_CC,NPTS_fix_CC,&shift,&ccc);

			free(run_amp_CC);
			free(fix_amp_CC);


			// Adjust shift time to compare begin (let's output two traces peak-aligned).
			shift*=(dt_CC/P[delta]);
			shift+=(fix_peak-fix_B-TstarPeak+run_B);


			// Step 10. Find absolute difference.
			double abs_difference=0;
			int OverlapLength;
			OverlapLength=NPTS_DIFF-abs(shift);
			if (shift>=0){
				for(count3=0;count3<OverlapLength;count3++){
					abs_difference+=fabs(tstar_amp[TstarPeak+(int)ceil(P[C1]/P[delta])+count3+shift]-fix_amp[WB+count3]);
				}
			}
			else {
				for(count3=0;count3<OverlapLength;count3++){
					abs_difference+=fabs(tstar_amp[TstarPeak+(int)ceil(P[C1]/P[delta])+count3]-fix_amp[WB+count3-shift]);
				}
			}

			fprintf(fpout,"%.4lf\t%.4lf\t%.6lf\t%.6lf\t%.6lf\n",Ts,V,fabs(ccc),shift*P[delta],abs_difference/OverlapLength);

			// Step 11. Judge if this tstar is best fit or not.

			FILE *fpout2;
			if (MinDiff>abs_difference/OverlapLength){

				MinDiff=abs_difference/OverlapLength;


				// Notedown current Stretch winner.
				if (Ts>=0){
					fpout2=fopen(PS[NewESW],"w");
					for (count3=0;count3<NPTS_run;count3++){
						fprintf(fpout2,"%.4e\t%.4e\n",(count3-NPTS_run/2)*P[delta]+fix_peak_time,tstar_amp[TstarPeak-NPTS_run/2+count3]);
					}
					fclose(fpout2);
				}
				else{

					// tstarred ScS.
					fpout2=fopen(PS[NewScS],"w");
					for (count3=0;count3<NPTS_run;count3++){
						fprintf(fpout2,"%.4e\t%.4e\n",(count3-NPTS_run/2)*P[delta]+fix_peak_time,tstar_amp[TstarPeak-NPTS_run/2+count3]);
					}
					fclose(fpout2);

					// orginal S as the ESW.
					fpout2=fopen(PS[NewESW],"w");
					for (count3=0;count3<NPTS_run;count3++){
						fprintf(fpout2,"%.4e\t%.4e\n",(count3-NPTS_run/2)*P[delta],fix_amp[fix_peak-NPTS_run/2+count3]);
					}
					fclose(fpout2);
				}


				// Output shifted running esf for plotting. (overlap its peak with fixed esf peak)
				fpout2=fopen(PS[plotfile],"w");
				for (count3=0;count3<NPTS_Cut;count3++){
					fprintf(fpout2,"%.4e\t%.4e\n",run_time[count3]+fix_peak_time,run_amp[count3]);
				}
				fclose(fpout2);


				// Output Best fit information.
				fpout2=fopen(PS[InfoBest],"w");
				fprintf(fpout2,"%.4lf\t%.4lf\t%.6lf\t%.6lf\t%.6lf\n",Ts,V,fabs(ccc),shift*P[delta],MinDiff);
				fclose(fpout2);

			} // End of Best fit judgement.


		} // Done Ts Stretch loop.


		// Vertical Stretch S back to original esf1_amp.
		for (count2=0;count2<NPTS_Cut;count2++){
			esf1_amp[count2]=esf1_amp[count2]*(1+V)-V;
		}


	} // Done Vertical Stretch loop.

	fclose(fpout);

    // Free spaces.
    free(esf1_time);
    free(esf2_time);
    free(esf1_amp);
    free(esf2_amp);

	free(ts);
	free(tstar_amp);
	free(tstar_time);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
