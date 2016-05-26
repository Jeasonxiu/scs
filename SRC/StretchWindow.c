#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Stretch S esf to best match ScS esf.
 * Comparison is made above certain level for each esf.
***********************************************************/

int main(int argc,char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {nXStretch,nYStretch,cate};
    enum PSenum {Sesf,ScSesf,Sstretched};
    enum Penum  {C1,C2,H1,H2,V1,V2,AMPlevel};

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
    int    NPTS_Cut,NPTS_ScS_CC;
    FILE   *fpin,*fpout;
    char   outfile[200];
    double time,amp;
    double *esf1_time,*esf1_amp,*esf2_time,*esf2_amp,*esfstretched_time,*ScS_time_CC,*ScS_amp_CC;

    // Points used to resample stretched shape. For CC.
    NPTS_ScS_CC=1000;

    // Count NPTS_Cut.
    NPTS_Cut=0;
    fpin=fopen(PS[Sesf],"r");
    while (fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            NPTS_Cut++;
        }
    }
    fclose(fpin);


    // Spaces for data.
    esf1_time=(double *)malloc(NPTS_Cut*sizeof(double));
    esf1_amp=(double *)malloc(NPTS_Cut*sizeof(double));
    esf2_time=(double *)malloc(NPTS_Cut*sizeof(double));
    esf2_amp=(double *)malloc(NPTS_Cut*sizeof(double));
    esfstretched_time=(double *)malloc(NPTS_Cut*sizeof(double));


	// Space for comparison.
    ScS_time_CC=(double *)malloc(NPTS_ScS_CC*sizeof(double));
    ScS_amp_CC=(double *)malloc(NPTS_ScS_CC*sizeof(double));


    // Read in S and ScS esf.
    count=0;
    fpin=fopen(PS[Sesf],"r");
    while(fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            esf1_time[count]=time;
            esf1_amp[count]=amp;
            count++;
        }
    }
    fclose(fpin);

    count=0;
    fpin=fopen(PS[ScSesf],"r");
    while(fscanf(fpin,"%lf%lf",&time,&amp)==2){
        if (-100.0<time && time<100.0){
            esf2_time[count]=time;
            esf2_amp[count]=amp;
            count++;
        }
    }
    fclose(fpin);

	// Done reading data, begin processing.


    // Find the peaks of two traces. (assumed to be within -10 ~ 20 of t=0 )
    // Normalize/flip two traces according to the peak.
	int Peak1,Peak2;
	double tmpmax;

    tmpmax=0;
    for (count=0;count<NPTS_Cut;count++){
        if ( -10<esf1_time[count] && esf1_time[count]<20 && tmpmax<fabs(esf1_amp[count])){
            tmpmax=fabs(esf1_amp[count]);
            Peak1=count;
        }
    }

	tmpmax*=(esf1_amp[Peak1]>0)?1:-1;
    for (count=0;count<NPTS_Cut;count++){
        esf1_amp[count]/=tmpmax;
    }


    tmpmax=0;
    for (count=0;count<NPTS_Cut;count++){
        if ( -10<esf2_time[count] && esf2_time[count]<20 && tmpmax<fabs(esf2_amp[count])){
            tmpmax=fabs(esf2_amp[count]);
            Peak2=count;
        }
    }

	tmpmax*=(esf2_amp[Peak2]>0)?1:-1;
    for (count=0;count<NPTS_Cut;count++){
        esf2_amp[count]/=tmpmax;
    }




    // Shift time on two esf to align peak at zero.
	double PeakT1,PeakT2;

    PeakT1=esf1_time[Peak1];
    PeakT2=esf2_time[Peak2];

    for (count=0;count<NPTS_Cut;count++){
        esf1_time[count]-=PeakT1;
        esf2_time[count]-=PeakT2;
    }


    // Output shifted original S esf for plotting.
    sprintf(outfile,"plotfile_%d_S_Shifted",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<NPTS_Cut;count++){
        fprintf(fpout,"%.4e\t%.4e\n",esf1_time[count]+PeakT2,esf1_amp[count]);
    }
    fclose(fpout);


	//Find the absolute difference window on ScS.
	int WB,WE;
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

	// Space for S_amp_DIFF.
	int NPTS_DIFF=WE-WB;
	double *S_amp_DIFF=(double *)malloc(NPTS_DIFF*sizeof(double));


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

	// 2. Resample and create target CC trace.

	double dt;

    dt=(esf2_time[ScS_E]-esf2_time[ScS_B])/(NPTS_ScS_CC-1);

    for (count=0;count<NPTS_ScS_CC;count++){
        ScS_time_CC[count]=esf2_time[ScS_B]+count*dt;
    }
    wiginterpd(esf2_time,esf2_amp,NPTS_Cut,ScS_time_CC,ScS_amp_CC,NPTS_ScS_CC,0);

    // 3. Get rid of part below AMPlevel, normalize it.

    for (count=0;count<NPTS_ScS_CC;count++){
        ScS_amp_CC[count]-=P[AMPlevel];
    }
    normalized(ScS_amp_CC,NPTS_ScS_CC);



    // Stretch S, make S_amp_CC,
	// compare it with ScS_amp_CC.

	int count2,count3;
	double dV,dH,V,H,V_max,H_max;
	FILE *fpplot;
	int shift,NPTS_S_CC,OverlapLength;

	double abs_difference,ccc,diff_min,ccc_max,flip,shift_max;
	double *S_time_CC,*S_amp_CC;

    S_time_CC=NULL;
    S_amp_CC=NULL;

	// Step length.
    dH=(P[H2]-P[H1])/(PI[nXStretch]-1);
    dV=(P[V2]-P[V1])/(PI[nYStretch]-1);


	// Begin stretch loop, vertical first.


	diff_min=1/0.0;
	V_max=P[V1];
	H_max=P[H1];

    sprintf(outfile,"Stretch_Info.%d",PI[cate]);
    fpout=fopen(outfile,"w");

	for (count=0;count<PI[nYStretch];count++){

		V=P[V1]+count*dV;

		// Stretch S vertically.

		for (count2=0;count2<NPTS_Cut;count2++){
			esf1_amp[count2]=(esf1_amp[count2]+V)/(1+V);
		}

		// Make ScS comparison part (target).

		// 1. Down-hill search ScS AMP level.

		int S_B=0,S_E=NPTS_Cut;

		for (count2=Peak1;count2>0;count2--){
			if (esf1_amp[count2]<P[AMPlevel]){
				S_B=count2;
				break;
			}
		}


		for (count2=Peak1;count2<NPTS_Cut;count2++){
			if (esf1_amp[count2]<P[AMPlevel]){
				S_E=count2;
				break;
			}
		}


		// Begin Horizontal stretch loop.

		for (count2=0;count2<PI[nXStretch];count2++){

			H=P[H1]+count2*dH;

			// stretch time axis.
			for (count3=0;count3<NPTS_Cut;count3++){
				esfstretched_time[count3]=H*esf1_time[count3];
			}


			// print out the lowest and highest stretch result for plot.
			if ( ( count==0 && count2==0) ||
				 ( count==0 && count2==PI[nXStretch]-1 ) ||
				 ( count==PI[nYStretch]-1 && count2==0 ) ||
				 ( count==PI[nYStretch]-1 && count2==PI[nXStretch]-1 ) ){

				sprintf(outfile,"tmpfile_%d_%d_%d.Sstretch",PI[cate],count+1,count2+1);
				fpplot=fopen(outfile,"w");
				for (count3=0;count3<NPTS_Cut;count3++){
					fprintf(fpplot,"%.4e\t%.4e\n",esfstretched_time[count3]+PeakT2,esf1_amp[count3]);
				}
				fclose(fpplot);
			}

			// 2. Resample and create S CC trace.

			NPTS_S_CC=(int)ceil((esfstretched_time[S_E]-esfstretched_time[S_B])/dt);

			free(S_time_CC);free(S_amp_CC);
			S_time_CC=(double *)malloc(NPTS_S_CC*sizeof(double));
			S_amp_CC=(double *)malloc(NPTS_S_CC*sizeof(double));

			for (count3=0;count3<NPTS_S_CC;count3++){
				S_time_CC[count3]=esfstretched_time[S_B]+count3*dt;
			}
			wiginterpd(esfstretched_time,esf1_amp,NPTS_Cut,S_time_CC,S_amp_CC,NPTS_S_CC,1);


			// 2'. Create S DIFF trace.
			wiginterpd(esfstretched_time,esf1_amp,NPTS_Cut,esf2_time+WB,S_amp_DIFF,WE-WB,1);


			// 3. Get rid of part below AMPlevel, normalize it.

			for (count3=0;count3<NPTS_S_CC;count3++){
				S_amp_CC[count3]-=P[AMPlevel];
			}
			normalized(S_amp_CC,NPTS_S_CC);



			// Compare two CC trace by absolute difference
			// frist find the shift,
			// then accumulate the absolute difference.

			// 1. find the shift.

			CC(S_amp_CC,NPTS_S_CC,ScS_amp_CC,NPTS_ScS_CC,&shift,&ccc);


			// 1'. Adjust shift time to compare begin.
			shift+=(int)ceil((esfstretched_time[S_B]-esf2_time[ScS_B])/dt);


			// 2. find accumulative abs difference.

			abs_difference=0;
			OverlapLength=NPTS_DIFF-abs(shift);
			if (shift>=0){
				for(count3=0;count3<OverlapLength;count3++){
					abs_difference+=fabs(S_amp_DIFF[count3+shift]-esf2_amp[WB+count3]);
				}
			}
			else {
				for(count3=0;count3<OverlapLength;count3++){
					abs_difference+=fabs(S_amp_DIFF[count3]-esf2_amp[WB-shift+count3]);
				}
			}


			// 3. Judge if this stretch is best fit or not.

			if (diff_min>abs_difference/OverlapLength){

			    diff_min=abs_difference/OverlapLength;
				ccc_max=fabs(ccc);
				H_max=H;
				V_max=V;
				shift_max=shift*dt;

				flip=ccc>0?1:-1;
			}

			fprintf(fpout,"%.4lf\t%.4lf\t%.6lf\t%.6lf\t%.6lf\n",H,V,fabs(ccc),shift*dt,abs_difference/OverlapLength);

		} // End of loop count2, horizontal stretch.

		// Vertical Stretch S back to original esf1_amp.

		for (count2=0;count2<NPTS_Cut;count2++){
			esf1_amp[count2]=esf1_amp[count2]*(1+V)-V;
		}


	} // End of loop count, vertical stretch.

    fprintf(fpout,"%.4lf\t%.4lf\t%.6lf\t%.6lf\t%.6lf\n",H_max,V_max,ccc_max,shift_max,diff_min);
	fclose(fpout);


    // Create Stretched S esf (-25 sec. ~ 25 sec.).
	int NPTS_S_Stretch=(int)ceil(50/0.025);
	double *esf_time,*esf_amp;

    esf_time=(double *)malloc(NPTS_S_Stretch*sizeof(double));
    esf_amp=(double *)malloc(NPTS_S_Stretch*sizeof(double));

    for (count=0;count<NPTS_S_Stretch;count++){
        esf_time[count]=-25+count*0.025;
    }

    // Stretch S according to best stretch.
    for (count=0;count<NPTS_Cut;count++){
        esfstretched_time[count]=H_max*esf1_time[count];
    }
	for (count=0;count<NPTS_Cut;count++){
		esf1_amp[count]=(esf1_amp[count]+V_max)/(1+V_max);
	}
    wiginterpd(esfstretched_time,esf1_amp,NPTS_Cut,esf_time,esf_amp,NPTS_S_Stretch,1);


	// Output best Stretched ESW !
	fpout=fopen(PS[Sstretched],"w");
	for (count=0;count<NPTS_S_Stretch;count++){
		fprintf(fpout,"%.4e\t%.4e\n",esf_time[count]+PeakT2,flip*esf_amp[count]);
	}
	fclose(fpout);


    // Free spaces.
    free(esf1_time);
    free(esf2_time);
    free(esf_time);
    free(esf1_amp);
    free(esf2_amp);
    free(esf_amp);
    free(esfstretched_time);

	free(S_amp_DIFF);

    free(S_time_CC);
    free(ScS_time_CC);
    free(S_amp_CC);
    free(ScS_amp_CC);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
