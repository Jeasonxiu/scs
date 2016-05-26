#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * This C function define the steps ESW going to do on the
 * data.
 *
 * Shule Yu
 * Nov 18 2015
***********************************************************/

void ESW_Work(struct Data *p){

	int count;

    /************************
     * Quick and dirty stack.
    ************************/
    FindPeak(p,1);
    MakeStack(p,1);
    PickOnSet(p,1);


    /*******************
     * More careful ESW.
    *******************/
    EvaluateSNR(p);
    MakeStack(p,0);
    PickOnSet(p,1);
    FindPeak(p,0);
    PickOnSet(p,0);


    // Let's do it again !
	// Before that, normalize each trace to
	// their (presumably) correcte peak.
    for (count=0;count<p->fileN;count++){
		p->amplitude[count]*=normalize_window(p->data[count],p->dlen,p->ppeak[count]-1,3);
    }

    EvaluateSNR(p);
    MakeStack(p,0);
    PickOnSet(p,1);
    FindPeak(p,0);
    PickOnSet(p,0);

    /********************************
     * Evaluations after ESW is done.
    ********************************/
    EvaluateSNR(p);
    Misfit(p);
    MakeNorm(p);
    NoiseFreq(p);

    return;
}

