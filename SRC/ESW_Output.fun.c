#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ESW.h>
#include<ASU_tools.h>

/*************************************************************
 * This C function print calculation results to certain files.
 *
 * Shule Yu
 * Jun 26 2014
*************************************************************/

void ESW_Output(struct Data *p){

    int   count,count2;
    char  *spaces="    ",outfile[200];
    FILE  *fpout;



    /*********
    * STDOUT *
    *********/

    fpout=fopen(p->STDOUT,"w");
    fprintf(fpout,"\n=======================================\n");
    fprintf(fpout,"=                Result                \n");
    fprintf(fpout,"=======================================\n");
    fprintf(fpout,"<EQ> %s\n",p->EQ);
    fprintf(fpout,"<Nrecord_Used> %d\n",p->contribute);
    fprintf(fpout,"<Nrecord_All> %d\n",p->fileN);
    fprintf(fpout,"<WaterESW> %.6lf\n",p->waterlevel);
	fprintf(fpout,"<Misfit_ESW> %.6lf\n",p->misfit_esw);
	fprintf(fpout,"<Misfit2_ESW> %.6lf\n",p->misfit2_esw);
	fprintf(fpout,"<Misfit3_ESW> %.6lf\n",p->misfit3_esw);
	fprintf(fpout,"<Misfit4_ESW> %.6lf\n",p->misfit4_esw);
    fclose(fpout);


    /**************
    * Main Output *
    **************/

    sprintf(outfile,"%s/%s",p->OUTDIR,p->OUTFILE);
    fpout=fopen(outfile,"w");
    fprintf(fpout,"<EQ>%s<STNM>%s<D_T>%s<CCC>%s<SNR>%s<Weight>%s\
	<Misfit>%s<Misfit2>%s<Misfit3>%s<Misfit4>%s<M1_B>%s<M1_E>%s<M2_B>%s<M2_E>%s\
	<Norm2>%s<Peak>%s<Nanchor>%s\
    <N_T1>%s<N_T2>%s<S_T1>%s<S_T2>%s<Polarity>%s<Rad_Pat>%s<WaterLevel>%s<Amplitude>\n"
    ,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces
    ,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces,spaces);

    for(count=0;count<p->fileN;count++){
        fprintf(fpout,"%s\t%s%15.3lf%15.2lf%15.2lf\
        %15.3lf%15.3lf%15.3lf%15.3lf%15.3lf%15.3lf%15.3lf%15.3lf\
		%15.3lf%15.3lf%15.3lf\
        %15.3lf%15.3lf%15.3lf\
        %15.3lf%15.3lf\
        %5d%15.4lf%15.6lf\t%.4e\n"
        ,p->EQ,p->stnm[count],p->C1+p->delta*p->ploc[count],p->ccc[count],p->snr[count],fabs(p->weight[count])
        ,p->misfit[count],p->misfit2[count],p->misfit3[count],p->misfit4[count],p->M1_B[count],p->M1_E[count],p->M2_B[count],p->M2_E[count]
		,p->norm2[count],p->C1+p->delta*p->ppeak[count]
        ,p->C1+p->delta*p->naloc[count],p->C1+p->delta*(p->naloc[count]+p->nloc)
		,p->C1+p->delta*(p->naloc[count]+p->nloc+p->Nlen)
        ,p->C1+p->delta*(p->ppeak[count]+p->sloc),p->C1+p->delta*(p->ppeak[count]+p->sloc+p->Slen)
        ,p->polarity[count],p->rad_pat[count],p->spectrummax[count],p->amplitude[count]);
    }
    fclose(fpout);


    /**************
    * ESW and STD *
    **************/

    sprintf(outfile,"%s/%s.ESF_F",p->OUTDIR,p->EQ);
    fpout=fopen(outfile,"w");
    for (count=0;count<p->Elen;count++){
        fprintf(fpout,"%.4lf\t%.4e\n",p->E1+count*p->delta,p->stack[p->stack_p+p->eloc+count]);
    }
    fclose(fpout);

    sprintf(outfile,"%s/%s.ESF_F.std",p->OUTDIR,p->EQ);
    fpout=fopen(outfile,"w");

    for (count=0;count<p->Elen;count++){
        fprintf(fpout,"%.4lf\t%.4e\n",p->E1+count*p->delta,p->std[p->stack_p+p->eloc+count]);
    }
    fclose(fpout);



    /**************************
    * Full stack and its std. *
    **************************/

    sprintf(outfile,"%s/fullstack",p->OUTDIR);
    fpout=fopen(outfile,"w");
    for (count=0;count<p->dlen;count++){
        fprintf(fpout,"%.4lf\t%.4e\n",(count-p->stack_p)*p->delta,p->stack[count]);
    }
    fclose(fpout);

    sprintf(outfile,"%s/fullstack.std",p->OUTDIR);
    fpout=fopen(outfile,"w");

    for (count=0;count<p->dlen;count++){
        fprintf(fpout,"%.4lf\t%.4e\n",(count-p->stack_p)*p->delta,p->std[count]);
    }
    fclose(fpout);



    /*****************************
    * All waveforms, t=0 at PREM *
    *****************************/

    for(count=0;count<p->fileN;count++){
        sprintf(outfile,"%s/%s.waveform",p->OUTDIR,p->stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<p->dlen;count2++){
            fprintf(fpout,"%.4lf\t%.4e\n",p->C1+count2*p->delta,p->data[count][count2]);
        }
        fclose(fpout);
    }

    return;
}
