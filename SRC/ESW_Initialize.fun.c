#include<stdio.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * This C function initialize the parameter part of the data
 * structure. Make it good for ESW_Check to work.
 *
 * Shule Yu
 * Nov 17 2015
***********************************************************/

void ESW_Initialize(struct Data *p){

    p->fileN=-1;
    p->dlen=-1;
	p->Elen=-1;
	p->Slen=-1;
	p->Nlen=-1;
    p->eloc=Dmaxl;
    p->sloc=Dmaxl;
    p->nloc=Dmaxl;
    p->passes=-1;
	p->order=-1;
	p->Filter_Flag=-1;

	p->EQ[0]='\0';
	p->PHASE[0]='\0';
	p->OUTDIR[0]='\0';
	p->INFILE[0]='\0';
	p->OUTFILE[0]='\0';

	p->C1=0.0/0.0;
	p->C2=0.0/0.0;
	p->E1=0.0/0.0;
	p->E2=0.0/0.0;
	p->F1=0.0/0.0;
	p->F2=0.0/0.0;
    p->S1=0.0/0.0;
	p->S2=0.0/0.0;
	p->N1=0.0/0.0;
	p->N2=0.0/0.0;
	p->taperwidth=0.0/0.0;
    p->delta=0.0/0.0;
    p->SNRLOW=0.0/0.0;
	p->SNRHIGH=0.0/0.0;
	p->CCCOFF=0.0/0.0;
	p->ramp=0.0/0.0;
    p->WBegin=0.0/0.0;
	p->WLen=0.0/0.0;
	p->WBegin_ScS=0.0/0.0;
	p->WLen_ScS=0.0/0.0;

    return;
}
