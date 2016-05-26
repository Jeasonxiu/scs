#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<sac.h>
#include<sacio.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {NPTS_signal,method};
    enum PSenum {outfile1,outfile2,outfile3,outfile4,outfile5,outfile6,outfile7,outfile8,outfile9,outfile10,outfile11,outfile12,outfile13,outfile14,outfile15,outfile16,outfile17,outfile18};
    enum Penum  {delta,sigma_source,gwidth,cutoff_left,cutoff_right,waterlevel,sigma_smooth,taperwidth,secondarrival,secondamp,ulvzarrival,ulvzamp};

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

    int    NPTS_source,NPTS_tmp,tmpP,P1,*P2;
    FILE   *fpout,*fpoutfile15,*fpoutfile16,*fpoutfile17,*fpoutfile18;
    double *structure,*source,*signal,**decon,*tmp,*frs,*frs_nodecon,*amp,*phase,*freq;

    NPTS_source=2*(int)ceil(P[gwidth]/2/P[delta]);
    NPTS_tmp=PI[NPTS_signal]+NPTS_source-1;

    structure=(double *)malloc(PI[NPTS_signal]*sizeof(double));
    source=(double *)malloc(NPTS_source*sizeof(double));
    tmp=(double *)malloc(NPTS_tmp*sizeof(double));
    signal=(double *)malloc(PI[NPTS_signal]*sizeof(double));
    frs=(double *)malloc(PI[NPTS_signal]/4*sizeof(double));
    frs_nodecon=(double *)malloc(PI[NPTS_signal]/4*sizeof(double));
    decon=(double **)malloc(sizeof(double));
    decon[0]=(double *)malloc(2*PI[NPTS_signal]*sizeof(double));
	P2=(int *)malloc(sizeof(int));

    // Make Strucuture.
    for (count=0;count<PI[NPTS_signal];count++){
        structure[count]=0;
    }
    structure[PI[NPTS_signal]/2]=1;
    structure[PI[NPTS_signal]/2-(int)(P[ulvzarrival]/P[delta])]=-P[ulvzamp];
    structure[PI[NPTS_signal]/2+(int)(P[ulvzarrival]/P[delta])]=P[ulvzamp];

    // Make Source.

//     random_gaussian(source,NPTS_source,0,P[sigma_source]);

    for (count=0;count<NPTS_source/2;count++){
        source[count]=gaussian(-(NPTS_source/2-count-0.5)*P[delta],P[sigma_source],0);
        source[NPTS_source-1-count]=source[count];
    }

    for (count=0;count<NPTS_source-(int)(P[secondarrival]/P[delta]);count++){
        source[count]+=P[secondamp]*source[count+(int)(P[secondarrival]/P[delta])];
    }

    reverse_array(source,NPTS_source);

    // Make signal.
    convolve(structure,source,PI[NPTS_signal],NPTS_source,tmp);
    for (count=0;count<PI[NPTS_signal];count++){
        signal[count]=tmp[count+NPTS_source/2];
    }

	butterworth_bp(&signal,1,PI[NPTS_signal],P[delta],2,2,0.03333,0.3,&signal);
	
    for (count=0;count<NPTS_source;count++){
        source[count]=signal[PI[NPTS_signal]/2-NPTS_source/2+count];
    }

    normalized(source,NPTS_source);
    normalized(signal,PI[NPTS_signal]);
    max_ampd(source,NPTS_source,&P1);
    max_ampd(signal,PI[NPTS_signal],P2);

    // Decon.
    taperd(signal,PI[NPTS_signal],P[taperwidth]);

    // Deconvolution.
    fpoutfile15=fopen(PS[outfile15],"w");
    fpoutfile16=fopen(PS[outfile16],"w");
    fpoutfile17=fopen(PS[outfile17],"w");
    fpoutfile18=fopen(PS[outfile18],"w");


    if (PI[method]==1){

        waterlevel_decon(&signal,1,PI[NPTS_signal],source,NPTS_source,P1,P2,decon,P[waterlevel],P[delta],0,NULL,NULL,NULL,NULL,NULL,NULL);
		normalized(decon[0],2*PI[NPTS_signal]);

    }
    else{
        printf("Method Error !\n");
        exit(1);
    }
    fclose(fpoutfile15);
    fclose(fpoutfile16);
    fclose(fpoutfile17);
    fclose(fpoutfile18);

    // Do FRS on signal.
    max_ampd(signal,PI[NPTS_signal],&tmpP);
    if (fabs(signal[tmpP])>fabs(signal[tmpP+1])){
        frs_nodecon[0]=0;
        for (count=1;count<PI[NPTS_signal]/4;count++){
            frs_nodecon[count]=signal[tmpP+count]-signal[tmpP-count];
        }
    }
    else{
        for (count=0;count<PI[NPTS_signal]/4;count++){
            frs_nodecon[count]=signal[tmpP+1+count]-signal[tmpP-count];
        }
    }

    // Do FRS on Deconed trace.
    max_ampd(decon[0],2*PI[NPTS_signal],&tmpP);
    if (fabs(decon[0][tmpP])>fabs(decon[0][tmpP+1])){
        frs[0]=0;
        for (count=1;count<PI[NPTS_signal]/4;count++){
            frs[count]=decon[0][tmpP+count]-decon[0][tmpP-count];
        }
    }
    else{
        for (count=0;count<PI[NPTS_signal]/4;count++){
            frs[count]=decon[0][tmpP+count]-decon[0][tmpP-count];
        }
    }

    // Output.
    fpout=fopen(PS[outfile1],"w");
    for (count=0;count<PI[NPTS_signal];count++){
        fprintf(fpout,"%.10lf\t%.10lf\n",(count-PI[NPTS_signal]/2)*P[delta],structure[count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile2],"w");
    for (count=0;count<NPTS_source;count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-NPTS_source/2)*P[delta],source[count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile3],"w");
    for (count=0;count<PI[NPTS_signal];count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-PI[NPTS_signal]/2)*P[delta],signal[count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile4],"w");
    for (count=0;count<2*PI[NPTS_signal];count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-PI[NPTS_signal])*P[delta],decon[0][count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile5],"w");
    for (count=0;count<PI[NPTS_signal]/4;count++){
        fprintf(fpout,"%.10lf\t%lf\n",count*P[delta],frs_nodecon[count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile6],"w");
    for (count=0;count<PI[NPTS_signal]/4;count++){
        fprintf(fpout,"%.10lf\t%lf\n",count*P[delta],frs[count]);
    }
    fclose(fpout);

    // Calculate the frequency content of these traces.
    // structure.
    amp=(double *)malloc((PI[NPTS_signal]/2+1)*sizeof(double));
    freq=(double *)malloc((PI[NPTS_signal]/2+1)*sizeof(double));
    phase=(double *)malloc((PI[NPTS_signal]/2+1)*sizeof(double));
    freq_amp_phase(&structure,1,PI[NPTS_signal],P[delta],freq,&amp,&phase);
    normalized(amp,PI[NPTS_signal]/2+1);

    fpout=fopen(PS[outfile7],"w");
    for (count=0;count<PI[NPTS_signal]/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile8],"w");
    for (count=0;count<PI[NPTS_signal]/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);

    // signal.
    freq_amp_phase(&signal,1,PI[NPTS_signal],P[delta],freq,&amp,&phase);
    normalized(amp,PI[NPTS_signal]/2+1);

    fpout=fopen(PS[outfile11],"w");
    for (count=0;count<PI[NPTS_signal]/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile12],"w");
    for (count=0;count<PI[NPTS_signal]/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);
    free(amp);
    free(freq);
    free(phase);

    // decon.
    amp=(double *)malloc((PI[NPTS_signal]+1)*sizeof(double));
    freq=(double *)malloc((PI[NPTS_signal]+1)*sizeof(double));
    phase=(double *)malloc((PI[NPTS_signal]+1)*sizeof(double));

    freq_amp_phase(decon,1,2*PI[NPTS_signal],P[delta],freq,&amp,&phase);
    normalized(amp,PI[NPTS_signal]+1);

    fpout=fopen(PS[outfile13],"w");
    for (count=0;count<PI[NPTS_signal]+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile14],"w");
    for (count=0;count<PI[NPTS_signal]+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);
    free(amp);
    free(freq);
    free(phase);

    // source.
    amp=(double *)malloc((NPTS_source/2+1)*sizeof(double));
    freq=(double *)malloc((NPTS_source/2+1)*sizeof(double));
    phase=(double *)malloc((NPTS_source/2+1)*sizeof(double));
    freq_amp_phase(&source,1,NPTS_source,P[delta],freq,&amp,&phase);
    normalized(amp,NPTS_source/2+1);

    fpout=fopen(PS[outfile9],"w");
    for (count=0;count<NPTS_source/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile10],"w");
    for (count=0;count<NPTS_source/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);
    free(amp);
    free(freq);
    free(phase);

    // Free spaces.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    free(structure);
    free(source);
    free(signal);
    free(decon[0]);
    free(decon);
    free(frs);
    free(frs_nodecon);
    free(tmp);

    return 0;
}
