#include<iostream>
#include<fstream>
#include<sstream>
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
    enum PSenum{filelist,stackout,stdup,stddown,FLAG2};
    enum Penum{delta,FLAG3};

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

	int nptsx=filenr(PS[filelist].c_str());
	int nptsy;
	double **Data=(double **)malloc(nptsx*sizeof(double *));

	ifstream infile;
	string filename;
	infile.open(PS[filelist]);

	Cnt=0;
	while (infile >> filename){
		nptsy=filenr(filename.c_str());
		Data[Cnt]=(double *)malloc(nptsy*sizeof(double));

		ifstream data;
		data.open(filename);
		double time;
		int Cnt2=0;
		while (data >> time >> Data[Cnt][Cnt2]){
			Cnt2++;
		}
		data.close();
		Cnt++;
	}
	infile.close();

	double *weight=NULL;
	int *shift=NULL;

	double *stackdata=(double *)malloc(nptsy*sizeof(double));
	double *stddata=(double *)malloc(nptsy*sizeof(double));
	shift_stack(Data,nptsx,nptsy,0,shift,0,weight,stackdata,stddata);

	ofstream outfile;

	outfile.open(PS[stackout].c_str());
	for (Cnt=0;Cnt<nptsy;Cnt++){
		outfile << P[delta]*Cnt << "  " << stackdata[Cnt] << endl;
	}
	outfile.close();
	
	outfile.open(PS[stdup].c_str());
	for (Cnt=0;Cnt<nptsy;Cnt++){
		outfile << P[delta]*Cnt << "  " << stackdata[Cnt]+stddata[Cnt] << endl;
	}
	outfile.close();

	outfile.open(PS[stddown].c_str());
	for (Cnt=0;Cnt<nptsy;Cnt++){
		outfile << P[delta]*Cnt << "  " << stackdata[Cnt]-stddata[Cnt] << endl;
	}
	outfile.close();

    return 0;
}
