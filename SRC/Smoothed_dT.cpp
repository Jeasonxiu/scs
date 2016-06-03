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
    enum PSenum{infile,outfile_S,outfile_ScS,FLAG2};
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

	struct Record{
		double stlo,stla,dTS,dTScS;
	};

	Record TmpRecord;
	vector<Record> Data;

	ifstream infp;
	infp.open(PS[infile]);

	while (infp >> TmpRecord.stlo >> TmpRecord.stla >> TmpRecord.dTS >> TmpRecord.dTScS){
		Data.push_back(TmpRecord);
	}

	ofstream out_S,out_ScS;
	out_S.open(PS[outfile_S]);
	out_ScS.open(PS[outfile_ScS]);

	double lon=P[XMIN],lat,Ave_S,Ave_ScS;
	int Count;

	while (lon<=P[XMAX]){
		lat=P[YMIN];
		while(lat<=P[YMAX]){

			Ave_S=0;
			Ave_ScS=0;
			Count=0;

			for (auto &item: Data){
				if ( fabs(item.stlo-lon)<0.5 && fabs(item.stla-lat)<0.5 ){
					Ave_S+=item.dTS;
					Ave_ScS+=item.dTScS;
					Count++;
				}
			}

			if (Count!=0){
				Ave_S/=Count;
				Ave_ScS/=Count;
				out_S << lon << " " << lat << " " << Ave_S << endl;
				out_ScS << lon << " " << lat << " " << Ave_ScS << endl;
			}

			lat+=P[YINC];
		}
		lon+=P[XINC];
	}

    return 0;
}
