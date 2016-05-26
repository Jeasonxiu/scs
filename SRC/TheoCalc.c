#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#include<ASU_tools.h>

// Calculate the theoretic reflection / transmission
// coefficients/ travel-time for a given ULVZ layer.

int main(int argc, char **argv){

    // Deal within inputs.
    int    int_num,string_num,double_num,count;
    int    *PI;
    char   **PS;
    double *P;

//     enum PIenum {};
    enum PSenum {outfile};
    enum Penum  {EVDE_MIN,EVDE_MAX,DELTA_EVDE,DIST_MIN,DIST_MAX,DELTA_DIST,Thickness_MIN,Thickness_MAX,Thickness_INC,D_Vs_MIN,D_Vs_MAX,D_Vs_INC,D_rho_MIN,D_rho_MAX,D_rho_INC};

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
    int    npts,NPTS;
	double Vs,Rho;
	double gcarc,evde,H,dvs,drho;
	double A,B,C,D,E,tmpval,RE;

	// R's are in km.
	double *R_Source,*R_Surface,*R_ULVZ_Top,*R_CMB;

	// rayp's are in deg/sec.
    double rayp_ScS,rayp_SvS,rayp_ScS_ulvz,rayp_ScscS,drayp;
	double *rayp_source,*rayp_receiver,*rayp_CMB;

	// positions are in deg.
	double position_ScS,position_ScS_in,position_ScS_ulvz,position_ScscS_up,position_ScscS_in,position_ScscS,position_SvS;
	double *position_source,*position_receiver,*position_CMB,dl;

    char   command[100],*Phase;
    FILE   *fpin,*fpout;
	double Ratio,StS,STS,SvS,SuS;

	// Some values.
    RE=6371.0;
    dl=0.001;
    NPTS=5001;

    prem(2891.0,1,0,&Rho,&tmpval,&tmpval,&Vs,&tmpval,&tmpval,&tmpval,&tmpval);

    Phase=(char *)malloc(10*sizeof(char));
    sprintf(Phase,"ScS");

	// Malloc searching space.
    rayp_source=(double *)malloc(NPTS*sizeof(double));
    rayp_receiver=(double *)malloc(NPTS*sizeof(double));
    rayp_CMB=(double *)malloc(NPTS*sizeof(double));

    position_source=(double *)malloc(NPTS*sizeof(double));
    position_receiver=(double *)malloc(NPTS*sizeof(double));
    position_CMB=(double *)malloc(NPTS*sizeof(double));

    R_Source=(double *)malloc(NPTS*sizeof(double));
    R_ULVZ_Top=(double *)malloc(NPTS*sizeof(double));
    R_Surface=(double *)malloc(NPTS*sizeof(double));
    R_CMB=(double *)malloc(NPTS*sizeof(double));

    for (count=0;count<NPTS;count++){
        R_Surface[count]=RE;
        R_CMB[count]=RE-2891.0;
    }

    fpout=fopen(PS[outfile],"a");

    evde=P[EVDE_MIN];
    while (evde<=P[EVDE_MAX]){

        for (count=0;count<NPTS;count++){
            R_Source[count]=RE-evde;
        }

        gcarc=P[DIST_MIN];
        while (gcarc<=P[DIST_MAX]){


            // Find original ScS ray parameter at CMB.
            bottom_location(0.0,0.0,evde,gcarc,0.0,Phase,&position_ScS,&tmpval,&tmpval);
            sprintf(command,"taup_time -h %.2lf -ph ScS -deg %.2lf --rayp -o stdout",evde,gcarc);
            fpin=popen(command,"r");
            fscanf(fpin,"%lf",&rayp_ScS);
            fclose(fpin);
            rayp_ScS*=(180/M_PI);


            // Define search area.
            for (count=0;count<NPTS;count++){
                position_source[count]=position_ScS-(NPTS-1)*dl/2+count*dl;
                position_receiver[count]=gcarc-position_source[count];
            }


            H=P[Thickness_MIN];
            while(H<=P[Thickness_MAX]){

                for (count=0;count<NPTS;count++){
                    R_ULVZ_Top[count]=RE-2891.0+H;
                }


                // Begin search.
                findrayp(R_Source,R_ULVZ_Top,position_source,NPTS,1,rayp_source);
                findrayp(R_Surface,R_ULVZ_Top,position_receiver,NPTS,1,rayp_receiver);


                // Find SvS position.
                drayp=1/0.0;
                for (count=0;count<NPTS;count++){
                    if (drayp>fabs(rayp_source[count]-rayp_receiver[count])){

                        drayp=fabs(rayp_source[count]-rayp_receiver[count]);
                        position_SvS=position_source[count];
                        rayp_SvS=(rayp_source[count]+rayp_receiver[count])/2;

                    }
                }

                dvs=P[D_Vs_MIN];
                while(dvs<=P[D_Vs_MAX]){

                    // (ScS_ULVZ) Define CMB search area, and count how many grids need to search.
                    for (count=0;count<NPTS;count++){

						if (position_source[count]>=position_ScS){
							break;
						}

						int count2;
                        drayp=1/0.0;
                        for (count2=0;count2<NPTS;count2++){
                            if (drayp>fabs(rayp_source[count]-rayp_receiver[count2])){
                                drayp=fabs(rayp_source[count]-rayp_receiver[count2]);
								// position_CMB is supposed to be the center point where rayp_receiver[count2]=rayp_source[count].
                                position_CMB[count]=(position_source[count2]-position_source[count])/2;
                            }
                        }
                    }
                    npts=count;

                    // Begin search.
                    findrayp_ulvz(R_ULVZ_Top,R_CMB,position_CMB,npts,1,rayp_CMB,dvs,H);

                    // Find ULVZ ScS bouncing position.
                    drayp=1/0.0;
                    for (count=0;count<npts;count++){

                        if (drayp>fabs(rayp_source[count]-rayp_CMB[count])){
                            drayp=fabs(rayp_source[count]-rayp_CMB[count]);
                            position_ScS_ulvz=position_source[count]+position_CMB[count];
                            position_ScS_in=position_source[count];
                            rayp_ScS_ulvz=(rayp_source[count]+rayp_CMB[count])/2;
                        }
                    }

                    // (ScscS) Define CMB search area.
                    for (count=0;count<NPTS;count++){

						if (position_source[count]>position_ScS){
							break;
						}

						int count2;
                        drayp=1/0.0;
                        for (count2=0;count2<NPTS;count2++){
                            if (drayp>fabs(rayp_source[count]-rayp_receiver[count2])){
                                drayp=fabs(rayp_source[count]-rayp_receiver[count2]);
                                position_CMB[count]=(position_source[count2]-position_source[count])/4;
                            }
                        }

                    }
                    npts=count;

                    // Begin search.
                    findrayp_ulvz(R_ULVZ_Top,R_CMB,position_CMB,npts,1,rayp_CMB,dvs,H);

                    // Find altered ScS position.
                    drayp=1/0.0;
                    for (count=0;count<npts;count++){
                        if (drayp>fabs(rayp_source[count]-rayp_CMB[count])){
                            drayp=fabs(rayp_source[count]-rayp_CMB[count]);
                            position_ScscS=position_source[count]+position_CMB[count];
                            position_ScscS_up=position_source[count]+2*position_CMB[count];
                            position_ScscS_in=position_source[count];
                            rayp_ScscS=(rayp_source[count]+rayp_CMB[count])/2;
                        }
                    }

                    drho=P[D_rho_MIN];
                    while(drho<=P[D_rho_MAX]){

//     Notes for the names.
//     A=sin(incident);
//     B=sin(transmision);
//     C=cos(incident);
//     D=cos(transmision);
//     E=denominator;

                        A=(rayp_ScS/3480.0)*Vs;
                        B=A*dvs;
                        C=sqrt(1-pow(A,2));
                        D=sqrt(1-pow(B,2));
                        E=Rho*Vs*C+Rho*drho*Vs*dvs*D;

                        SvS=(Rho*Vs*C-Rho*drho*Vs*dvs*D)/E;
                        SuS=-(Rho*Vs*C-Rho*drho*Vs*dvs*D)/E;
                        StS=Rho*Vs*C*2/E;
                        STS=Rho*drho*Vs*dvs*D*2/E;

                        // d ln (Rho) / d ln (Vs)
                        Ratio=log(drho)*log(Vs)/log(dvs)/log(Rho);

// keys="<EVDE> <Gcarc> <Vs> <Rho> <Thickness>
// <InAngle> <TransAngle>
// <SvS> <SuS> <StS> <STS>
// <AMP_SdS> <AMP_ScS2> <AMP_FRS>
// <dTime> <Ratio>"
// <rayp_ScS> <rayp_SvS> <rayp_ScS_ULVZ> <rayp_ScscS>
// Relative (to original ScS bounce point) position:
// <P_SvS> <P_ScS_ULVZ> <P_ScS_ULVZ_in> <P_ScscS> <P_ScscS_up> <P_ScscS_in>

                        fprintf(fpout,"%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\
						\t%.2lf\t%.2lf\
						\t%15.4e\t%15.4e\t%15.4e\t%15.4e\
						\t%15.4e\t%15.4e\t%15.4e\
						\t%15.4e\t%15.4e\
						\t%15.4e\t%15.4e\t%15.4e\t%15.4e\
						\t%15.4e\t%15.4e\t%15.4e\t%15.4e\t%15.4e\t%15.4e\n"
                        ,evde,gcarc,dvs,drho,H
						,asin(A)*180/M_PI,asin(B)*180/M_PI
						,SvS,SuS,StS,STS
                        ,SvS/StS/STS,SuS,SuS-SvS/StS/STS
						,2*(H/D)/(Vs*dvs),Ratio
                        ,rayp_ScS,rayp_SvS,rayp_ScS_ulvz,rayp_ScscS
                        ,position_SvS-position_ScS,position_ScS_ulvz-position_ScS,position_ScS_in-position_ScS,position_ScscS-position_ScS,position_ScscS_up-position_ScS,position_ScscS_in-position_ScS);


printf("TheoCalc: EVDE:%.2lf, GCARC:%.2lf, Thickness:%.2lf, dVs:%.3lf, drho:%.3lf\n",evde,gcarc,H,dvs,drho);
fflush(stdout);


                        drho+=P[D_rho_INC];
                    }

                    dvs+=P[D_Vs_INC];
                }

                H+=P[Thickness_INC];
            }

            gcarc+=P[DELTA_DIST];
        }
        evde+=P[DELTA_EVDE];
    }

    fclose(fpout);

    // Free spaces.
    for (count=0;count<string_num;count++){
        free(PS[count]);
    }
    free(P);
    free(PI);
    free(PS);

    return 0;
}
