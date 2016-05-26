#include<stdio.h>
#include<stdlib.h>
#include<math.h>

#include<ASU_tools.h>

int main(int argc, char **argv){

    int    *flag,*P;
    FILE   *fpin,*fpout;
    double deg,time,dx,ddx;
    int    npts,reverse,section_num,section_num_new;
    int    count,count2,count3,newlength;
    double *phase_deg,*phase_time,*x,*y,*xx,*yy,*newx,*newy,*newy_tmp;
    double timemax=strtod(argv[3],NULL);

    fpout=fopen(argv[2],"w");
    dx=0.5;

    // Read in Phase data.
    fpin=fopen(argv[1],"r");
    npts=0;
    while (fscanf(fpin,"%lf%lf",&deg,&time)==2){
        npts++;
    }
    fclose(fpin);
    phase_deg=(double *)malloc(npts*sizeof(double));
    phase_time=(double *)malloc(npts*sizeof(double));
    fpin=fopen(argv[1],"r");
    for (count=0;count<npts;count++){
        fscanf(fpin,"%lf%lf",&phase_deg[count],&phase_time[count]);
    }
    fclose(fpin);

    // Find sections.
    flag=(int *)malloc(npts*sizeof(int));
    for (count=0;count<npts;count++){
        flag[count]=0;
    }

    section_num=1;
    for (count=1;count<npts-1;count++){
        if (phase_deg[count]>phase_deg[count-1] && phase_deg[count]>phase_deg[count+1]){
            flag[count]=1;
            section_num++;
        }
        if (phase_deg[count]<phase_deg[count-1] && phase_deg[count]<phase_deg[count+1]){
            flag[count]=-1;
            section_num++;
        }
    }
    if (phase_deg[npts-2]<phase_deg[npts-1]){
        flag[npts-1]=1;
    }
    else {
        flag[npts-1]=-1;
    }

    P=(int *)malloc((1+section_num)*sizeof(int));
    x=(double *)malloc(2*section_num*sizeof(double));
    y=(double *)malloc(2*section_num*sizeof(double));

    P[0]=0;
    count2=1;
    for (count=0;count<npts;count++){
        if (flag[count]!=0){
            P[count2]=count;
            count2++;
        }
    }

    for (count=0;count<section_num;count++){
        x[count]=phase_deg[P[count]];
        y[count]=phase_deg[P[count+1]];
    }

    // Union these sections into several big ones.
    xx=(double *)malloc(section_num*sizeof(double));
    yy=(double *)malloc(section_num*sizeof(double));
    union_sets(x,y,xx,yy,section_num,&section_num_new);

    // For each big sections, search for time values.
    for (count=0;count<section_num_new;count++){

        newlength=1+(int)ceil((yy[count]-xx[count])/dx);
        ddx=(yy[count]-xx[count])/(newlength-1);
        newx=(double *)malloc(newlength*sizeof(double));
        newy=(double *)malloc(newlength*sizeof(double));
        newy_tmp=(double *)malloc(newlength*sizeof(double));
        for (count2=0;count2<newlength;count2++){
            newx[count2]=xx[count]+ddx*count2;
            newy[count2]=+1/0.0;
        }

        for (count2=0;count2<section_num;count2++){
            reverse=0;
            if (fmin(x[count2],y[count2])>yy[count] || fmax(x[count2],y[count2])<xx[count]){
                continue;
            }
            if (flag[P[count2+1]]==-1){
                reverse_array(phase_deg+P[count2],P[count2+1]-P[count2]+1);
                reverse_array(phase_time+P[count2],P[count2+1]-P[count2]+1);
                reverse=1;
            }

            wiginterpd(phase_deg+P[count2],phase_time+P[count2],(P[count2+1]-P[count2]+1),newx,newy_tmp,newlength,1);

            for (count3=0;count3<newlength;count3++){
                if (phase_deg[P[count2]]<=newx[count3] && newx[count3]<=phase_deg[P[count2+1]]){
                    if (newy[count3]>newy_tmp[count3]){
                        newy[count3]=newy_tmp[count3];
                    }
                }
            }

            if (reverse==1){
                reverse_array(phase_deg+P[count2],P[count2+1]-P[count2]+1);
                reverse_array(phase_time+P[count2],P[count2+1]-P[count2]+1);
            }
        }
        for (count2=0;count2<newlength;count2++){
            if (newy[count2]<timemax){
                fprintf(fpout,"%11.3lf%11.3lf\n",newx[count2],newy[count2]);
            }
        }
        free(newx);
        free(newy);
        free(newy_tmp);
    }
    return 0;
}
