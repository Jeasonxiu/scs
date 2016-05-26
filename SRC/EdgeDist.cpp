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

struct record{
	double hitloc;
	double gcarc;
};

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{table,model_stnm_gcarc,out,FLAG2};
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

	ifstream infile;
	ofstream outfile;
	vector<struct record> Data;
	struct record tmpdata;
	double gcarc;
	string tmpstr1,tmpstr2;

	infile.open(PS[table]);
	while (infile >> tmpdata.hitloc >> tmpdata.gcarc){
		Data.push_back(tmpdata);
	}
	infile.close();

	infile.open(PS[model_stnm_gcarc]);
	outfile.open(PS[out]);
	while (infile >> tmpstr1 >> tmpstr2 >> gcarc){
		for (auto item: Data){
			if (item.gcarc==gcarc){
				outfile << tmpstr1 << " " << tmpstr2 << " " << gcarc << " " << item.hitloc << endl;
				break;
			}
		}

	}
	infile.close();
	outfile.close();

    return 0;
}
