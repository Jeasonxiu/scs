#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<vector>
#include<string>
#include<mlpack/methods/kmeans/kmeans.hpp>
#include<mlpack/methods/kmeans/refined_start.hpp>
#include<mlpack/core.hpp>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

int main(int argc, char **argv){

    enum PIenum{CateN,FLAG1};
    enum PSenum{infile,outfile,FLAG2};
    enum Penum{FLAG3};

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

	// Read in info;
	ifstream infofile;
	string pairname;
	int category;
	double measurement;
	vector<string> *PairName=(vector<string> *)malloc(PI[CateN]*sizeof(vector<string>));
	double *Ave=(double *)malloc(PI[CateN]*sizeof(double));

	infofile.open(PS[infile]);

	while(infofile >> pairname >> category >> measurement){

		PairName[category-1].push_back(pairname);
		Ave[category-1]+=measurement;

	}

	infofile.close();


	// Get arrange values.
	for (int index1=0;index1<PI[CateN];index1++){
		Ave[index1]/=PairName[index1].size();
	}

	// Arrange (get index);
	int *Index=(int *)malloc(PI[CateN]*sizeof(int));

	for (int index1=0;index1<PI[CateN];index1++){
		max_vald(Ave,PI[CateN],&Index[index1]);
		Ave[Index[index1]]=-1/0.0;
	}

	// Output result.
	ofstream result;
	result.open(PS[outfile]);
	for (int index1=0;index1<PI[CateN];index1++){
		for (auto &item:PairName[Index[index1]]){
			result << item << " " << index1+1 << endl;
		}
	}
	result.close();

    return 0;
}
