#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cmath>
#include<cstring>
#include<cstdlib>
#include<vector>
#include<string>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

int main(int argc, char **argv){

    enum PIenum{FLAG1};
    enum PSenum{infile,outfile_pre,FLAG2};
    enum Penum{C1,Length,delta,F1,F2,taperwidth,FLAG3};

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

	double **data,*ptime;
	int nptsx,nptsy,*bad_flag;
	string *stnm;
	char **filelist;

	nptsx=filenr(PS[infile].c_str());
	nptsy=(int)ceil(P[Length]/P[delta]);

	ptime=new double [nptsx];
	bad_flag=new int [nptsx];
	stnm=new string [nptsx];
	filelist=new char *[nptsx];
	data=new double *[nptsx];
	for (int index=0;index<nptsx;index++){
		data[index]=new double [nptsy];
		filelist[index]=new char [200];
		bad_flag[index]=0;
	}

	ifstream infp;
	infp.open(PS[infile]);
	for (int index=0;index<nptsx;index++){
		infp >> tmpstr >> stnm[index] >> ptime[index];
		strcpy(filelist[index],tmpstr.c_str());
	}

	infp.close();


    read_sac(data,nptsx,nptsy,ptime,P[C1],P[delta],P[F1],P[F2],2,2,2,1,
	         P[taperwidth],filelist,bad_flag);

	ofstream outfp;
	for (int index=0;index<nptsx;index++){

		tmpstr=PS[outfile_pre]+stnm[index]+".waveform";
		outfp.open(tmpstr);

		if (bad_flag[index]!=0){
			outfp << "0 0" << endl;
		}

		else{

			normalize_window(data[index],nptsy,(int)ceil((-150-P[C1])/P[delta]),
			                 (int)ceil(300/P[delta]));

			for (int index2=0;index2<nptsy;index2++){
				outfp << P[C1]+P[delta]*index2 << " " << data[index][index2]
					  << endl;
			}
		}

		outfp.close();
	}

    return 0;
}
