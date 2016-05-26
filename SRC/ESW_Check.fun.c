#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * This C function check whether parameters are appropriate.
 *
 * Note: New spaces malloced here.
 *
 * Shule Yu
 * Nov 17 2015
***********************************************************/

void ESW_Check(struct Data *p){

	int count,flag;

	flag=0;

	if (p->fileN<=0) flag=1;
    if (p->dlen<=0 || p->dlen>Dmaxl) flag=1;
	if (p->Elen<=0) flag=1;
	if (p->Slen<=0) flag=1;
	if (p->Nlen<=0) flag=1;
    if (p->passes<=0) flag=1;
	if (p->order<=0) flag=1;
    if (abs(p->eloc)>=p->dlen) flag=1;
    if (abs(p->sloc)>=p->dlen) flag=1;
    if (abs(p->nloc)>=p->dlen) flag=1;

	if (strlen(p->EQ)==0) flag=1;
	if (strlen(p->PHASE)==0) flag=1;
	if (strlen(p->OUTDIR)==0) flag=1;
	if (strlen(p->INFILE)==0) flag=1;
	if (strlen(p->OUTFILE)==0) flag=1;

    if (isnan(p->delta) || p->delta<=0) flag=1;
	if (isnan(p->C1) || p->C1>0 || p->C1<-p->delta*Dmaxl) flag=1;
	if (isnan(p->C2) || p->C2<0 || p->C2>p->delta*Dmaxl) flag=1;
	if (isnan(p->E1) || fabs(p->E1)>p->delta*Dmaxl) flag=1;
	if (isnan(p->E2) || fabs(p->E2)>p->delta*Dmaxl) flag=1;
	if (isnan(p->F1) || p->F1<0) flag=1;
	if (isnan(p->F2) || p->F2<0) flag=1;
	if (p->Filter_Flag<0 || p->Filter_Flag>3) flag=1;
	if (isnan(p->S1) || fabs(p->S1)>p->delta*Dmaxl) flag=1;
	if (isnan(p->S2) || fabs(p->S2)>p->delta*Dmaxl) flag=1;
	if (isnan(p->N1) || fabs(p->N1)>p->delta*Dmaxl) flag=1;
	if (isnan(p->N2) || fabs(p->N2)>p->delta*Dmaxl) flag=1;
	if (isnan(p->taperwidth) || p->taperwidth<0 || p->taperwidth>0.5) flag=1;
    if (isnan(p->SNRLOW)) flag=1;
	if (isnan(p->SNRHIGH)) flag=1;
	if (isnan(p->SNRLOW>p->SNRHIGH)) flag=1;
	if (isnan(p->CCCOFF) || p->CCCOFF<0 || p->CCCOFF>1) flag=1;
	if (isnan(p->ramp) || p->ramp<0 || p->ramp>1) flag=1;
    if (isnan(p->WBegin)) flag=1;
	if (isnan(p->WLen) || p->WLen<0) flag=1;
	if (isnan(p->WBegin_ScS)) flag=1;
	if (isnan(p->WLen_ScS) || p->WLen_ScS<0) flag=1;

	if ( flag!=0 ){
		printf("In %s: Parameter(s) inappropriate ...\n",__func__);
		exit(1);
	}
	else{

		p->ploc=(int *)malloc(p->fileN*sizeof(int));
		p->naloc=(int *)malloc(p->fileN*sizeof(int));
		p->rad_pat=(double *)malloc(p->fileN*sizeof(double));
		p->data=(double **)malloc(p->fileN*sizeof(double *));
		p->stnm=(char **)malloc(p->fileN*sizeof(char *));
		for (count=0;count<p->fileN;count++){
			p->data[count]=(double *)malloc(p->dlen*sizeof(double));
			p->stnm[count]=(char *)malloc(10*sizeof(double));
		}

		p->shift=(int *)malloc(p->fileN*sizeof(int));
		p->ppeak=(int *)malloc(p->fileN*sizeof(int));
		p->polarity=(int *)malloc(p->fileN*sizeof(int));
		p->weight=(double *)malloc(p->fileN*sizeof(double));
		p->snr=(double *)malloc(p->fileN*sizeof(double));
		p->ccc=(double *)malloc(p->fileN*sizeof(double));
		p->amplitude=(double *)malloc(p->fileN*sizeof(double));
		p->misfit=(double *)malloc(p->fileN*sizeof(double));
		p->misfit2=(double *)malloc(p->fileN*sizeof(double));
		p->norm2=(double *)malloc(p->fileN*sizeof(double));
		p->stack=(double *)malloc(p->dlen*sizeof(double));
		p->std=(double *)malloc(p->dlen*sizeof(double));
		p->spectrummax=(double *)malloc(p->fileN*sizeof(double));

	}
    return;
}
