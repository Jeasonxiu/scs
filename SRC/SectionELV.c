#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>
#include<tomography.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {infile,Phase,EQ};
//     enum Penum  {D1,D2,D3,D4};

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

    struct Tomography data;
    int    count2;
    char   stnm[10],Spathfile[200],ScSpathfile[200],tmpstr[200];
    FILE   *fp,*fpin,*fpout,*fpout1;
    double lon,lat,depth,v_model,v_prem,lon_previous,lat_previous,depth_previous,extreme_vs,dv;

    // Read in tomography model.
    read_tomography(&data);

    // Work begin.

    for (count=0;count<2*(double_num-1);count++){

        fp=fopen(PS[infile],"r");

        sprintf(tmpstr,"%s.SectionL_S_%d",PS[EQ],count+1);
        fpout=fopen(tmpstr,"w");
        fprintf(fpout,"<STNM> <Vs>\n");

        sprintf(tmpstr,"%s.SectionL_ScS_%d",PS[EQ],count+1);
        fpout1=fopen(tmpstr,"w");
        fprintf(fpout1,"<STNM> <Vs>\n");

        while (fscanf(fp,"%s%s%s",stnm,Spathfile,ScSpathfile)==3){

            // S.
            fpin=fopen(Spathfile,"r");

            if (fpin==NULL){
                printf("%s\n",Spathfile);
                continue;
            }

            count2=0;
            extreme_vs=0;
            while (fscanf(fpin,"%lf%lf%lf",&lon,&lat,&depth)==3){

                if (count2==0){
                    lon_previous=lon;
                    lat_previous=lat;
                    depth_previous=depth;
                }

                // Get velocity.
                v_model=getvelocity(&data,(lon_previous+lon)/2,(lat_previous+lat)/2,(depth_previous+depth)/2,PS[Phase]);
                v_prem=d_vs((depth_previous+depth)/2);
                dv=(v_model-v_prem)/v_prem;

                // extreme of whole path.
                if (count<double_num-1){
                    if (extreme_vs > dv && depth_previous <= depth && P[count] <= depth && depth <= P[count+1]){
                        extreme_vs = dv;
                    }
                }
                else{
                    if (extreme_vs > dv && depth_previous >= depth && P[2*(double_num-1)-count-1] <= depth && depth <= P[2*(double_num-1)-count]){
                        extreme_vs = dv;
                    }
                }

                lon_previous=lon;
                lat_previous=lat;
                depth_previous=depth;

                count2++;
            }
            fclose(fpin);
            fprintf(fpout,"%s\t%.4e\n",stnm,extreme_vs);

            // ScS.
            fpin=fopen(ScSpathfile,"r");

            if (fpin==NULL){
                printf("%s\n",ScSpathfile);
                continue;
            }

            count2=0;
            extreme_vs=0;
            while (fscanf(fpin,"%lf%lf%lf",&lon,&lat,&depth)==3){

                if (count2==0){
                    lon_previous=lon;
                    lat_previous=lat;
                    depth_previous=depth;
                }

                // Get velocity.
                v_model=getvelocity(&data,(lon_previous+lon)/2,(lat_previous+lat)/2,(depth_previous+depth)/2,PS[Phase]);
                v_prem=d_vs((depth_previous+depth)/2);
                dv=(v_model-v_prem)/v_prem;

                // extreme of whole path.
                if (count<double_num-1){
                    if (extreme_vs > dv && depth_previous <= depth && P[count] <= depth && depth <= P[count+1]){
                        extreme_vs = dv;
                    }
                }
                else{
                    if (extreme_vs > dv && depth_previous >= depth && P[2*(double_num-1)-count-1] <= depth && depth <= P[2*(double_num-1)-count]){
                        extreme_vs = dv;
                    }
                }

                lon_previous=lon;
                lat_previous=lat;
                depth_previous=depth;

                count2++;
            }
            fclose(fpin);
            fprintf(fpout1,"%s\t%.4e\n",stnm,extreme_vs);

        }
        fclose(fp);
        fclose(fpout);
        fclose(fpout1);

    }

    // Free spaces.

    free_tomography(&data);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
