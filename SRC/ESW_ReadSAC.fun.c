#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ESW.h>
#include<ASU_tools.h>

/***********************************************************
 * This C function read from input file the trace-dependent
 * parameters and use read_sac to read in signal data.
 *
 * Shule Yu
 * Jun 26 2014
***********************************************************/

void ESW_ReadSAC(struct Data *p){

    int    count,count2,fileN,*bad;
    FILE   *fpin,*fpout;
    char   **filelist,outfile[200];
    double *ptime,AMP,nanchor;

    filelist=(char **)malloc(p->fileN*sizeof(char *));
    for (count=0;count<p->fileN;count++){
        filelist[count]=(char *)malloc(200*sizeof(char));
    }
    ptime=(double *)malloc(p->fileN*sizeof(double));
    bad=(int *)malloc(p->fileN*sizeof(int));

    // Read in sac file names, ptime, rad_pat.
    fpin=fopen(p->INFILE,"r");
    for (count=0;count<p->fileN;count++){
        fscanf(fpin,"%s%s%lf%lf%lf",filelist[count],p->stnm[count],ptime+count,&nanchor,p->rad_pat+count);

        p->ploc[count]=(int)ceil(-p->C1/p->delta);
        p->naloc[count]=(int)ceil((nanchor-ptime[count])/p->delta)+p->ploc[count];
    }
    fclose(fpin);

    fileN=read_sac(p->data,p->fileN,p->dlen,ptime,p->C1,p->delta,p->F1,p->F2,p->order,p->passes,p->Filter_Flag,1,p->taperwidth,filelist,bad);

    if (fileN==0){
        printf("No record for EQ: %s ...\n",p->EQ);
        exit(1);
    }

    // Deal with bad traces. ( shift record forward, skip bad traces slot. )
	sprintf(outfile,"%s/BadTraces.txt",p->OUTDIR);
	fpout=fopen(outfile,"w");
    for (count=p->fileN-1;count>-1;count--){
        if (bad[count]==1){
			fprintf(fpout,"%s\n",filelist[count]);
            free(p->data[count]);
            for (count2=count;count2<p->fileN-1;count2++){
                p->rad_pat[count2]=p->rad_pat[count2+1];
                strcpy(p->stnm[count2],p->stnm[count2+1]);
                p->naloc[count2]=p->naloc[count2+1];
                p->data[count2]=p->data[count2+1];
            }
        }
    }
	fclose(fpout);

    // Normalize them within ESW window.
    for (count=0;count<p->fileN;count++){
        p->amplitude[count]=normalize_window(p->data[count],p->dlen,p->ploc[count]+p->eloc,p->Elen);
    }

    // Free auxiliary space.
    for (count=0;count<p->fileN;count++){
        free(filelist[count]);
    }
    free(filelist);
    free(ptime);
    free(bad);

    // Fix the real trace num.
    p->fileN=fileN;

    return;
}
