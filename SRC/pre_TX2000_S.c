#include<stdio.h>
#include<stdlib.h>
#include<ASU_tools.h>
#include<tomography.h>

int main(){

    struct Tomography data;
    int    count;
    FILE   *fpout,*fpout1;
    double depth,Vs;

    // read in tomography.
    read_tomography(&data);

    // Combine the perturbation within PREM ( This is not correct operation )
    fpout=fopen("v.dat","w");
    fpout1=fopen("v_PREM.dat","w");
    for (count=0;count<data.Ndata;count++){

        depth=data.depth[count/(data.Nlon*data.Nlat)];

        Vs=d_vs(depth);

        fprintf(fpout,"%.5lf, ",(1+data.v[count]/100)*Vs);
        fprintf(fpout1,"%.5lf, ",Vs);
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
