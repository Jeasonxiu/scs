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
	int BinNum,TraceNum;
};

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{infile,outfile_pre,FLAG2};
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

	int NBin=filenr(PS[infile].c_str());
	vector<Record> Data;
	Record tmpRecord;

	ifstream fpin;
	fpin.open(PS[infile]);
	for (int index=0;index<NBin;index++){
		fpin >> tmpRecord.BinNum >> tmpRecord.TraceNum;
		Data.push_back(tmpRecord);
	}
	fpin.close();

	auto f=[](const Record &s1,const Record &s2){
		return s1.TraceNum<s2.TraceNum;
	};

	sort(Data.begin(),Data.end(),f);

	for (size_t index=0;index<Data.size();index++){

		ofstream fpout;
		fpout.open(PS[outfile_pre]+to_string(Data[index].BinNum));

		for (size_t index2=0;index2<Data.size();index2++){

			if (index2==0){
				tmpstr=" "+to_string(Data[0].BinNum);
			}
			else if (Data[index2].TraceNum==Data[index2-1].TraceNum){
				tmpstr+=(" "+to_string(Data[index2].BinNum));
			}
			else if (Data[index2].TraceNum<=Data[index].TraceNum){
				fpout << Data[index2-1].TraceNum << tmpstr << endl;
				tmpstr=" "+to_string(Data[index2].BinNum);
			}
			else{
				fpout << Data[index2-1].TraceNum << tmpstr << endl;
				break;
			}

			if (index2==Data.size()-1 &&
				Data[index2].TraceNum!=Data[index2-1].TraceNum){
				fpout << Data[index2].TraceNum << tmpstr << endl;
			}
		}

		fpout.close();
	}

    return 0;
}
