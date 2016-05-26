#include<stdio.h>
#include<stdlib.h>
#include<math.h>

#include<ASU_tools.h>

/***********************************************************
 * 1. Use CC to make a measurement between Stretched S and ScS.
 * 2. No decon the stretched S esf from every ScS waveform.
 * 3. Make ESF of deconed trace to get CCC, Misfit ..
 * 4. Reconstruct ScS and Measure the difference between
 *    original ScS and reconstructed trace.
 *
 * Shule Yu
 * Nov 03 2014
***********************************************************/

int main(int argc, char **argv){

    /****************************
     * Deal within inputs.
    ****************************/
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {cate,fileN};
    enum PSenum {infile};
    enum Penum  {waterlevel,sigma,gwidth,delta,Taper_source,Taper_signal,C1,C2,N1,Nend,S1,S2,AN};

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
    int    N,N2,count2,maxpoint,shift,P1,P2,P3,P4,Pes1,Pes2;
    FILE   *fpin,*fpin1,*fpout,*fpout1;
    char   outfile[200],waveform[200],esf[200],command[200],stnm[10],**st;
    double tmpmax,time,**scs,*es,**ans,*peak,*OnSet,*Nanchor,snr_1,snr_2,misfit,ccc,*snr,*Misfit;

    /****************************
     * Malloc spaces.
    ****************************/
    N=(int)ceil((P[C2]-P[C1])/P[delta])+1;

    scs=(double **)malloc(PI[fileN]*sizeof(double *));
    ans=(double **)malloc(PI[fileN]*sizeof(double *));
    st=(char **)malloc(PI[fileN]*sizeof(char *));

    for (count=0;count<PI[fileN];count++){
        scs[count]=(double *)malloc(N*sizeof(double));
        ans[count]=(double *)malloc(N*sizeof(double));
        st[count]=(char *)malloc(10*sizeof(char));
    }

    es=(double *)malloc(N*sizeof(double));
    peak=(double *)malloc(PI[fileN]*sizeof(double));
    OnSet=(double *)malloc(PI[fileN]*sizeof(double));
    Nanchor=(double *)malloc(PI[fileN]*sizeof(double));
    snr=(double *)malloc(PI[fileN]*sizeof(double));
    Misfit=(double *)malloc(PI[fileN]*sizeof(double));

    /****************************
     * Read in Data.
    ****************************/
    fpin=fopen(PS[infile],"r");
    for (count=0;count<PI[fileN];count++){
        fscanf(fpin,"%s%s%s%lf%lf%lf",st[count],waveform,esf,&peak[count],&OnSet[count],&Nanchor[count]);

        // Read in ScS.
        fpin1=fopen(waveform,"r");
        count2=0;
        while (fscanf(fpin1,"%lf%lf",&time,&scs[count][count2])==2){
            if (P[C1]<=time && time<=P[C2] && count2<N-1 ){
                count2++;
            }
        }
        fclose(fpin1);
        taperd(scs[count],count2,P[Taper_source]);
    }
    fclose(fpin);
    N=count2;

    // Read in E.S.F.
    fpin=fopen(esf,"r");
    count=0;
    while (fscanf(fpin,"%lf%lf",&time,&es[count])==2){
        count++;
    }
    N2=count;
    fclose(fpin);
    taperd(es,N2,P[Taper_signal]);

    // Estimate half height of ESF.
    max_ampd(es,N2,&P1);
    for (count=P1;count>0;count--){
        if (fabs(es[count])<0.5){
            Pes1=count;
            break;
        }
    }
    for (count=P1;count<N2;count++){
        if (fabs(es[count])<0.5){
            Pes2=count;
            break;
        }
    }

    /****************************
     * Make No decon.
    ****************************/
    for (count=0;count<PI[fileN];count++){
        for (count2=0;count2<N;count2++){
            ans[count][count2]=scs[count][count2];
        }
    }

    /****************************
     * Make StretchDecon estimation.
    ****************************/
    sprintf(outfile,"tmpfile_%d_StretchDeconInfo",PI[cate]);
    fpout=fopen(outfile,"w");
    fprintf(fpout,"<STNM> <peak> <SNR_1> <SNR_2> <SNR> <CCC_St> <Misfit_St> <Cate> <N1Time> <S1Time> <N2Time> <N3Time>\n");
    for (count=0;count<PI[fileN];count++){

        // find deconed pulse's peak.
        P1=(int)((peak[count]-P[C1])/P[delta]);
        if (fabs(ans[count][P1])>0.5){
            for (count2=P1;count2>0;count2--){
                if (fabs(ans[count][count2])<0.5){
                    P1=count2;
                    break;
                }
            }
            for (count2=P1+1;count2<N;count2++){
                if (fabs(ans[count][count2])<0.5){
                    P2=count2;
                    break;
                }
            }
            max_ampd(ans[count]+P1,P2-P1,&maxpoint);
            maxpoint+=P1;
            tmpmax=ans[count][maxpoint];
        }
        else{
            P1=(int)((peak[count]-P[C1]-3.0)/P[delta]);
            P2=(int)(6.0/P[delta]);
            max_ampd(ans[count]+P1,P2,&maxpoint);
            maxpoint+=P1;
            tmpmax=ans[count][maxpoint];
        }

        // Flip it to pulse up. Normalize it to the pulse.
        for (count2=0;count2<N;count2++){
            ans[count][count2]/=tmpmax;
        }

        // Do CCC estimation betweeen the stretched and tapered S and ScS traces.
        P1=(int)((peak[count]-P[C1])/P[delta])-N2/2;
        CC(scs[count]+P1,N2,es,N2,&shift,&ccc);

        // Do Misfit estimation betweeen the stretched S and ScS traces.
        P1=(int)((peak[count]-P[C1])/P[delta]);
        for (count2=P1;count2>P1-N2/2;count2--){
            if (fabs(scs[count][count2])<0.5){
                P2=count2;
                break;
            }
        }
        for (count2=P1;count2<P1+N2/2;count2++){
            if (fabs(scs[count][count2])<0.5){
                P3=count2;
                break;
            }
        }
        Misfit[count]=1.0*(P3-P2);
        misfit=Misfit[count]/(Pes2-Pes1)-1;

        // Do normal SNR estimation on deconed trace.
        P1=(int)((Nanchor[count]-P[C1]+P[N1])/P[delta]);
        P2=(int)((P[Nend]-P[N1])/P[delta]);
        P3=maxpoint+(int)(P[S1]/P[delta]);
        P4=(int)((P[S2]-P[S1])/P[delta]);
        snr[count]=snr_envelope(ans[count],N,P1,P2,P3,P4);

        // Do Adjacent Noise estimation on deconed trace.
        P2=(int)(P[AN]/P[delta]);
        P1=P3-P2;
        snr_1=snr_envelope(ans[count],N,P1,P2,P3,P4);
        snr_2=snr_envelope(ans[count],N,P3+P4,P2,P3,P4);

        // Output every deconved trace's info.
        fprintf(fpout,"%s\t%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf%11.3lf\t%d%11.3lf%11.3lf%11.3lf%11.3lf\n"
        ,st[count],P[C1]+maxpoint*P[delta],snr_1,snr_2,snr[count],ccc,misfit,PI[cate],Nanchor[count]+P[N1],maxpoint*P[delta]+P[C1]+P[S1],P[C1]+(P3+P4)*P[delta],P[C1]+P1*P[delta]);

        // Output every deconved trace.
        sprintf(outfile,"%s.trace",st[count]);
        fpout1=fopen(outfile,"w");
        for (count2=0;count2<N;count2++){
            fprintf(fpout1,"%.4lf\t%.5e\n",P[C1]+count2*P[delta],ans[count][count2]);
        }
        fclose(fpout1);
    }
    fclose(fpout);

    /********************************************
     * Output tapered Stretched S ESF of this Cate
    ********************************************/
    sprintf(outfile,"%d.esf",PI[cate]);
    fpout=fopen(outfile,"w");
    for (count=0;count<N2;count++){
        fprintf(fpout,"%.4lf\t%.5e\n",time-(N2-1)*P[delta]+count*P[delta],es[count]);
    }
    fclose(fpout);

    /************************
     *  Free spaces.
    ************************/
    for (count=0;count<PI[fileN];count++){
        free(scs[count]);
        free(st[count]);
        free(ans[count]);
    }
    free(scs);
    free(st);
    free(ans);

    free(es);
    free(peak);
    free(OnSet);
    free(Nanchor);
    free(snr);
    free(Misfit);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
