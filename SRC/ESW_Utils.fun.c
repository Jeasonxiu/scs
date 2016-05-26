#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

// 4 functions:
// FindPeak
// MakeStack
// MakeWeight
// PickOnSet

void FindPeak(struct Data *p,int quick){

	/**********************************************
	 * This C function find peak position for each
	 * trace within time window ploc ~ ploc + 10.
	 *
	 * int quick  --  1 indicate rough pick.
	**********************************************/

    int  polarity[MAXtrace],count,count2,fileNN,shift,P,Wlength,Wbegin,Wlength_ScS,Wbegin_ScS;
    FILE *fpin;
    char *DATAFILE="tmpfile_POLARITY",names[MAXtrace][10];

    // Read in S Polarity for ScS.
    if (strcmp(p->PHASE,"ScS")==0){
        fpin=fopen(DATAFILE,"r");

        count=0;
        while (fscanf(fpin,"%s%d",names[count],&polarity[count])==2){
            count++;
        }
        fclose(fpin);
        fileNN=count;

        // Assign Polarity for ScS.
        for (count=0;count<p->fileN;count++){
            for (count2=0;count2<fileNN;count2++){
                if (strcmp(p->stnm[count],names[count2])==0){
                    break;
                }
            }
            if (count2<fileNN){
                p->polarity[count]=polarity[count2];
            }
        }
    }

    if (quick==1){

        Wbegin=(int)(p->WBegin/p->delta);
        Wlength=(int)(p->WLen/p->delta);
        Wbegin_ScS=(int)(p->WBegin_ScS/p->delta);
        Wlength_ScS=(int)(p->WLen_ScS/p->delta);

        for (count=0;count<p->fileN;count++){
            if (strcmp(p->PHASE,"S")==0){
                p->polarity[count]=max_ampd(p->data[count]+p->ploc[count]+Wbegin,Wlength,&p->ppeak[count]);
                p->ppeak[count]+=p->ploc[count]+Wbegin;
            }
            else{
                if (p->polarity[count]==1){
                    max_vald(p->data[count]+p->ploc[count]+Wbegin_ScS,Wlength_ScS,&p->ppeak[count]);
                }
                else{
                    min_vald(p->data[count]+p->ploc[count]+Wbegin_ScS,Wlength_ScS,&p->ppeak[count]);
                }
                p->ppeak[count]+=p->ploc[count]+Wbegin_ScS;

            }

            // Find the peak within ESW Window if the process above is wrong.

            if (strcmp(p->PHASE,"S")==0 && fabs(p->data[count][p->ppeak[count]])<0.75){
                p->polarity[count]=max_ampd(p->data[count]+p->ploc[count]+p->eloc,p->Elen,&p->ppeak[count]);
                p->ppeak[count]+=(p->ploc[count]+p->eloc);
            }
        }
    }
    else{

        // Find the peak position on ESW.
        max_ampd(p->stack+p->stack_p+p->eloc,p->Elen,&P);
        P+=p->stack_p+p->eloc;

        // Find the peak position on traces within -2 ~ +2 second around peak pridicted by ESE ccc position.
        for (count=0;count<p->fileN;count++){
            shift=P-p->shift[count]-(int)2/p->delta;
            if (strcmp(p->PHASE,"S")==0){
                p->polarity[count]=max_ampd(p->data[count]+shift,(int)4/p->delta,&p->ppeak[count]);
            }
            else{
                if (p->polarity[count]==1){
                    max_vald(p->data[count]+shift,(int)4/p->delta,&p->ppeak[count]);
                }
                else{
                    min_vald(p->data[count]+shift,(int)4/p->delta,&p->ppeak[count]);
                }
            }
            p->ppeak[count]+=shift;
        }
    }

    return;
}

void MakeStack(struct Data *p,int quick){

	/********************************************
	 * This C function make stack and create ESW.
	 *
	 * int quick  --  1 indicate weight is only
	 * 				  depends on CCC.
	********************************************/

    int    N,count,count2,contribute,P;
    double flip,AMP;

    contribute=1;
    // Iteratively make stack.
    for (N=0;N<stackloopN;N++){

        // Shift_Stack and make stack N.
        if (N==0 || contribute==0){
            shift_stack(p->data,p->fileN,p->dlen,0,p->shift,0,p->weight,p->stack,p->std);
        }
        else{
            shift_stack(p->data,p->fileN,p->dlen,1,p->shift,1,p->weight,p->stack,p->std);
        }

        // Count how many traces contribute to this stack.
        contribute=0;
        for (count=0;count<p->fileN;count++){
            if (p->weight[count]!=0){
                contribute++;
            }
        }

        // Normalize stack within ESE window.
        AMP=normalize_window(p->stack,p->dlen,p->stack_p+p->eloc,p->Elen);
        for (count=0;count<p->dlen;count++){
            p->std[count]/=AMP;
        }

        // Flip stack to peak upwards.
        flip=max_ampd(p->stack+p->stack_p+p->eloc,p->Elen,&count);
        for (count=0;count<p->dlen;count++){
            p->stack[count]*=flip;
        }

        // Cross-Correlation.
        for (count=0;count<p->fileN;count++){
            CC_positive(p->stack+p->stack_p+p->eloc,p->Elen,p->data[count]+p->ploc[count]+p->eloc,p->Elen,p->shift+count,p->ccc+count,p->polarity[count]);
            p->shift[count]+=(p->stack_p-p->ploc[count]);
        }

        // MakeWeights.
		MakeWeight(p,quick);
    }
    p->contribute=contribute;

    return ;
}

void MakeWeight(struct Data *p, int quick){

	/********************************************
	 * This C function returns a weight for each
	 * trace.
	 *
	 * int quick   --  1 indicate weight is only
	 * 				   depends on CCC.
	********************************************/
	int count;

    if (quick!=1){

		for (count=0;count<p->fileN;count++){

			if (fabs(p->ccc[count])>=p->CCCOFF && p->snr[count]>p->SNRLOW){
				p->weight[count]=p->ccc[count]*(p->ramp+(1-p->ramp)*ramp_function(p->snr[count],p->SNRLOW,p->SNRHIGH));
			}
			else{
				p->weight[count]=0.0;
			}
		}
    }
    else{

		for (count=0;count<p->fileN;count++){

			if (fabs(p->ccc[count])>=p->CCCOFF){
				p->weight[count]=p->ccc[count];
			}
			else{
				p->weight[count]=0.0;
			}
		}
    }
	return;
}

void PickOnSet(struct Data *p,int update){

	/***********************************************
	 * This C function set a hardwired OnSet on ESW.
	 *
	 * int update  --  1 means we then use cross-
	 *                 correlation to set onset of
	 *                 each trace. (update ploc)
	***********************************************/

    int    count,newonset,P;

    // Pick OnSet on ESW.
    newonset=pick_onset(p->stack,p->dlen,p->delta,p->stack_p+p->sloc,p->Slen);
    if (newonset>0){
        p->stack_p=newonset;
    }
    
    // ! Subject to modification !
    // Find the peak position on ESW and use the peakk-3s as the OnSet.
    max_ampd(p->stack+p->stack_p+p->eloc,p->Elen,&P);
    p->stack_p+=P+p->eloc-(int)(3/p->delta);

    // Update every traces' phase onset location.
    if (update==0){
        for (count=0;count<p->fileN;count++){
            p->ploc[count]=p->stack_p-p->shift[count];
        }
    }
    return;
}
