#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<vector>
#include<string>
extern "C"{
#include<ASU_tools.h>
#include<unistd.h>
}

using namespace std;

int main(int argc, char **argv){

    enum PIenum{Threshold,FLAG1};
    enum PSenum{eq_stnm_hitlo_hitla,BinFile,FLAG2};
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

	ifstream infile,infile2;
	string binfilename;
	ofstream outfile;
	string gridname;
	vector<double> LonBound,LatBound;
	double tmplon,tmplat;
	double *xx,*yy,*x,*y;
	string tmpEQ,tmpstnm;
	double tmphitlo,tmphitla;
	vector<double> Hitlo,Hitla;
	vector<string> EQ,Stnm;
	vector<int> Index;

	infile.open(PS[eq_stnm_hitlo_hitla]);
	while (infile >> tmpEQ >> tmpstnm >> tmphitlo >> tmphitla ){
		EQ.push_back(tmpEQ);
		Stnm.push_back(tmpstnm);
		Hitlo.push_back(tmphitlo);
		Hitla.push_back(tmphitla);
	}
	infile.close();

	x=&Hitlo[0];
	y=&Hitla[0];

	int *WN=(int *)malloc(Hitlo.size()*sizeof(int));
	int TraceCnt;
	double LonAver,LatAver;

	Cnt=1;
	infile.open(PS[BinFile]);
	while (infile >> binfilename){

		gridname=to_string(Cnt)+".grid";
		outfile.open(gridname);
		outfile << "<EQ> <STNM> <DIST> <binR> <binLon> <binLat> <binLon_Before> <binLat_Before> <Hitlo> <Hitla>" << endl;

		infile2.open(binfilename);

		LonBound.clear();
		LatBound.clear();


		while (infile2 >> tmplon >> tmplat){
			LonBound.push_back(tmplon);
			LatBound.push_back(tmplat);
		}

		infile2.close();

		LonAver=0;
		LatAver=0;
		for (auto index: LonBound){
			LonAver+=index;
		}
		LonAver/=LonBound.size();
		for (auto index: LatBound){
			LatAver+=index;
		}
		LatAver/=LatBound.size();

		xx=&LonBound[0];
		yy=&LatBound[0];

		points_in_polygon(x,y,Hitlo.size(),xx,yy,LonBound.size(),WN);
		
		TraceCnt=0;
		for (decltype(Hitlo.size())index=0;index<Hitlo.size();++index){
			if (WN[index]==1){
				outfile << EQ[index] << " " << Stnm[index] << " 0.0 1.0 " << LonAver << " "
						<< LatAver << " " << LonAver << " " << LatAver << " " << Hitlo[index]
						<< " " << Hitla[index] << endl;
				++TraceCnt;
			}
		}
		outfile.close();

		if (TraceCnt>=PI[Threshold]){
			++Cnt;
		}
		else{
			unlink(binfilename.c_str());
		}
	}
	infile.close();

	free(WN);

    return 0;
}
