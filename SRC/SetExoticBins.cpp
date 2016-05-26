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
    enum PSenum{hitlo_hitla_az,FLAG2};
    enum Penum{lomin,lomax,loinc,lamin,lamax,lainc,Y,X,FLAG3};

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

	// Hit locations.
	vector<double> hitlo,hitla,az;
	double tmphitlo,tmphitla,tmpaz;
	ifstream infile;
	infile.open(PS[hitlo_hitla_az]);
	while (infile >> tmphitlo >> tmphitla >> tmpaz){
		hitlo.push_back(tmphitlo);
		hitla.push_back(tmphitla);
		az.push_back(lon2360(tmpaz));
	}
	infile.close();

	// Bin Centers.
	int nptsx,nptsy;
	double *binlons,*binlats;

	nptsx=meshsize(P[lomin],P[lomax],P[loinc],1);
	binlons=(double *)malloc(nptsx*sizeof(double));
	meshthem(binlons,nptsx,P[lomin],P[lomax],P[loinc],1);

	nptsy=meshsize(P[lamin],P[lamax],P[lainc],1);
	binlats=(double *)malloc(nptsy*sizeof(double));
	meshthem(binlats,nptsy,P[lamin],P[lamax],P[lainc],1);

	// Output each bin.
	ofstream outfile;
	int Cnt2,Cnt3,InIt;
	string binname;
	double AvrAz,tmplon,tmplat,tmpdist,dt=0.05;
	double p1lon,p1lat,p2lon,p2lat;
	double q1lon,q1lat,q2lon,q2lat;
	double q3lon,q3lat,q4lon,q4lat;

	Cnt3=1;
	for (Cnt=0;Cnt<nptsx;++Cnt){
		for (Cnt2=0;Cnt2<nptsy;++Cnt2){
			binname=to_string(Cnt3)+".bin";

			// Find the average az.
			AvrAz=0.0;
			InIt=0;
			for (decltype(hitlo.size()) index=0;index<hitlo.size();++index){
				if (gcpdistance(hitlo[index],hitla[index],binlons[Cnt],binlats[Cnt2])>1.0){
					continue;
				}
				AvrAz+=az[index];
				++InIt;
			}
			if (InIt==0){
				continue;
			}
			AvrAz/=InIt;

			// Create bin and output it.
			waypoint_az(binlons[Cnt],binlats[Cnt2],AvrAz,P[Y]/2,&p1lon,&p1lat);
			waypoint_az(binlons[Cnt],binlats[Cnt2],AvrAz-180,P[Y]/2,&p2lon,&p2lat);
			waypoint_az(p1lon,p1lat,AvrAz-270,P[X]/2,&q1lon,&q1lat);
			waypoint_az(p1lon,p1lat,AvrAz-90,P[X]/2,&q2lon,&q2lat);
			waypoint_az(p2lon,p2lat,AvrAz-90,P[X]/2,&q3lon,&q3lat);
			waypoint_az(p2lon,p2lat,AvrAz-270,P[X]/2,&q4lon,&q4lat);

			outfile.open(binname);

			tmpdist=0.0;
			while (tmpdist<P[X]){
				waypoint_az(q1lon,q1lat,AvrAz-90,tmpdist,&tmplon,&tmplat);
				outfile << tmplon << " " << tmplat << endl;
				tmpdist+=dt;
			}

			tmpdist=0.0;
			while (tmpdist<P[Y]){
				waypoint_az(q2lon,q2lat,AvrAz-180,tmpdist,&tmplon,&tmplat);
				outfile << tmplon << " " << tmplat << endl;
				tmpdist+=dt;
			}

			tmpdist=0.0;
			while (tmpdist<P[X]){
				waypoint_az(q3lon,q3lat,AvrAz-270,tmpdist,&tmplon,&tmplat);
				outfile << tmplon << " " << tmplat << endl;
				tmpdist+=dt;
			}

			tmpdist=0.0;
			while (tmpdist<P[Y]){
				waypoint_az(q4lon,q4lat,AvrAz,tmpdist,&tmplon,&tmplat);
				outfile << tmplon << " " << tmplat << endl;
				tmpdist+=dt;
			}

			outfile.close();
			++Cnt3;
		}
	}

	free(binlons);
	free(binlats);

    return 0;
}
