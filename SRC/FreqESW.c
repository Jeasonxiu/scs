#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>
#include<fftw3.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {NR,nptsy};
    enum PSenum {infile};
//     enum Penum  {};

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
    int count2;
    FILE *fp,*fpin,*fpout;
    char tmpstr1[300],tmpstr2[300];
    double *time,*amp,*freq,*spectrum,*phase,dt,maxfreq,dfreq;

    amp=(double *)malloc(PI[nptsy]*sizeof(double));
    time=(double *)malloc(PI[nptsy]*sizeof(double));
    
    freq=(double *)malloc((PI[nptsy]/2+1)*sizeof(double));
    spectrum=(double *)malloc((PI[nptsy]/2+1)*sizeof(double));
    phase=(double *)malloc((PI[nptsy]/2+1)*sizeof(double));

    fftw_complex *out;
    fftw_plan    p1; 
    fftw_plan    p2; 

    out=(fftw_complex *)fftw_malloc((PI[nptsy]/2+1)*sizeof(fftw_complex));
    p1=fftw_plan_dft_r2c_1d(PI[nptsy],amp,out,FFTW_MEASURE);
    p2=fftw_plan_dft_c2r_1d(PI[nptsy],out,amp,FFTW_MEASURE);


    fp=fopen(PS[infile],"r");
    for (count=0;count<PI[NR];count++){
        fscanf(fp,"%s%s",tmpstr1,tmpstr2);
        fpin=fopen(tmpstr1,"r");
        fpout=fopen(tmpstr2,"w");

        for (count2=0;count2<PI[nptsy];count2++){
            fscanf(fpin,"%lf%lf",&time[count2],&amp[count2]);
        }

        dt=time[1]-time[0];
        maxfreq=0.5/dt;
        dfreq=maxfreq/(PI[nptsy]/2.0);
// printf("%lf\t%lf\t%lf\n",dt,maxfreq,dfreq);

        fftw_execute(p1);

        for (count2=0;count2<PI[nptsy]/2+1;count2++){
            freq[count2]=dfreq*count2;
            spectrum[count2]=pow(out[count2][0],2)+pow(out[count2][1],2);
            phase[count2]=atan2(out[count2][1],out[count2][0]);
            fprintf(fpout,"%.15e\t%.15e\t%.15e\t%.15e\t%.15e\n",freq[count2],out[count2][0],out[count2][1],spectrum[count2],phase[count2]);
        }
        
        fclose(fpin);
        fclose(fpout);
    }
    fclose(fp);


    // Free spaces.
    fftw_destroy_plan(p1);
    fftw_destroy_plan(p2);
    fftw_free(out);

    free(amp);

    free(time);
    
    free(freq);
    free(spectrum);
    free(phase);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
