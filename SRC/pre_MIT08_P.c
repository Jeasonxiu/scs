#include<stdio.h>
#include<stdlib.h>
#include<ASU_tools.h>
#include<tomography.h>

int main(){

    struct Tomography data;
    int    count;
    FILE   *fpout,*fpout1;
    double absoluteVp,Vprem;

    read_tomography(&data);

    // Combine the perturbation within PREM ( This is not correct operation )
    fpout=fopen("v.dat","w");
    fpout1=fopen("v_PREM.dat","w");
    for (count=0;count<data.Ndata;count++){

        Vprem=d_vp(data.depth[count/(data.Nlon*data.Nlat)]);

        absoluteVp=(1+data.v[count]/100)*Vprem;

        fprintf(fpout,"%.6lf, ",absoluteVp);
        fprintf(fpout1,"%.6lf, ",Vprem);

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
