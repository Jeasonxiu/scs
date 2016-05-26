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
    enum PSenum {infile,outfile,outfile1,outfile2,outfile3,outfile4,outfile5,outfile6,outfile7,outfile8,outfile9,outfile10,outfile11,outfile12,outfile13,outfile14,outfile15,Phase};
    enum Penum  {vfast,vslow,source,receiver,middle};

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
    char   stnm[10],pathfile[200];
    FILE   *fp,*fpin,*fpout,*fpout1,*fpout2,*fpout3,*fpout4,*fpout5,*fpout6,*fpout7,*fpout8,*fpout9,*fpout10,*fpout11,*fpout12,*fpout13,*fpout14,*fpout15;
    double lon,lat,depth,v_model,v_prem,dist_high_source,dist_high_receiver,dist_high_middle,dist_high,dist_whole,lon_previous,lat_previous,depth_previous,RE,dist,extreme_vs,extreme_source,extreme_receiver,extreme_middle,dv,dist_low,dist_low_source,dist_low_receiver,dist_low_middle,extremel_vs,extremel_source,extremel_receiver,extremel_middle;

    RE=6371.0;

    // Read in tomography model.
    read_tomography(&data);

    // Work begin.
    fp=fopen(PS[infile],"r");

    fpout=fopen(PS[outfile],"w");
    fpout1=fopen(PS[outfile1],"w");
    fpout2=fopen(PS[outfile2],"w");
    fpout3=fopen(PS[outfile3],"w");
    fpout4=fopen(PS[outfile4],"w");
    fpout5=fopen(PS[outfile5],"w");
    fpout6=fopen(PS[outfile6],"w");
    fpout7=fopen(PS[outfile7],"w");
    fpout8=fopen(PS[outfile8],"w");
    fpout9=fopen(PS[outfile9],"w");
    fpout10=fopen(PS[outfile10],"w");
    fpout11=fopen(PS[outfile11],"w");
    fpout12=fopen(PS[outfile12],"w");
    fpout13=fopen(PS[outfile13],"w");
    fpout14=fopen(PS[outfile14],"w");
    fpout15=fopen(PS[outfile15],"w");
    fprintf(fpout,"<STNM> <Percentage>\n");
    fprintf(fpout1,"<STNM> <Percentage>\n");
    fprintf(fpout2,"<STNM> <Percentage>\n");
    fprintf(fpout3,"<STNM> <Percentage>\n");
    fprintf(fpout4,"<STNM> <Vs>\n");
    fprintf(fpout5,"<STNM> <Vs>\n");
    fprintf(fpout6,"<STNM> <Vs>\n");
    fprintf(fpout7,"<STNM> <Vs>\n");
    fprintf(fpout8,"<STNM> <Percentage>\n");
    fprintf(fpout9,"<STNM> <Percentage>\n");
    fprintf(fpout10,"<STNM> <Percentage>\n");
    fprintf(fpout11,"<STNM> <Percentage>\n");
    fprintf(fpout12,"<STNM> <Vs>\n");
    fprintf(fpout13,"<STNM> <Vs>\n");
    fprintf(fpout14,"<STNM> <Vs>\n");
    fprintf(fpout15,"<STNM> <Vs>\n");

    while (fscanf(fp,"%s%s",stnm,pathfile)==2){

        fpin=fopen(pathfile,"r");
        if (fpin==NULL){
            printf("File not exists: %s ...\n",pathfile);
            continue;
        }

        count=0;
        dist_whole=0;

        dist_high=0;
        dist_high_source=0;
        dist_high_receiver=0;
        dist_high_middle=0;
        extreme_vs=0;
        extreme_source=0;
        extreme_receiver=0;
        extreme_middle=0;

        dist_low=0;
        dist_low_source=0;
        dist_low_receiver=0;
        dist_low_middle=0;
        extremel_vs=0;
        extremel_source=0;
        extremel_receiver=0;
        extremel_middle=0;

        while (fscanf(fpin,"%lf%lf%lf",&lon,&lat,&depth)==3){

            if (count==0){
                lon_previous=lon;
                lat_previous=lat;
                depth_previous=depth;
            }

            // Calculate the distance.
            sphdist(lon_previous,lat_previous,RE-depth_previous,lon,lat,RE-depth,&dist);
            dist_whole+=dist;

            // Get velocity.
            v_model=getvelocity(&data,(lon_previous+lon)/2,(lat_previous+lat)/2,(depth_previous+depth)/2,PS[Phase]);
            v_prem=d_vs((depth_previous+depth)/2);
            dv=(v_model-v_prem)/v_prem;

            // Judgements.
            if ( dv > P[vfast] ){

                // whole ray_path section.
                dist_high+=dist;

                // near source ray_path section.
                if ( depth<=P[source] && depth_previous<=depth ){
                    dist_high_source+=dist;
                }

                // near receiver ray_path section.
                if ( depth<=P[receiver] && depth_previous>=depth ){
                    dist_high_receiver+=dist;
                }

                // middle ray_path section.
                if ( depth>=P[middle] ){
                    dist_high_middle+=dist;
                }
            }

            if ( dv < P[vslow] ){

                // whole ray_path section.
                dist_low+=dist;

                // near source ray_path section.
                if ( depth<=P[source] && depth_previous<=depth ){
                    dist_low_source+=dist;
                }

                // near receiver ray_path section.
                if ( depth<=P[receiver] && depth_previous>=depth ){
                    dist_low_receiver+=dist;
                }

                // middle ray_path section.
                if ( depth>=P[middle] ){
                    dist_low_middle+=dist;
                }
            }

            // extreme of whole path.
            if (extreme_vs < dv){
                extreme_vs = dv;
            }

            // extreme of source section.
            if (extreme_source < dv && depth<=P[source] && depth_previous<=depth){
                extreme_source = dv;
            }

            // extreme of receiver section.
            if (extreme_receiver < dv && depth<=P[receiver] && depth_previous>=depth){
                extreme_receiver = dv;
            }

            // extreme of middle section.
            if ( extreme_middle < dv && depth>=P[middle] ){
                extreme_middle = dv;
            }

            // extreme of whole path.
            if (extremel_vs > dv){
                extremel_vs = dv;
            }

            // extreme of source section.
            if (extremel_source > dv && depth<=P[source] && depth_previous<=depth){
                extremel_source = dv;
            }

            // extreme of receiver section.
            if (extremel_receiver > dv && depth<=P[receiver] && depth_previous>=depth){
                extremel_receiver = dv;
            }

            // extreme of middle section.
            if ( extremel_middle > dv && depth>=P[middle] ){
                extremel_middle = dv;
            }

            lon_previous=lon;
            lat_previous=lat;
            depth_previous=depth;

            count++;
        }

        fclose(fpin);

        fprintf(fpout,"%s\t%.4e\n",stnm,dist_high/dist_whole);
        fprintf(fpout1,"%s\t%.4e\n",stnm,dist_high_source/dist_whole);
        fprintf(fpout2,"%s\t%.4e\n",stnm,dist_high_receiver/dist_whole);
        fprintf(fpout3,"%s\t%.4e\n",stnm,dist_high_middle/dist_whole);
        fprintf(fpout4,"%s\t%.4e\n",stnm,extreme_vs);
        fprintf(fpout5,"%s\t%.4e\n",stnm,extreme_source);
        fprintf(fpout6,"%s\t%.4e\n",stnm,extreme_receiver);
        fprintf(fpout7,"%s\t%.4e\n",stnm,extreme_middle);

        fprintf(fpout8,"%s\t%.4e\n",stnm,dist_low/dist_whole);
        fprintf(fpout9,"%s\t%.4e\n",stnm,dist_low_source/dist_whole);
        fprintf(fpout10,"%s\t%.4e\n",stnm,dist_low_receiver/dist_whole);
        fprintf(fpout11,"%s\t%.4e\n",stnm,dist_low_middle/dist_whole);
        fprintf(fpout12,"%s\t%.4e\n",stnm,extremel_vs);
        fprintf(fpout13,"%s\t%.4e\n",stnm,extremel_source);
        fprintf(fpout14,"%s\t%.4e\n",stnm,extremel_receiver);
        fprintf(fpout15,"%s\t%.4e\n",stnm,extremel_middle);
    }

    fclose(fp);
    fclose(fpout);
    fclose(fpout1);
    fclose(fpout2);
    fclose(fpout3);
    fclose(fpout4);
    fclose(fpout5);
    fclose(fpout6);
    fclose(fpout7);
    fclose(fpout8);
    fclose(fpout9);
    fclose(fpout10);
    fclose(fpout11);
    fclose(fpout12);
    fclose(fpout13);
    fclose(fpout14);
    fclose(fpout15);


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
