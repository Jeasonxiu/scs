#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * This C function read from input file the trace-dependent
 * parameters and read in signal data from two-column files.
 *
 * Shule Yu
 * Nov 18 2015
***********************************************************/

void ESW_ReadFile(struct Data *p){

    int    count,count2,npts,count3;
    FILE   *fp,*fpin;
    char   filename[200];
	double time,begin;

    // Read in file names, stnm, rad_pat.
    fp=fopen(p->INFILE,"r");
    for (count=0;count<p->fileN;count++){
        fscanf(fp,"%s%s%lf%lf",filename,p->stnm[count],&begin,p->rad_pat+count);

		count3=0;
		npts=filenr(filename);
		fpin=fopen(filename,"r");
		for (count2=0;count2<npts;count2++){
			fscanf(fpin,"%lf%lf",&time,&p->data[count][count3]);
			if (p->C1<=time && time<=p->C2 && count3<p->dlen){
				count3++;
			}
		}
		fclose(fpin);

        p->ploc[count]=(int)ceil((-p->C1+begin)/p->delta);
        p->naloc[count]=p->ploc[count];
    }
    fclose(fp);

    // Normalize them within ESW window.
    for (count=0;count<p->fileN;count++){
		p->amplitude[count]=normalize_window(p->data[count],p->dlen,p->ploc[count]+p->eloc,p->Elen);
    }

    return;
}
