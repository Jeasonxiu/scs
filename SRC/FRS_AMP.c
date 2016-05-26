#include<stdio.h>
#include<math.h>
#include<ASU_tools.h>


int main(){

    const double rayp=7.93158;
    const double RE=6371.0;
    const double R_CMB=3480.0;
    double dvs,A,B,C,D;


	A=rayp*180/M_PI*d_vs(RE-R_CMB)/R_CMB;

	for (dvs=1;dvs>0.7;dvs=dvs-0.01){

		B=A*dvs;
		C=sqrt(1-A*A);
		D=sqrt(1-B*B);

		printf("%.2lf\t%.4lf\n",dvs,(C-D)/(C+D)*(-1-4*C*D/(C+D)/(C+D)));

	}

	return 0;
}
