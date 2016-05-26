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


	ifstream Indexfile,file1,file2;
	ofstream Output;
	Indexfile.open(PS[infile]);
	Output.open(PS[outfile]);

	string pairname,file1name,file2name;

	double signal1[1240];
	double signal2[1240];
	double time;
	int    npts1,npts2;
	double CCC;

	while (Indexfile >> pairname >> file1name >> file2name ){
		file1.open(file1name);
		file2.open(file2name);

		if (!file1){
			cout << "File: " << file1name << " not found !" << endl;
			return 1;
		}

		if (!file2){
			cout << "File: " << file2name << " not found !" << endl;
			return 1;
		}

		npts1=0;
		npts2=0;

		while (file1 >> time >> signal1[npts1]){
			npts1++;
		}

		while (file2 >> time >> signal2[npts2]){
			npts2++;
		}

		CC_static(signal1,npts1,signal2,npts2,&CCC);

		if (CCC<0){
			CCC=0.0;
		}


		Output << pairname << "," << CCC << endl;

		file1.close();
		file2.close();

	}

	Indexfile.close();
	Output.close();

    return 0;
}
