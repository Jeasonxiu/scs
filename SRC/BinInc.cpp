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
    enum PSenum{infilename,outfileSuffix,outfileSuffix2,FLAG2};
    enum Penum{Dmin,Dmax,Dinc,Drange,FLAG3};

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


	ofstream outfile;
	int TraceNum;
	double *Trace;

	TraceNum=meshsize(P[Dmin],P[Dmax],P[Dinc],0);
	Trace=(double *)malloc(TraceNum*sizeof(double));
	meshthem(Trace,TraceNum,P[Dmin],P[Dmax],P[Dinc],0);

	for (Cnt=0;Cnt<TraceNum;++Cnt){


		ifstream infile;
		string filename;
		double gcarc,tmpweight;
		vector<string> NeedIt;
		vector<double> Weight;

		NeedIt.clear();
		infile.open(PS[infilename]);
		while (infile >> gcarc >> filename >> tmpweight){
			if (Trace[Cnt]-P[Drange]/2<gcarc && gcarc<=Trace[Cnt]+P[Drange]/2){
				NeedIt.push_back(filename);
				Weight.push_back(tmpweight);
			}
		}
		infile.close();
		
		if (NeedIt.empty()){
			continue;
		}

		int Cnt2;
		double *time,**data,*sta,*stdd;
		time=(double *)malloc(filenr(NeedIt[0].c_str())*sizeof(double));
		data=(double **)malloc(NeedIt.size()*sizeof(double *));
		for (decltype(NeedIt.size()) index=0;index<NeedIt.size();++index){
			data[index]=(double *)malloc(filenr(NeedIt[0].c_str())*sizeof(double));
		}
		sta=(double *)malloc(filenr(NeedIt[0].c_str())*sizeof(double));
		stdd=(double *)malloc(filenr(NeedIt[0].c_str())*sizeof(double));

		Cnt2=0;
		infile.open(NeedIt[0]);
		while (infile >> time[Cnt2] >> tmpval){
			++Cnt2;
		}
		infile.close();

		for (decltype(NeedIt.size()) index1=0;index1<NeedIt.size();++index1){
			infile.open(NeedIt[index1]);
			Cnt2=0;
			while(infile >> tmpval >> data[index1][Cnt2]){
				++Cnt2;
			}
			infile.close();
		}

        // Raw sum.
		int *shift=NULL;
		double *weight=NULL;
		shift_stack(data,NeedIt.size(),filenr(NeedIt[0].c_str()),0,shift,0,weight,sta,stdd);

		outfile.open(to_string(Trace[Cnt])+"_"+to_string(NeedIt.size())+PS[outfileSuffix]);
		for (Cnt2=0;Cnt2<filenr(NeedIt[0].c_str());++Cnt2){
			outfile << time[Cnt2] << " " << sta[Cnt2] << endl;
		}
		outfile.close();

        // Weighted inc sum.
        weight=&Weight[0];
		shift_stack(data,NeedIt.size(),filenr(NeedIt[0].c_str()),0,shift,1,weight,sta,stdd);

		outfile.open(to_string(Trace[Cnt])+"_"+to_string(NeedIt.size())+PS[outfileSuffix2]);
		for (Cnt2=0;Cnt2<filenr(NeedIt[0].c_str());++Cnt2){
			outfile << time[Cnt2] << " " << sta[Cnt2] << endl;
		}
		outfile.close();

		free(sta);
		free(stdd);
		free(time);
		for (decltype(NeedIt.size()) index=0;index<NeedIt.size();++index){
			free(data[index]);
		}
		free(data);
	}

    return 0;
}
