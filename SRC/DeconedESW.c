#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * ESW on deconed ScS traces.
***********************************************************/

int main(int argc, char **argv){

	if (argc!=4){
		printf("In C : Argument Error!\n");
		return 1;
	}

    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {passes,order,filterflag};
    enum PSenum {EQ,PHASE,OUTDIR,INFILE,STDOUT,OUTFILE};
    enum Penum  {C1,C2,E1,E2,F1,F2,S1,S2,N1,N2,
	             taperwidth,DELTA,SNRLOW,SNRHIGH,
				 CCCOFF,ramp,WBegin,WLen,
				 WBegin_ScS,WLen_ScS};

    int_num=atoi(argv[1]);
    string_num=atoi(argv[2]);
    double_num=atoi(argv[3]);

    PI=(int *)malloc(int_num*sizeof(int));
    PS=(char **)malloc(string_num*sizeof(char *));
    P=(double *)malloc(double_num*sizeof(double));
    for (count=0;count<string_num;count++){
        PS[count]=(char *)malloc(200*sizeof(char));
    }

    for (count=0;count<int_num;count++){
        if (scanf("%d",PI+count)!=1){
            printf("In C : Integer parameter reading Error !\n");
			CleanUp(PI,PS,P,string_num);
            return 1;
        }
    }

    for (count=0;count<string_num;count++){
        if (scanf("%s",PS[count])!=1){
            printf("In C : String parameter reading Error !\n");
			CleanUp(PI,PS,P,string_num);
            return 1;
        }
    }

    for (count=0;count<double_num;count++){
        if (scanf("%lf",P+count)!=1){
            printf("In C : Double parameter reading Error !\n");
			CleanUp(PI,PS,P,string_num);
            return 1;
        }
    }



    /*********************************
	 *
     *            Begin.
	 *
    *********************************/

    struct Data *p=(struct Data *)malloc(sizeof(struct Data));

	ESW_Initialize(p);


    /*********************************
	 *
     *      Loading parameters.
	 *
    *********************************/

    p->dlen=(int)ceil((P[C2]-P[C1])/P[DELTA]);p->fileN=filenr(PS[INFILE]);
	strcpy(p->EQ,PS[EQ]);strcpy(p->PHASE,PS[PHASE]);strcpy(p->OUTDIR,PS[OUTDIR]);
	strcpy(p->INFILE,PS[INFILE]);strcpy(p->STDOUT,PS[STDOUT]);strcpy(p->OUTFILE,PS[OUTFILE]);
    p->passes=PI[passes];p->order=PI[order];p->F1=P[F1];p->F2=P[F2];
	p->Filter_Flag=PI[filterflag];p->taperwidth=P[taperwidth];
    p->delta=P[DELTA];p->C1=P[C1];p->C2=P[C2];p->E1=P[E1];p->E2=P[E2];
    p->S1=P[S1];p->S2=P[S2];p->N1=P[N1];p->N2=P[N2];
    p->eloc=(int)ceil(p->E1/p->delta);p->Elen=(int)ceil((P[E2]-P[E1])/P[DELTA]);
    p->sloc=(int)ceil(p->S1/p->delta);p->Slen=(int)ceil((P[S2]-P[S1])/P[DELTA]);
    p->nloc=(int)ceil(p->N1/p->delta);p->Nlen=(int)ceil((P[N2]-P[N1])/P[DELTA]);
    p->SNRLOW=P[SNRLOW];p->SNRHIGH=P[SNRHIGH];p->CCCOFF=P[CCCOFF];p->ramp=P[ramp];
    p->WBegin=P[WBegin];p->WLen=P[WLen];p->WBegin_ScS=P[WBegin_ScS];p->WLen_ScS=P[WLen_ScS];
    p->stack_p=(int)ceil(-P[C1]/p->delta);



    /*********************************
	 *
	 *    Begin calculation.
	 *
    *********************************/

	ESW_Check(p);

    ESW_ReadFile(p);

    ESW_Work(p);

    ESW_Output(p);

	CleanUp(PI,PS,P,string_num);

    return 0;
}

void CleanUp(int *PI, char **PS, double *P, int string_num){
	int Cnt;
	for (Cnt=0;Cnt<string_num;++Cnt){
		free(PS[Cnt]);
	}
	free(P);free(PI);free(PS);
	return;
}
