#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Tstar S esf to best match ScS esf.
 * Comparison is made above certain level for each esf.
***********************************************************/

int main(int argc,char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {nStretch,cate};
    enum PSenum {Sesf,ScSesf,Sstretched,Original,InfoOut,Mark};
    enum Penum  {C1,C2,R1,R2,AMPlevel,Vlevel};

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
    int    NPTS_Cut;
    FILE   *fpin,*fpout;
    char   outfile[200];
    double PeakT1,PeakT2,time,amp,tmpmax;
    double *esf1_time,*esf1_amp,*esf2_time,*esf2_amp;


    // Count NPTS_Cut.
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
    count=0;
    while(fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            esf1_time[count]=time;
            esf1_amp[count]=amp;
            count++;
        }
    }
    fclose(fpin);

    fpin=fopen(PS[ScSesf],"r");
    count=0;
    while(fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            esf2_time[count]=time;
            esf2_amp[count]=amp;
            count++;
        }
    }
    fclose(fpin);



    // Find the peaks of two traces. (should be lies within -10 ~ 20 of t=0 )
    // 1. Normlize two traces according to the peak.

	int Peak1,Peak2;

    tmpmax=0;
    for (count=0;count<NPTS_Cut;count++){
        if ( -10<esf1_time[count] && esf1_time[count]<20 && tmpmax<fabs(esf1_amp[count])){
            tmpmax=fabs(esf1_amp[count]);
            Peak1=count;
        }
    }
    for (count=0;count<NPTS_Cut;count++){
        esf1_amp[count]/=tmpmax;
    }

    tmpmax=0;
    for (count=0;count<NPTS_Cut;count++){
        if ( -10<esf1_time[count] && esf2_time[count]<20 && tmpmax<fabs(esf2_amp[count])){
            tmpmax=fabs(esf2_amp[count]);
            Peak2=count;
        }
    }
    for (count=0;count<NPTS_Cut;count++){
        esf2_amp[count]/=tmpmax;
    }


    // 2. Shift time on two esf to align peak at t=0.
    PeakT1=esf1_time[Peak1];
    PeakT2=esf2_time[Peak2];
    for (count=0;count<NPTS_Cut;count++){
        esf1_time[count]-=PeakT1;
        esf2_time[count]-=PeakT2;
    }



    // Output shifted original S esf for plotting. (overlap its peak with ScS esf peak)
    sprintf(outfile,"plotfile_%d_S_Shifted",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<NPTS_Cut;count++){
        fprintf(fpout,"%.4e\t%.4e\n",esf1_time[count]+PeakT2,esf1_amp[count]);
    }
    fclose(fpout);


	//Find the absolute difference window on ScS.
	int WB,WE,NPTS_DIFF;
    for (count=0;count<NPTS_Cut;count++){
		if (esf2_time[count]>P[C1]){
			WB=count;
			break;
		}
    }
    for (count=0;count<NPTS_Cut;count++){
		if (esf2_time[count]>P[C2]){
			WE=count;
			break;
		}
    }
	NPTS_DIFF=WE-WB;


	// Make ScS comparison part (target).

	// 1. Down-hill search ScS AMP level.

	int ScS_B=0,ScS_E=NPTS_Cut;

    for (count=Peak2;count>0;count--){
        if (esf2_amp[count]<P[AMPlevel]){
            ScS_B=count;
            break;
        }
    }

    for (count=Peak2;count<NPTS_Cut;count++){
        if (esf2_amp[count]<P[AMPlevel]){
            ScS_E=count;
            break;
        }
    }

	// 2. Interpolate to get value.
    // & Get rid of part below AMPlevel, normalize it.

	int NPTS_ScS_CC=1000;
	double *ScS_amp_CC,*ScS_time_CC;
	double dt_CC;

	dt_CC=(esf2_time[ScS_E]-esf2_time[ScS_B])/(NPTS_ScS_CC-1);

	ScS_amp_CC=(double *)malloc(NPTS_ScS_CC*sizeof(double));
	ScS_time_CC=(double *)malloc(NPTS_ScS_CC*sizeof(double));

	for (count=0;count<NPTS_ScS_CC;count++){
		ScS_time_CC[count]=esf2_time[ScS_B]+dt_CC*count;
	}

    wiginterpd(esf2_time,esf2_amp,NPTS_Cut,ScS_time_CC,ScS_amp_CC,NPTS_ScS_CC,0);

	for (count=0;count<NPTS_ScS_CC;count++){
		ScS_amp_CC[count]-=P[AMPlevel];
	}

    normalized(ScS_amp_CC,NPTS_ScS_CC);



    // Stretch S vertically.
    for (count=0;count<NPTS_Cut;count++){
        esf1_amp[count]=(esf1_amp[count]+P[Vlevel])/(1+P[Vlevel]);
    }


	// Tstar on S begin.

	int    count2,NPTS_tstar=8000,shift,NPTS_S_CC,S_B,S_E;
	double dts,*ts;
	double *tstarred,*tstar_time;
	int    Peaktmp,NPTS_S,flip,OverlapLength;
	FILE   *fpplot,*fpout2;
	double dt,dl,ccc,ccc_max,diff_min,abs_difference,dl_max,shift_max;
	double *S_time_CC=NULL,*S_amp_CC=NULL;



	// Sampling rate of input esf.
	dt=esf1_time[1]-esf1_time[0];

	// Use -30 ~ 30 sec of S esf into Tstar operator.
	NPTS_S=(int)(60/dt);


	// Make spaces for tstar operator.
	ts=(double *)malloc(NPTS_tstar*sizeof(double));
	tstarred=(double *)malloc((NPTS_tstar+NPTS_S-1)*sizeof(double));
	tstar_time=(double *)malloc((NPTS_tstar+NPTS_S-1)*sizeof(double));


	// Output original "S" esf (used for ScS get Tstarred case). peak at t=0;
	fpout=fopen(PS[Original],"w");
	for (count=0;count<NPTS_S;count++){
		fprintf(fpout,"%.4e\t%.4e\n",(count-NPTS_S/2)*dt,esf2_amp[Peak2-NPTS_S/2+count]);
	}
	fclose(fpout);



    // Step length.
    dts=(P[R2]-P[R1])/(PI[nStretch]-1);


    // TstarStretch S and compare it with ScS_amp_CC.
    fpout=fopen(PS[InfoOut],"w");
    diff_min=1/0.0;

    for (count=0;count<PI[nStretch];count++){


        // Tstar Value.
        dl=P[R1]+dts*count;


		// Operate Tstar on S esf.
		tstar(dt,NPTS_tstar,dl,ts);
		convolve(esf1_amp+Peak1-NPTS_S/2,ts,NPTS_S,NPTS_tstar,tstarred);
		normalized(tstarred,NPTS_tstar+NPTS_S-1);


		// Find peak on the T starred trace.
		max_ampd(tstarred,NPTS_tstar+NPTS_S-1,&Peaktmp);


		// print out the lowest and highest stretch result for plot. ( just simply overlap its peak with ScS esf peak)
		if ( count==0  || count==PI[nStretch]-1 ){

			sprintf(outfile,"tmpfile_%d_%d.Tstarred",PI[cate],count+1);
			fpplot=fopen(outfile,"w");
			for (count2=0;count2<NPTS_S;count2++){
				fprintf(fpplot,"%.4e\t%.4e\n",(count2-NPTS_S/2)*dt+PeakT2,tstarred[Peaktmp+count2-NPTS_S/2]);
			}
			fclose(fpplot);

		}


		// Down-hill search the AMPlevel point on tstared S. (S_B----S_E)

		S_B=0;
		for (count2=Peaktmp;count2>0;count2--){
			if (tstarred[count2]<P[AMPlevel]){
				S_B=count2;
				break;
			}
		}

		S_E=NPTS_tstar+NPTS_S-1;
		for (count2=Peaktmp;count2<NPTS_tstar+NPTS_S-1;count2++){
			if (tstarred[count2]<P[AMPlevel]){
				S_E=count2;
				break;
			}
		}


		// Set time axis for tstarred trace.
		for (count2=0;count2<NPTS_tstar+NPTS_S-1;count2++){
			tstar_time[count2]=dt*(count2-S_B);
		}


		// Make S comparison part.
		// & Get rid of part below AMPlevel, normalize it.
		free(S_amp_CC);
		free(S_time_CC);

		NPTS_S_CC=(int)ceil((S_E-S_B)*dt/dt_CC);
		S_time_CC=(double *)malloc(NPTS_S_CC*sizeof(double));
		S_amp_CC=(double *)malloc(NPTS_S_CC*sizeof(double));

		for (count2=0;count2<NPTS_S_CC;count2++){
			S_time_CC[count2]=dt_CC*count2;
		}

		wiginterpd(tstar_time,tstarred,NPTS_tstar+NPTS_S-1,S_time_CC,S_amp_CC,NPTS_S_CC,0);

		for (count2=0;count2<NPTS_S_CC;count2++){
			S_amp_CC[count2]-=P[AMPlevel];
		}

		normalized(S_amp_CC,NPTS_S_CC);


        // Compare them by absolute difference:
		// find the shift using CC, then accumulate the absolute difference.

        CC(S_amp_CC,NPTS_S_CC,ScS_amp_CC,NPTS_ScS_CC,&shift,&ccc);


		// 1'. Adjust shift time to compare begin.
		shift*=(dt_CC/dt);
		shift+=(Peak2-ScS_B-Peaktmp+S_B);


        abs_difference=0;
		OverlapLength=NPTS_DIFF-abs(shift);
        if (shift>=0){
            for(count2=0;count2<OverlapLength;count2++){
                abs_difference+=fabs(tstarred[Peaktmp+(int)ceil(P[C1]/dt)+count2+shift]-esf2_amp[WB+count2]);
            }
        }
        else {
            for(count2=0;count2<OverlapLength;count2++){
                abs_difference+=fabs(tstarred[Peaktmp+(int)ceil(P[C1]/dt)+count2]-esf2_amp[WB+count2-shift]);
            }
        }

		// 3. Judge if this tstar is best fit or not.

        if (diff_min>abs_difference/OverlapLength){
            diff_min=abs_difference/OverlapLength;
            ccc_max=fabs(ccc);
            dl_max=dl;
            flip=ccc>0?1:-1;
            shift_max=shift*dt;


			// Notedown current winner.
			fpout2=fopen(PS[Sstretched],"w");
			for (count2=0;count2<NPTS_S;count2++){
				fprintf(fpout2,"%.4e\t%.4e\n",(count2-NPTS_S/2)*dt+PeakT2,flip*tstarred[Peaktmp-NPTS_S/2+count2]);
			}
			fclose(fpout2);
        }

        fprintf(fpout,"%.4lf\t%.6lf\t%.6lf\t%.6lf\n",dl,fabs(ccc),shift*dt,abs_difference/OverlapLength);
    }

    fprintf(fpout,"%.4lf\t%.6lf\t%.6lf\t%.6lf\n",dl_max,ccc_max,shift_max,diff_min);

    fclose(fpout);

	if (dl_max!=P[R1]){
		fpout=fopen(PS[Mark],"w");
		fprintf(fpout,"%s\n",PS[Mark]);
		fclose(fpout);
	}

    // Free spaces.
    free(esf1_time);
    free(esf2_time);
    free(esf1_amp);
    free(esf2_amp);

    free(S_amp_CC);
    free(ScS_amp_CC);
	free(ts);
	free(tstarred);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
