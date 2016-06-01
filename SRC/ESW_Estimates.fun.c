#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

// 4 functions:
// EvaluateSNR
// Misfit
// MakeNorm
// NoiseFreq

void EvaluateSNR(struct Data *p){

	/**********************************************
	 * This C function evaluate SNR for each trace.
	**********************************************/

    int  count;
    for (count=0;count<p->fileN;count++){
        p->snr[count]=snr_envelope(p->data[count],p->dlen,p->naloc[count]+p->nloc,p->Nlen,p->ppeak[count]+p->sloc,p->Slen);
    }

    return;
}


void Misfit(struct Data *p){

	/************************************************
	 * This C function make misfit difference defined
	 * as the comparison of half-height/peak-to-zero
	 * width/area-under-curve in time domain between
	 * ESW and each trace:
	 * misfit=(trace-esf)/esf
	************************************************/

    int    count,count2,H1,H2,tmpP,width;
    double AMP,Sum_ESW,Sum_Trace;
	char *DATAFILE="tmpfile_MISFIT";
	double S_misfit_esw[4];
	FILE *fpin;

	if (strcmp(p->PHASE,"ScS")==0){
		fpin=fopen(DATAFILE,"r");
		for (count=0;count<4;count++){
			fscanf(fpin,"%lf",&S_misfit_esw[count]);
		}
		fclose(fpin);
	}


	// Step1. For half-height esitmation.

    // Find half-height on ESW.
    max_ampd(p->stack+p->stack_p+p->eloc,p->Elen,&tmpP);
    tmpP+=p->stack_p+p->eloc;
    AMP=fabs(p->stack[tmpP]);
    for (H1=tmpP;H1>p->stack_p+p->eloc;H1--){
        if (fabs(p->stack[H1])<0.5*AMP){
            break;
        }
    }
    for (H2=tmpP;H2<p->stack_p+p->eloc+p->Elen;H2++){
        if (fabs(p->stack[H2])<0.5*AMP){
            break;
        }
    }
    width=H2-H1;
	p->misfit_esw=width*p->delta;

    // Area above half-height on ESW.
    Sum_ESW=0;
    for (count=H1;count<=H2;count++){
        Sum_ESW+=fabs(p->stack[count]);
    }
	Sum_ESW-=(H2-H1)*fabs(p->stack[H1]);
	p->misfit2_esw=Sum_ESW;

	// use the same criteria as S.
	if (strcmp(p->PHASE,"ScS")==0){
		width=(int)(S_misfit_esw[0]/p->delta);
		Sum_ESW=S_misfit_esw[1];
	}




    for (count=0;count<p->fileN;count++){

        // Find half-height on traces.
        tmpP=p->ppeak[count];
        AMP=fabs(p->data[count][tmpP]);
        for (count2=tmpP;count2>p->ploc[count]+p->eloc;count2--){
            if (fabs(p->data[count][count2])<0.5*AMP){
                H1=count2;
                break;
            }
        }
        for (count2=tmpP;count2<p->ploc[count]+p->eloc+p->Elen;count2++){
            if (fabs(p->data[count][count2])<0.5*AMP){
                H2=count2;
                break;
            }
        }

        // Area above half-height on traces.
        Sum_Trace=0;
        for (count2=H1;count2<=H2;count2++){
            Sum_Trace+=fabs(p->data[count][count2]);
        }
        Sum_Trace-=(H2-H1)*fabs(p->data[count][H1]);

        // Record Measurements.
        p->misfit[count]=(1.0*(H2-H1)/width)-1.0;
        p->misfit2[count]=Sum_Trace/Sum_ESW-1;
		p->M1_B[count]=H1*p->delta+p->C1;
		p->M1_E[count]=H2*p->delta+p->C1;

    }

	// Step2. Do the same thing for the peak-to-zero.

	// Find zero position on ESW.
	max_ampd(p->stack+p->stack_p+p->eloc,p->Elen,&tmpP);
	tmpP+=p->stack_p+p->eloc;
	for (H1=tmpP;H1>p->stack_p+p->eloc;H1--){
		if (p->stack[H1]*p->stack[H1-1]<=0){
			break;
		}
	}
	for (H2=tmpP;H2<p->stack_p+p->eloc+p->Elen;H2++){
		if (p->stack[H2]*p->stack[H2-1]<=0){
			break;
		}
	}
	width=H2-H1;
	p->misfit3_esw=width*p->delta;

	// Area under curve on ESW.
	Sum_ESW=0;
	for (count=H1;count<=H2;count++){
		Sum_ESW+=fabs(p->stack[count]);
	}
	Sum_ESW-=(H2-H1)*fabs(p->stack[H1]);
	p->misfit4_esw=Sum_ESW;

	// use the same criteria as S.
	if (strcmp(p->PHASE,"ScS")==0){
		width=(int)(S_misfit_esw[2]/p->delta);
		Sum_ESW=S_misfit_esw[3];
	}


	for (count=0;count<p->fileN;count++){

		// Find zero-crossing on traces.
		for (H1=p->ppeak[count];H1>p->ploc[count]+p->eloc;H1--){
			if (p->data[count][H1]*p->data[count][H1-1]<=0){
				break;
			}
		}
		for (H2=p->ppeak[count];H2<p->ploc[count]+p->eloc+p->Elen;H2++){
			if (p->data[count][H2]*p->data[count][H2-1]<=0){
				break;
			}
		}

		// Area above half-height on traces.
		Sum_Trace=0;
		for (count2=H1;count2<=H2;count2++){
			Sum_Trace+=fabs(p->data[count][count2]);
		}
		Sum_Trace-=(H2-H1)*fabs(p->data[count][H1]);

		// Record Measurements.
		p->misfit3[count]=(1.0*(H2-H1)/width)-1.0;
		p->misfit4[count]=Sum_Trace/Sum_ESW-1;
		p->M2_B[count]=H1*p->delta+p->C1;
		p->M2_E[count]=H2*p->delta+p->C1;

	}
    return;
}


void MakeNorm(struct Data *p){

	/************************************************
	 * This C function make Norm2 difference between
	 * ESW and each trace:
	 * norm2=(trace-ESW)_2/(ESW)_2.
	************************************************/

    int    count,count2;
    double *tmpdata;
    tmpdata=(double *)malloc(p->Elen*sizeof(double));

    for (count=0;count<p->fileN;count++){
        for (count2=0;count2<p->Elen;count2++){
            tmpdata[count2]=p->data[count][p->ploc[count]+p->eloc+count2]*p->polarity[count];
        }
        p->norm2[count]=p_norm_err(tmpdata,p->stack+p->stack_p+p->eloc,p->Elen,2);
    }

	free(tmpdata);

    return;
}

void NoiseFreq(struct Data *p){

	/**************************************************
	 * This C function do fft on the noise section of
	 * each trace, measure the frequency spectrum peak,
	 * which can be used later as a guidance to decide
	 * the deconvolution waterlevel.
	************************************************/

    int    count,tmpP;
    double **noise,*freq,**amp,**phase;

    if (strcmp(p->PHASE,"S")!=0){
        for (count=0;count<p->fileN;count++){
            p->spectrummax[count]=0.0;
        }
        p->waterlevel=0.0;
        return ;
    }


    noise=(double **)malloc(p->fileN*sizeof(double *));
    amp=(double **)malloc(p->fileN*sizeof(double *));
    phase=(double **)malloc(p->fileN*sizeof(double *));

    p->Nlen+=p->Nlen%2;

    freq=(double *)malloc((p->Nlen/2+1)*sizeof(double));
    for (count=0;count<p->fileN;count++){
        amp[count]=(double *)malloc((p->Nlen/2+1)*sizeof(double));
        phase[count]=(double *)malloc((p->Nlen/2+1)*sizeof(double));
    }

    // Do measurements on the traces.
    for (count=0;count<p->fileN;count++){
        noise[count]=p->data[count]+p->naloc[count]+p->nloc;
    }

    freq_amp_phase(noise,p->fileN,p->Nlen,p->delta,freq,amp,phase);

    for (count=0;count<p->fileN;count++){
        p->spectrummax[count]=max_vald(amp[count],p->Nlen/2+1,&tmpP)/p->Nlen;
    }

    // Do measurements on the stack.
    noise[0]=p->stack+p->stack_p+p->nloc;
    freq_amp_phase(noise,1,p->Nlen,p->delta,freq,amp,phase);
    p->waterlevel=max_vald(amp[0],p->Nlen/2+1,&tmpP)/p->Nlen;

    // Free space.
    for (count=0;count<p->fileN;count++){
        free(amp[count]);
        free(phase[count]);
    }

    free(freq);
    free(amp);
    free(phase);
    free(noise);

    return;
}
