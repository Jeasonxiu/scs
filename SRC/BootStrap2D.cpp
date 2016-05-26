#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<vector>
#include<string>
extern "C"{
#include<unistd.h>
#include<gmt/gmt.h>
#include<ASU_tools.h>
}

using namespace std;

struct record{
	double Time;
	double Amp;
};

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{filenames,outfile,outfile2,FLAG2};
    enum Penum{timemin,timemax,timeinc,ampmin,ampmax,ampinc,FLAG3};

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
		stringstream ss{tmpstr};
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

	// Set up count grid.
	int nptsx=meshsize(P[timemin],P[timemax],P[timeinc],0);
	int nptsy=meshsize(P[ampmin],P[ampmax],P[ampinc],0);
	double *x=(double *)malloc(nptsx*sizeof(double));
	double *y=(double *)malloc(nptsy*sizeof(double));
	meshthem(x,nptsx,P[timemin],P[timemax],P[timeinc],0);
	meshthem(y,nptsy,P[ampmin],P[ampmax],P[ampinc],0);
	float *grid=(float  *)malloc((nptsx-1)*(nptsy-1)*sizeof(float));
	for (Cnt=0;Cnt<(nptsx-1)*(nptsy-1);++Cnt){
		grid[Cnt]=0;
	}

	// Read and count.
	ifstream infile,infile2;
	infile.open(PS[filenames]);
	string tracename;
	vector<record> Data;
	struct record tmpdata;
	int Cnt2;

	while (infile>>tracename){

		Data.clear();

		infile2.open(tracename);
		while (infile2>>tmpdata.Time>>tmpdata.Amp){
			Data.push_back(tmpdata);
		}
		infile2.close();

		// Count.
		for (Cnt=0;Cnt<nptsx-1;++Cnt){
			for (Cnt2=0;Cnt2<nptsy-1;++Cnt2){
				for (auto item: Data){
					if (x[Cnt]<=item.Time && item.Time<x[Cnt+1] && y[Cnt2]<=item.Amp && item.Amp<y[Cnt2+1]){
						grid[Cnt*(nptsy-1)+Cnt2]+=1.0;
						break;
					}
				}
			}
		}

	}
	infile.close();

	ofstream out;

	out.open(PS[outfile]);
	for (Cnt=0;Cnt<nptsx-1;++Cnt){
		for (Cnt2=0;Cnt2<nptsy-1;++Cnt2){
			out << x[Cnt] << " " << y[Cnt2] << " " << grid[Cnt*(nptsy-1)+Cnt2] << endl;
		}
	}
	out.close();

	tmpval=maxval_f(grid,(nptsx-1)*(nptsy-1),&Cnt);
	for (Cnt=0;Cnt<(nptsx-1)*(nptsy-1);++Cnt){
		if (grid[Cnt]==0){
			grid[Cnt]=1/0.0;
		}
	}
	out.open(PS[outfile2]);
	out << minval_f(grid,(nptsx-1)*(nptsy-1),&Cnt) << " " << tmpval << endl;
	out.close();


	free(x);
	free(y);
	free(grid);

    return 0;
}
