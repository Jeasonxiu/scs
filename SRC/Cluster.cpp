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
    enum Penum{CateB,CateWidth,taper,DELTA,FLAG3};

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

	// Data size.
	int nptsx,nptsy;
	nptsx=filenr(PS[infile].c_str());
	nptsy=(int)ceil(P[CateWidth]/P[DELTA])+1;

	double *data=(double *)malloc(nptsx*nptsy*sizeof(double));


	// Read in info & data;
	ifstream infofile,indata;
	string pairname,stnm;
	double OnSet,time;
	int Polarity,index;
	vector<string> PairName,STNM;

	infofile.open(PS[infile]);

	index=0;
	while(infofile >> pairname >> tmpstr >> stnm >> OnSet >> Polarity){

		PairName.push_back(pairname);
		STNM.push_back(stnm);

		indata.open(tmpstr);

		for (int index1=0;index1<nptsy;index1++){
			indata >> time >> data[index];

			time-=OnSet;
			data[index]*=Polarity;

			if (time<P[CateB]){
				index1--;
			}
			else{
				index++;
			}
		}

		indata.close();

	}

	infofile.close();


	// Output target data.
	ofstream outdata;

	for (int index1=0;index1<nptsx;index1++){
		tmpstr=STNM[index1]+".traces";
		outdata.open(tmpstr);
		for (int index2=0;index2<nptsy;index2++){
			outdata << P[CateB]+index2*P[DELTA] << " " << data[index1*nptsy+index2] << endl;
		}
		outdata.close();
	}

	// Taper data & Output Taperred data.
	for (int index1=0;index1<nptsx;index1++){
        taperd(data+index1*nptsy,nptsy,P[taper]);
	}

	for (int index1=0;index1<nptsx;index1++){
		tmpstr=STNM[index1]+".tapered";
		outdata.open(tmpstr);
		for (int index2=0;index2<nptsy;index2++){
			outdata << P[CateB]+index2*P[DELTA] << " " << data[index1*nptsy+index2] << endl;
		}
		outdata.close();
	}

	// Do Cluster Analysis.
	arma::mat A(data,nptsy,nptsx,false,true);
	arma::Row<size_t> assignments;
	mlpack::kmeans::RefinedStart k;
	k.Percentage()=0.5;
	k.Cluster(A,PI[CateN],assignments);

	// Output result;
	ofstream result;
	result.open(PS[outfile]);
	for (int index1=0;index1<nptsx;index1++){
		result << PairName[index1] << " " << assignments[index1]+1 << endl;
	}
	result.close();

	free(data);
    return 0;
}
