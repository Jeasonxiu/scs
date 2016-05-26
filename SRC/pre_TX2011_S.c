#include<stdio.h>
#include<stdlib.h>
#include<ASU_tools.h>
#include<tomography.h>

int main(){

    struct Tomography data;
    int    count,count2;
    FILE   *fpin,*fpout,*fpout1;
    double D[298],V[298],depth,vs;

    // read in tomography.
    read_tomography(&data);

    // read in reference (TX2011_ref).
    fpin=fopen("preprocess.TX2011_ref.txt","r");
    for (count=0;count<298;count++){
        fscanf(fpin,"%lf%lf",&D[count],&V[count]);
    }
    fclose(fpin);

    // Combine the perturbation within PREM ( This is not correct operation )
    fpout=fopen("v.dat","w");
    fpout1=fopen("v_TX2011_ref.dat","w");
    for (count=0;count<data.Ndata;count++){

        depth=data.depth[count/(data.Nlon*data.Nlat)];

        for (count2=0;count2<298;count2++){
            if(D[count2]>=depth){
                break;
            }
        }

        vs=V[count2-1]+(depth-D[count2-1])/(D[count2]-D[count2-1])*(V[count2]-V[count2-1]);

        fprintf(fpout,"%.5lf, ",(1+data.v[count]/100)*vs);
        fprintf(fpout1,"%.5lf, ",vs);
        if (count%6==5){
            fprintf(fpout,"\n");
            fprintf(fpout1,"\n");
        }
    }
    fclose(fpout);
    fclose(fpout1);

    free_tomography(&data);
    return 0;

}
