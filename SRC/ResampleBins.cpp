#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<vector>
#include<string>
#include<random>
#include<chrono>
#include<algorithm>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

struct Record{
	double *trace,weight;
};

int main(int argc, char **argv){

    enum PIenum{NPTSY,ResampleNum,RandTestNum,FLAG1};
    enum PSenum{infile,outfile_pre,FLAG2};
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

	// Read in files.
	int nptsy=PI[NPTSY];
	int nptsx=filenr(PS[infile].c_str());

	double *weight=new double [nptsx];
	double **frs=new double *[nptsx];
	for (int index=0;index<nptsx;index++){
		frs[index]=new double [nptsy];
	}

	ifstream fpin,fpin2;
	fpin.open(PS[infile]);
	for (int index=0;index<nptsx;index++){
		fpin >> tmpstr >> weight[index];
		fpin2.open(tmpstr);

		for (int index2=0;index2<nptsy;index2++){
			fpin2 >> tmpval >> frs[index][index2];
		}
		fpin2.close();
	}
	fpin.close();

	// Random them.
	vector<Record> Data;
	Record tmpRecord;
	double *weight_forstack=new double [PI[ResampleNum]];
	double *stack_result=new double [nptsy];
	double *stack_std=new double [nptsy];
	double **frs_forstack=new double *[PI[ResampleNum]];
	int *shift=nullptr;

	for (int index=0;index<nptsx;index++){
		tmpRecord.trace=frs[index];
		tmpRecord.weight=weight[index];
		Data.push_back(tmpRecord);
	}

	for (int index=0;index<PI[RandTestNum];index++){

		unsigned seed=chrono::system_clock::now().time_since_epoch().count();
		shuffle(Data.begin(),Data.end(),default_random_engine(seed));

		for (int index2=0;index2<PI[ResampleNum];index2++){
			weight_forstack[index2]=Data[index2].weight;
			frs_forstack[index2]=Data[index2].trace;
		}

		shift_stack(frs_forstack,PI[ResampleNum],nptsy,0,shift,
		            1,weight_forstack,stack_result,stack_std);

		ofstream fpout;
		fpout.open(PS[outfile_pre]+to_string(index+1));
		for (int index2=0;index2<nptsy;index2++){
			fpout << index2*P[delta] << " " << stack_result[index2] << " " 
			      << stack_std[index2] << endl;
		}
		fpout.close();

	}

	delete[] weight;
	for (int index=0;index<nptsx;index++){
		delete[] frs[index];
	}
	delete[] frs;
	delete[] weight_forstack;
	delete[] stack_result;
	delete[] stack_std;
	delete[] frs_forstack;

    return 0;
}
