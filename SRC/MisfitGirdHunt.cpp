#include<iostream>
#include<fstream>
#include<sstream>
#include<cmath>
#include<cstdio>
#include<cstdlib>
#include<vector>
#include<string>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{infile,outfile_Pre,outfile_depth,FLAG2};
    enum Penum{XMIN,XMAX,XINC,YMIN,YMAX,YINC,DMIN,DMAX,DINC,FLAG3};

    /****************************************************************

				Deal with inputs. (Store them in PI,PS,P)

    ****************************************************************/

	if (argc!=4){
		cerr << "In C++: Argument Error!" << endl;
		return 1;
	}

    int int_num,string_num,double_num;

    vector<int> PI;
    vector<string> PS;
    vector<double> P;

    int_num=atoi(argv[1]);
    string_num=atoi(argv[2]);
    double_num=atoi(argv[3]);

	if (FLAG1!=int_num){
		cerr << "In C++: Ints Naming Error !" << endl;
	}
	if (FLAG2!=string_num){
		cerr << "In C++: Strings Naming Error !" << endl;
	}
	if (FLAG3!=double_num){
		cerr << "In C++: Doubles Naming Error !" << endl;
	}

	string tmpstr;
	int tmpint,Cnt;
	double tmpval;

	Cnt=0;
	while (getline(cin,tmpstr)){
		++Cnt;
		stringstream ss(tmpstr);
		if (Cnt<=int_num){
			if (ss >> tmpint && ss.eof()){
				PI.push_back(tmpint);
			}
			else{
				cerr << "In C++: Ints reading Error !" << endl;
				return 1;
			}
		}
		else if (Cnt<=int_num+string_num){
			PS.push_back(tmpstr);
		}
		else if (Cnt<=int_num+string_num+double_num){
			if (ss >> tmpval && ss.eof()){
				P.push_back(tmpval);
			}
			else{
				cerr << "In C++: Doubles reading Error !" << endl;
				return 1;
			}
		}
		else{
			cerr << "In C++: Redundant inputs !" << endl;
			return 1;
		}
	}
	if (Cnt!=int_num+string_num+double_num){
		cerr << "In C++: Not enough inputs !" << endl;
		return 1;
	}

    /****************************************************************

                              Job begin.

    ****************************************************************/

	// Set up grid.
	int XSIZE=meshsize(P[XMIN],P[XMAX],P[XINC],1);
	int YSIZE=meshsize(P[YMIN],P[YMAX],P[YINC],1);
	int DSIZE=meshsize(P[DMIN],P[DMAX],P[DINC],1);

	double *X=(double *)malloc(XSIZE*sizeof(double));
	double *Y=(double *)malloc(YSIZE*sizeof(double));
	double *D=(double *)malloc(DSIZE*sizeof(double));

	double XINT=meshthem(X,XSIZE,P[XMIN],P[XMAX],P[XINC],1);
	double YINT=meshthem(Y,YSIZE,P[YMIN],P[YMAX],P[YINC],1);
	double DINT=meshthem(D,DSIZE,P[DMIN],P[DMAX],P[DINC],1);

	double *Grid=(double *)malloc(XSIZE*YSIZE*DSIZE*sizeof(double));
	for (int index=0;index<XSIZE*YSIZE*DSIZE;index++){
		Grid[index]=0;
	}

	// Reading path file.
	string pathfile;
	double Misfit;
	ifstream infp;
	infp.open(PS[infile]);

	while (infp>>pathfile>>Misfit){

		double Val=(Misfit>0?1:-1);
		double lon,lat,depth;
		int Index_Pre=0;
		ifstream pathfp;
		pathfp.open(pathfile);

		while (pathfp >> lon >> lat >> depth){
			int Index=(int)floor((depth-P[DMIN])/DINT)*XSIZE*YSIZE+(int)floor((lat-P[YMIN])/YINT)*XSIZE+(int)floor((lon-P[XMIN])/XINT);
			if (Index!=Index_Pre){
				Index_Pre=Index;
				Grid[Index]+=Val;
			}
		}
		pathfp.close();

	}
	infp.close();

	// Output XYZ file.
	ofstream outfp;
	for (int index=0;index<DSIZE-1;index++){

		outfp.open(PS[outfile_Pre]+to_string(index+1));

		for (int index2=0;index2<XSIZE*YSIZE;index2++){
			outfp << X[index2%XSIZE]+XINT/2 << " " << Y[index2/XSIZE]+YINT/2 << " " << Grid[index2+index*XSIZE*YSIZE] << endl;
		}

		outfp.close();
	}

	// Output depth grid.
	outfp.open(PS[outfile_depth]);
	for (int index=0;index<DSIZE;index++){
		outfp << D[index] << endl;
	}
	outfp.close();


    return 0;
}
