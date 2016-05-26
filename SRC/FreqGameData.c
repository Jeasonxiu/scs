#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {method};
    enum PSenum {infile,outfile1,outfile2,outfile3,outfile4,outfile5,outfile6,outfile7,outfile8,outfile9,outfile10,outfile11,outfile12,outfile13,outfile14,outfile15,outfile16,outfile17,outfile18,outfile19,outfile20,infile_tmp};
    enum Penum  {cut,delta,gwidth,cutoff_left,cutoff_right,waterlevel,sigma_smooth,taperwidth,secondarrival,secondamp,ulvzarrival,ulvzamp,noiselevel};

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
    int    NPTS_struct,NPTS_source,NPTS_signal,NPTS_decon,NPTS_frs,NPTS_post,tmpP,P1,*P2;
    FILE   *fpin,*fpout;
    double *structure,*source,*signal,**decon,*frs,*frs_1,*amp,*phase,*freq,time,*randdouble,*filled_source_fft_amp,*filled_source_fft_phase,*post,*decon_gaussblur,*decon_bandpass,**fft_amp,**fft_phase,**divide_amp,**divide_phase,df;
    float  *decon_float,*post_float;


    // Set up trace length.
    NPTS_struct=2*(int)ceil((50+1*P[ulvzarrival])/P[delta]);
    NPTS_source=(int)ceil(2*P[cut]/P[delta]);
    NPTS_signal=NPTS_struct+NPTS_source-1;
    NPTS_decon=2*NPTS_signal;
    NPTS_frs=(int)ceil(20/P[delta]);
    NPTS_post=3001;

    structure=(double *)malloc(NPTS_struct*sizeof(double));
    source=(double *)malloc(NPTS_source*sizeof(double));
    signal=(double *)malloc(NPTS_signal*sizeof(double));
    decon=(double **)malloc(sizeof(double));
    decon[0]=(double *)malloc(NPTS_decon*sizeof(double));
    filled_source_fft_amp=(double *)malloc((NPTS_signal+1)*sizeof(double));
    filled_source_fft_phase=(double *)malloc((NPTS_signal+1)*sizeof(double));
    decon_float=(float *)malloc(NPTS_decon*sizeof(float));
    randdouble=(double *)malloc(NPTS_signal*sizeof(double));
    post=(double *)malloc(NPTS_post*sizeof(double));
    post_float=(float *)malloc(NPTS_post*sizeof(float));
    decon_gaussblur=(double *)malloc(NPTS_decon*sizeof(double));
    decon_bandpass=(double *)malloc(NPTS_decon*sizeof(double));
    fft_amp=(double **)malloc(sizeof(double *));
    fft_amp[0]=(double *)malloc((NPTS_signal+1)*sizeof(double));
    fft_phase=(double **)malloc(sizeof(double *));
    fft_phase[0]=(double *)malloc((NPTS_signal+1)*sizeof(double));

    divide_amp=(double **)malloc(sizeof(double *));
    divide_amp[0]=(double *)malloc((NPTS_signal+1)*sizeof(double));
    divide_phase=(double **)malloc(sizeof(double *));
    divide_phase[0]=(double *)malloc((NPTS_signal+1)*sizeof(double));

    frs=(double *)malloc(NPTS_frs*sizeof(double));
    frs_1=(double *)malloc(NPTS_frs*sizeof(double));

    P2=(int *)malloc(sizeof(int));

    // Make Strucuture.
    for (count=0;count<NPTS_struct;count++){
        structure[count]=0;
    }
    structure[NPTS_struct/2]=1;
    structure[NPTS_struct/2-(int)(P[ulvzarrival]/P[delta])]=-P[ulvzamp];
    structure[NPTS_struct/2+(int)(P[ulvzarrival]/P[delta])]=P[ulvzamp];


    // Read Source.
    fpin=fopen(PS[infile],"r");
    for(count=0;count<NPTS_source;count++){

        fscanf(fpin,"%lf%lf",&time,&source[count]);

        if ( time < -P[cut] ){
            count--;
        }
    }
    fclose(fpin);
    taperd(source,NPTS_source,P[taperwidth]);

    // Make signal.
//     convolve(structure,source,NPTS_struct,NPTS_source,signal);

	// tmp:
    for(count=0;count<NPTS_signal;count++){
		signal[count]=0;
	}

    fpin=fopen(PS[infile_tmp],"r");
	count=0;
    while(fscanf(fpin,"%lf%lf",&time,&signal[count])==2){
        if ( fabs(time) < 30 ){
            ++count;
        }
    }
    fclose(fpin);
    taperd(signal,NPTS_source,P[taperwidth]);
    max_vald(signal,NPTS_signal,P2);
	shift_array(signal,NPTS_signal,NPTS_signal/2-(*P2));


    // Create noise.
    random_gaussian(randdouble,NPTS_signal,0,P[noiselevel]);
    for (count=0;count<NPTS_signal;count++){
        signal[count]+=randdouble[count];
    }

//     normalized(signal,NPTS_signal);


    max_vald(source,NPTS_source,&P1);
    max_vald(signal,NPTS_signal,P2);
//     max_vald(signal+(*P2)+700,400,&tmpP);
// printf("Begin searching: %.2lf\n",1.0*((*P2)+700-NPTS_signal/2)*P[delta]);
//     (*P2)+=(tmpP+700);
// printf("The peak of source is chosen at %.2lf sec.\n",1.0*(P1-NPTS_source/2)*P[delta]);
// printf("The peak of ScS is chosen at %.2lf sec.\n",1.0*((*P2)-NPTS_signal/2)*P[delta]);

    // Deconvolution.
    waterlevel_decon(&signal,1,NPTS_signal,source,NPTS_source,P1,P2,decon,P[waterlevel],P[delta],1,filled_source_fft_amp,filled_source_fft_phase,fft_amp,fft_phase,divide_amp,divide_phase);

    // Output just after division frequency spectrum and phase.
    amp=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    freq=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    phase=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    freq_amp_phase(decon,1,NPTS_decon,P[delta],freq,&amp,&phase);
    normalized(amp,NPTS_decon/2+1);

    fpout=fopen(PS[outfile19],"w");
    for (count=0;count<NPTS_decon/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile20],"w");
    for (count=0;count<NPTS_decon/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);
    free(amp);
    free(freq);
    free(phase);


    // Do all the methods on the same trace.
    // method 1, gauss blur.
    gaussblur_1d(decon,1,NPTS_decon,P[delta],P[sigma_smooth],P[gwidth],&decon_gaussblur);
    normalized(decon_gaussblur,NPTS_decon);

    // method 2, bandpass.
	butterworth_bp(decon,1,NPTS_decon,P[delta],2,2,0.03,0.3,&decon_bandpass);
    normalized(decon_bandpass,NPTS_decon);

    // Post-process the deconed trace.
    if (PI[method]==1){
        gaussblur_1d(decon,1,NPTS_decon,P[delta],P[sigma_smooth],P[gwidth],decon);
    }
    else{
		butterworth_bp(decon,1,NPTS_decon,P[delta],2,2,0.03,0.3,decon);
    }
    normalized(decon[0],NPTS_decon);

    // Do FRS on signal. (Upper plot.)
    max_ampd(signal,NPTS_signal,&tmpP);
    if (fabs(signal[tmpP])>fabs(signal[tmpP+1])){
        frs_1[0]=0;
        for (count=1;count<NPTS_frs;count++){
            frs_1[count]=signal[tmpP+count]-signal[tmpP-count];
        }
    }
    else{
        for (count=0;count<NPTS_frs;count++){
            frs_1[count]=signal[tmpP+1+count]-signal[tmpP-count];
        }
    }

    // Do FRS on Deconed trace_1. (Upper plot.)
// 	double *goes_into_frs;
//     goes_into_frs=decon_bandpass;
//     max_ampd(goes_into_frs+NPTS_decon/2-200,400,&tmpP);
//     tmpP+=(NPTS_decon/2-200);
//     normalize_window(goes_into_frs,NPTS_decon,NPTS_decon/2-200,NPTS_decon/2+200);
//     if (fabs(goes_into_frs[tmpP])>fabs(goes_into_frs[tmpP+1])){
//         frs_1[0]=0;
//         for (count=1;count<NPTS_frs;count++){
//             frs_1[count]=goes_into_frs[tmpP+count]-goes_into_frs[tmpP-count];
//         }
//     }
//     else{
//         for (count=0;count<NPTS_frs;count++){
//             frs_1[count]=goes_into_frs[tmpP+count]-goes_into_frs[tmpP-count];
//         }
//     }

    // Do FRS on Deconed trace. (Lower plot.)
    max_ampd(decon[0]+NPTS_decon/2-200,400,&tmpP);
    tmpP+=(NPTS_decon/2-200);
    normalize_window(decon[0],NPTS_decon,NPTS_decon/2-200,NPTS_decon/2+200);
    if (fabs(decon[0][tmpP])>fabs(decon[0][tmpP+1])){
        frs[0]=0;
        for (count=1;count<NPTS_frs;count++){
            frs[count]=decon[0][tmpP+count]-decon[0][tmpP-count];
        }
    }
    else{
        for (count=0;count<NPTS_frs;count++){
            frs[count]=decon[0][tmpP+count]-decon[0][tmpP-count];
        }
    }


    // Outputs.

    // Structure.
    fpout=fopen(PS[outfile1],"w");
    for (count=0;count<NPTS_struct;count++){
        fprintf(fpout,"%.10lf\t%.10lf\n",(count-NPTS_struct/2)*P[delta],structure[count]);
    }
    fclose(fpout);

    // Source.
    fpout=fopen(PS[outfile2],"w");
    for (count=0;count<NPTS_source;count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-NPTS_source/2)*P[delta],source[count]);
    }
    fclose(fpout);



    // Signal.
    fpout=fopen(PS[outfile3],"w");
    for (count=0;count<NPTS_signal;count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-NPTS_signal/2)*P[delta],signal[count]);
    }
    fclose(fpout);

    // Deconed.
    fpout=fopen(PS[outfile4],"w");
    for (count=0;count<NPTS_decon;count++){
        fprintf(fpout,"%.10lf\t%lf\n",(count-NPTS_decon/2)*P[delta],decon[0][count]);
    }
    fclose(fpout);

    // FRS_decon.
    fpout=fopen(PS[outfile6],"w");
    for (count=0;count<NPTS_frs;count++){
        fprintf(fpout,"%.10lf\t%lf\n",count*P[delta],frs[count]);
    }
    fclose(fpout);

    // FRS_1.
    fpout=fopen(PS[outfile5],"w");
    for (count=0;count<NPTS_frs;count++){
        fprintf(fpout,"%.10lf\t%lf\n",count*P[delta],frs_1[count]);
    }
    fclose(fpout);


    // Calculate the frequency content of these traces.

    // structure.
    amp=(double *)malloc((NPTS_struct/2+1)*sizeof(double));
    freq=(double *)malloc((NPTS_struct/2+1)*sizeof(double));
    phase=(double *)malloc((NPTS_struct/2+1)*sizeof(double));
    freq_amp_phase(&structure,1,NPTS_struct,P[delta],freq,&amp,&phase);
    normalized(amp,NPTS_struct/2+1);

    fpout=fopen(PS[outfile7],"w");
    for (count=0;count<NPTS_struct/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile8],"w");
    for (count=0;count<NPTS_struct/2+1;count++){
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


    // signal.
    normalized(fft_amp[0],NPTS_signal+1);
    df=1.0/(NPTS_decon-1)/P[delta];

    fpout=fopen(PS[outfile11],"w");
    for (count=0;count<NPTS_signal+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",df*count,fft_amp[0][count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile12],"w");
    for (count=0;count<NPTS_signal+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",df*count,fft_phase[0][count]);
    }
    fclose(fpout);


    // decon.
    amp=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    freq=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    phase=(double *)malloc((NPTS_decon/2+1)*sizeof(double));
    freq_amp_phase(decon,1,NPTS_decon,P[delta],freq,&amp,&phase);
    normalized(amp,NPTS_decon/2+1);

    fpout=fopen(PS[outfile13],"w");
    for (count=0;count<NPTS_decon/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile14],"w");
    for (count=0;count<NPTS_decon/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);
    free(amp);
    free(freq);
    free(phase);

    // Water-filled source frequency response and phase.
    normalized(filled_source_fft_amp,NPTS_signal+1);

    fpout=fopen(PS[outfile15],"w");
    for (count=0;count<NPTS_signal+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",df*count,filled_source_fft_amp[count]);
    }
    fclose(fpout);
    fpout=fopen(PS[outfile16],"w");
    for (count=0;count<NPTS_signal+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",df*count,filled_source_fft_phase[count]);
    }
    fclose(fpout);

    // Post - process frequncy response and phase.

    if (PI[method]==1){

        // Gauss
        post[NPTS_post/2]=gaussian(0,P[sigma_smooth],0);
        for (count=0;count<NPTS_post/2;count++){
            post[count]=gaussian(-(NPTS_post/2-count)*P[delta],P[sigma_smooth],0);
            post[NPTS_post-1-count]=post[count];
        }
    }
    else{

        // BandPass filter.
        for (count=0;count<NPTS_post;count++){
            post[count]=0;
        }
        post[NPTS_post/2]=1;
		butterworth_bp(&post,1,NPTS_post,P[delta],2,2,0.03,0.3,&post);
    }

    amp=(double *)malloc((NPTS_post/2+1)*sizeof(double));
    freq=(double *)malloc((NPTS_post/2+1)*sizeof(double));
    phase=(double *)malloc((NPTS_post/2+1)*sizeof(double));
    freq_amp_phase(&post,1,NPTS_post,P[delta],freq,&amp,&phase);
    normalized(amp,NPTS_post/2+1);

    fpout=fopen(PS[outfile17],"w");
    for (count=0;count<NPTS_post/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],amp[count]);
    }
    fclose(fpout);

    fpout=fopen(PS[outfile18],"w");
    for (count=0;count<NPTS_post/2+1;count++){
        fprintf(fpout,"%.10lf\t%lf\n",freq[count],phase[count]);
    }
    fclose(fpout);

    // Free spaces.

    free(amp);
    free(freq);
    free(phase);

    free(structure);
    free(source);
    free(signal);
    free(decon[0]);
    free(decon);
    free(filled_source_fft_amp);
    free(filled_source_fft_phase);
    free(decon_float);
    free(randdouble);
    free(post);
    free(post_float);
    free(decon_gaussblur);
    free(decon_bandpass);

    free(fft_amp[0]);
    free(fft_amp);
    free(fft_phase[0]);
    free(fft_phase);

    free(divide_amp[0]);
    free(divide_amp);
    free(divide_phase[0]);
    free(divide_phase);

    free(frs);
    free(frs_1);
    free(P2);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
