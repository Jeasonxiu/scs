#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<string.h>
#include<ASU_tools.h>

int main(int argc, char **argv){

    // Deal with inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

    enum PIenum {nptsx};
    enum PSenum {infile,outfile,outfile2};
    enum Penum  {Time,delta};

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


    /****************************************************************

                              Job begin.

    ****************************************************************/
	FILE   *fp,*fpin,*fpout,*fpout2;
	double time,**data,CC,Pnorm;
	char   Tracefile[100],**ModelName;
	int    Cnt,Cnt2,NPTS;

	data=(double **)malloc(PI[nptsx]*sizeof(double *));
	ModelName=(char **)malloc(PI[nptsx]*sizeof(char *));
	for (Cnt=0;Cnt<PI[nptsx];Cnt++){
		data[Cnt]=(double *)malloc(((int)(P[Time]/P[delta])+10)*sizeof(double));
		ModelName[Cnt]=(char *)malloc(20*sizeof(char));
	}

	fp=fopen(PS[infile],"r");

	// Read in ScS Traces.
	for (Cnt=0;Cnt<PI[nptsx];Cnt++){

		fscanf(fp,"%s",Tracefile);
		fpin=fopen(Tracefile,"r");
		strcpy(ModelName[Cnt],"xx");

		Cnt2=0;
		while (fscanf(fpin,"%lf%lf",&time,&data[Cnt][Cnt2])==2){
			if (time<=P[Time]){
				++Cnt2;
			}
		}
		NPTS=Cnt2;

		fclose(fpin);
	}

	fclose(fp);

	fpout=fopen(PS[outfile],"w");
	fpout2=fopen(PS[outfile2],"w");

	for (Cnt=0;Cnt<PI[nptsx];Cnt++){
		for (Cnt2=0;Cnt2<PI[nptsx];Cnt2++){
			if (Cnt==Cnt2){
				continue;
			}

			CC_static(data[Cnt],NPTS,data[Cnt2],NPTS,&CC);
			Pnorm=p_norm_err(data[Cnt],data[Cnt2],NPTS,2);
			fprintf(fpout,"%.4e\n",CC);
			fprintf(fpout2,"%.4e\n",Pnorm);
		}
	}
	fclose(fpout);
	fclose(fpout2);

    // Free spaces.
	for (Cnt=0;Cnt<PI[nptsx];Cnt++){
		free(ModelName[Cnt]);
		free(data[Cnt]);
	}
	free(ModelName);
	free(data);

    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
