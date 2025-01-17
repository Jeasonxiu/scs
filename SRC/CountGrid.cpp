#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cmath>
#include<cstdlib>
#include<vector>
#include<string>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{infile,outfile,FLAG2};
    enum Penum{XMIN,XMAX,XINC,YMIN,YMAX,YINC,FLAG3};

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

	// Set up grids.
	int XNPTS=meshsize(P[XMIN],P[XMAX],P[XINC],1);
	int YNPTS=meshsize(P[YMIN],P[YMAX],P[YINC],1);
	double *X=(double *)malloc(XNPTS*sizeof(double));
	double *Y=(double *)malloc(YNPTS*sizeof(double));
	meshthem(X,XNPTS,P[XMIN],P[XMAX],P[XINC],1);
	meshthem(Y,YNPTS,P[YMIN],P[YMAX],P[YINC],1);
	int *Count=(int *)malloc(XNPTS*YNPTS*sizeof(int));
	for (int index=0;index<XNPTS*YNPTS;++index){
		Count[index]=0;
	}

	// Count.
	ifstream points;
	points.open(PS[infile]);
	double x,y;
	while (points >> x >> y){
		++Count[(int)floor((x-P[XMIN])/P[XINC])*YNPTS+(int)floor((y-P[YMIN])/P[YINC])];
	}
	points.close();

	// Output.
	ofstream grids_count;
	grids_count.open(PS[outfile]);
	for (int index=0;index<XNPTS*YNPTS;++index){
		grids_count << X[index/YNPTS] << " " << Y[index%YNPTS] << " " << Count[index] << endl;
	}
	grids_count.close();

	free(Count);
	free(X);
	free(Y);

    return 0;
}
