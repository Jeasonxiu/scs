#include<stdio.h>
#include<stdlib.h>
#include<assert.h>
#include<string.h>
#include<math.h>
#include<sac.h>
#include<sacio.h>
#include<ASU_tools.h>

/*************************************************************************
 * 1. Use CC to make a measurement between Stretched S and ScS trace.
 * 2. Output sac file for Ammon's iterative deconvolution.
 *
 * Shule Yu
 * Jul 12 2015
*************************************************************************/

int main(int argc, char **argv){

    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {cate,fileN};
    enum PSenum {infile,ESFfile};
    enum Penum  {delta,C1,C2,Taper_signal};

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
    int    NPTS_signal,NPTS_source,count2,*shift,P0,*P2,P3,P4,Pes1,Pes2,polarity;
    FILE   *fp,*fpin,*fpout;
    char   outfile[200],ScSfile[200],**stnm;
    double time,peak,**scs,*esf,ccc,misfit,snr,snr_1,snr_2;

    // Set up trace length.
    NPTS_signal=(int)ceil((P[C2]-P[C1])/P[delta]);


    P2=(int *)malloc(PI[fileN]*sizeof(int));
    scs=(double **)malloc(PI[fileN]*sizeof(double *));
    stnm=(char **)malloc(PI[fileN]*sizeof(char *));
    shift=(int *)malloc(PI[fileN]*sizeof(int));

    for (count=0;count<PI[fileN];count++){
        scs[count]=(double *)malloc(NPTS_signal*sizeof(double));
        stnm[count]=(char *)malloc(20*sizeof(char));
    }

    esf=(double *)malloc(NPTS_signal*sizeof(double));

    // Read in E.S.F.
    // Find its peak position.
    fp=fopen(PS[ESFfile],"r");
    NPTS_source=0;
    while (fscanf(fp,"%lf%lf",&time,&esf[NPTS_source])==2){
        if ( -20 <= time && time <= 25 ){
            NPTS_source++;
        }
    }
    fclose(fp);

    max_ampd(esf,NPTS_source,&P0);


    // Read in ScS traces.
    fp=fopen(PS[infile],"r");
    for (count=0;count<PI[fileN];count++){

        fscanf(fp,"%s%s%lf",stnm[count],ScSfile,&peak);

        // Read in ScS traces, shift to ScS peak @ time=0.
        fpin=fopen(ScSfile,"r");

        count2=0;
        while (fscanf(fpin,"%lf%lf",&time,&scs[count][count2])==2){

            if ( P[C1] <= time-peak ){
                count2++;
            }

            if ( count2==NPTS_signal ){
                break;
            }
        }

        fclose(fpin);

        // Find the peak position on ScS:
        P2[count]=(int)ceil(-P[C1]/P[delta]);

        // Taper the edges.
        taperd(scs[count],NPTS_signal,P[Taper_signal]);

    }
    fclose(fp);

    /****************************
       Do some other estimations.
    ****************************/

    // Find Half-height position on ESF.
    for (count=P0;count>0;count--){
        if (fabs(esf[count])<0.5){
            Pes1=count;
            break;
        }
    }
    for (count=P0;count<NPTS_source;count++){
        if (fabs(esf[count])<0.5){
            Pes2=count;
            break;
        }
    }

    sprintf(outfile,"tmpfile_%d_StretchDeconInfo",PI[cate]);
    fpout=fopen(outfile,"w");
    fprintf(fpout,"<STNM> <SNR_1> <SNR_2> <SNR> <Shift_St> <CCC_St> <Misfit_St> <Cate> <N1Time> <S1Time> <N2Time> <N3Time> <ESFPeak>\n");

    for (count=0;count<PI[fileN];count++){


        // Do CCC estimation betweeen the stretched-tapered S esf and ScS traces.
        P3=(int)ceil(10/P[delta]);
        P4=(int)ceil(15/P[delta]);
        polarity=scs[count][P2[count]]>0?1:-1;
        CC_positive(scs[count]+P2[count]-P3,P3+P4,esf+P0-P3,P3+P4,&shift[count],&ccc,polarity);

        // Do Misfit estimation betweeen the stretched and tapered S esf and ScS traces.
        for (count2=P2[count];count2>0;count2--){
            if (fabs(scs[count][count2])<0.5){
                P3=count2;
                break;
            }
        }
        for (count2=P2[count];count2<NPTS_signal;count2++){
            if (fabs(scs[count][count2])<0.5){
                P4=count2;
                break;
            }
        }
        misfit=1.0*(P4-P3)/(Pes2-Pes1)-1;

        // Do SNR estimation on deconed trace.
        snr=100;
        snr_1=100;
        snr_2=100;

        // Output estimations.
        fprintf(fpout,"%s\t%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf\t%d%11.3lf%11.3lf%11.3lf%11.3lf%11.4lf\n"
        ,stnm[count],snr_1,snr_2,snr,P[delta]*shift[count],ccc,misfit,PI[cate],-200.0,-100.0,-100.0,-100.0,P0*P[delta]);

    }
    fclose(fpout);

    // Write out SAC files for simmon's code.
    // Shift the peak of ScS at time=100 sec.
    // Shift the peak of esf at time=30 sec.

    char  name[100];
    int   nerr,max;
    float beg,del;
    float signal_float[8000],source_float[3000];

    max=NPTS_source;
    beg=0;
//     beg=30-P0*P[delta];
    del=0.025;

    sprintf(name,"%d.esf.sac",PI[cate]);
    for (count=0;count<NPTS_source;count++){
        source_float[count]=esf[count];
    }   
    wsac1(name,source_float,&max,&beg,&del,&nerr,strlen(name));

    max=NPTS_signal;
    for (count=0;count<PI[fileN];count++){

        beg=100-P2[count]*P[delta];

        sprintf(name,"%s.tapered.sac",stnm[count]);
        for (count2=0;count2<NPTS_signal;count2++){
            signal_float[count2]=(scs[count][P2[count]]>0?1:-1)*scs[count][count2];
        }   
        wsac1(name,signal_float,&max,&beg,&del,&nerr,strlen(name));
    }

    // Output tapered source, shift the peak to time=0.
    sprintf(outfile,"%d.esf",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<NPTS_source;count++){
        fprintf(fpout,"%.4lf\t%.5e\n",(count-P0)*P[delta],esf[count]);
    }
    fclose(fpout);

    // Output tapered signal.
    for (count=0;count<PI[fileN];count++){
        sprintf(outfile,"%s.tapered",stnm[count]);
        fpout=fopen(outfile,"w");
        for (count2=0;count2<NPTS_signal;count2++){
            fprintf(fpout,"%.4lf\t%.5e\n",P[C1]+count2*P[delta],scs[count][count2]);
        }
        fclose(fpout);
    }

    /************************
     *  Free spaces.
    ************************/
    for (count=0;count<PI[fileN];count++){
        free(scs[count]);
        free(stnm[count]);
    }
    free(scs);
    free(stnm);
	free(shift);
	free(P2);
    free(esf);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
