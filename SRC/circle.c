#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<ASU_tools.h>

/***********************************************************
 * Generate a geographic circle locations ( different azimuth )
 * around a certain geographic point.
***********************************************************/

int main(int argc, char **argv){
    int    count,npts;
    double evlo,evla,az,dist,daz;

    evlo=strtod(argv[1],NULL);
    evla=strtod(argv[2],NULL);
    dist=strtod(argv[3],NULL);
    npts=3600;

    double *pla,*plo,*ppla,*pplo;
    pla=(double *)malloc(npts*sizeof(double));
    plo=(double *)malloc(npts*sizeof(double));
    ppla=(double *)malloc(npts*sizeof(double));
    pplo=(double *)malloc(npts*sizeof(double));

    daz=360.0/(npts-1);
    az=0;

    for (count=0;count<npts;count++){
        waypoint_az(evlo,evla,az,dist,plo+count,pla+count);
        az+=daz;
    }

    for (count=1;count<npts-1;count++){
        ppla[count]=(pla[count-1]+pla[count]+pla[count+1])/3.0;
        pplo[count]=(plo[count-1]+plo[count]+plo[count+1])/3.0;
    }
    ppla[npts-1]=(pla[npts-2]+pla[npts-1]+pla[0])/3.0;
    pplo[npts-1]=(plo[npts-2]+plo[npts-1]+plo[0])/3.0;
    ppla[0]=(pla[npts-1]+pla[0]+pla[1])/3.0;
    pplo[0]=(plo[npts-1]+plo[0]+plo[1])/3.0;

    for (count=0;count<npts;count++){
        printf("%11.3lf\t%11.3lf\n",pplo[count],ppla[count]);
    }

    free(pla);
    free(plo);
    free(ppla);
    free(pplo);

    return 0;
}
