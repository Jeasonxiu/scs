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
    enum PSenum{distfile,indatafilename,outfilename,EQ,FLAG2};
    enum Penum{ShiftDepth,FLAG3};

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

	// read in.
	ifstream infile;

	infile.open(PS[distfile]);
	vector<double> dist;
	vector<string> distfilename;
	while (infile >> tmpval >> tmpstr){
		dist.push_back(tmpval);
		distfilename.push_back(tmpstr);
	}
	infile.close();

	infile.open(PS[indatafilename]);
	vector<string> stnm;
	double evde;
	vector<double> gcarc;
	while (infile >> tmpstr >> evde >> tmpval){
		stnm.push_back(tmpstr);
		gcarc.push_back(tmpval);
	}
	infile.close();

	// process.
	//
	vector<double> originalDist;
	vector<double> newDist;
	
	for (decltype(dist.size()) index=0;index<dist.size();++index){

		double tmpdist,tmpr;
		infile.open(distfilename[index]);
		while (infile >> tmpdist >> tmpr){
			if (evde<6371.0-tmpr){
				originalDist.push_back(dist[index]-tmpdist);
				break;
			}
		}
		infile.close();

		infile.open(distfilename[index]);
		while (infile >> tmpdist >> tmpr){
			if (P[ShiftDepth]<6371.0-tmpr){
				newDist.push_back(dist[index]-tmpdist);
				break;
			}
		}
		infile.close();
	}

	// output
	double *x=&originalDist[0];
	double *y=&newDist[0];
	double *xx=&gcarc[0];
	double *yy=(double *)malloc(gcarc.size()*sizeof(double));

	wiginterpd(x,y,newDist.size(),xx,yy,gcarc.size(),1);
	
	ofstream outfile;
	outfile.open(PS[outfilename]);
	for (decltype(stnm.size()) index=0; index<stnm.size();++index){
		outfile << PS[EQ] << "_" << stnm[index] << " " << yy[index] << endl;
	}
	outfile.close();

	free(yy);

    return 0;
}
