#include<iostream>
#include<fstream>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<cmath>
#include<vector>
#include<string>
extern "C"{
#include<ASU_tools.h>
}

using namespace std;

/***********************************************************
 * Tstar S ESW or ScS traces to best match ScS trace/S ESW.
 * Comparison position is decided by portion above certain
 * amplitude level.
 * Best fit is decided by choosing the minimum absolute
 * difference within certain time window.
 *
 * This will search Tstar first. Once the proper Tstar is found.
 * Fix the Tstar operator, do the vertical stretch serach.
 * Use the minimum absolute different vertical stretch parameters.
 *
 * Then do taper on both ESW and trace, then apply waterlevel
 * de-convolution.
***********************************************************/

struct Record{
	string PairName,STNM,Waveform,OldESW,Tapered,NewESW,Trace;
	double Peak_ScS,NA_ScS,Peak_S,DTS,PREM_S,PREM_ScS;
};

struct CompareESW{
	double Ts,Ver,*Signal;
	int Peak,Length;
};

struct CompareScS{
	double *Signal;
	int Peak,Length;
};

struct DeconPair{
	double *Source,*Signal,*Decon;
	int Source_Peak,Signal_Peak,Decon_Peak;
	double Ts,Ver,Shift,CCC,Diff; // Ts<0 means ScS is get tstared.
	                              // Shift is the proper shift in sec if Peaks
								  //     are pre-aligned. Negative means ScS
								  //     need to move forward.
};

void CompareESW_ScS(CompareESW,CompareScS,int *,double *,double *,double *,
                    double,int,int);

int main(int argc, char **argv){

    enum PIenum{nXStretch,nYStretch,FLAG1};
    enum PSenum{infile,outfile,outfile2,BestInfo,ESWGrid_Pre,FLAG2};
    enum Penum{C1,C2,R2,V1,V2,AMPlevel,delta,WaterLevel,C1_D,C2_D,N1_D,N2_D,
			   S1_D,S2_D,AN,F1_D,F2_D,FLAG3};

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

	// Chap 1. Stretch.

	// Step 1. Deal with input files.

	vector<Record> Data;
	Record TmpRecord;
	string OldESW;

	ifstream infp;
	infp.open(PS[infile]);
	while (infp >> TmpRecord.PairName >> TmpRecord.STNM >> TmpRecord.Waveform
				>> TmpRecord.OldESW >> TmpRecord.Tapered >> TmpRecord.NewESW
				>> TmpRecord.Trace >> TmpRecord.Peak_ScS >> TmpRecord.NA_ScS
				>> TmpRecord.Peak_S >> TmpRecord.DTS
				>> TmpRecord.PREM_S >> TmpRecord.PREM_ScS ){
		Data.push_back(TmpRecord);
	}
	infp.close();




	// Step 2. Read in Waveform and OldESW. Cut them between -100 ~ 100 sec.

    // 1. Count NPTS_Cut.
	int NPTS_Cut=0;
	double time,amp;
	infp.open(Data[0].OldESW);
	while (infp >> time >> amp){
        if ( -100.0<time && time<100.0 ){
            NPTS_Cut++;
        }
	}
	infp.close();


	// 2. Read in Waveforms.
	double **ScSWaveformTapered_amp=new double *[Data.size()];
	double **ScSWaveformTapered_time=new double *[Data.size()];
	for (size_t index=0;index<Data.size();index++){
		ScSWaveformTapered_amp[index]=new double[NPTS_Cut];
		ScSWaveformTapered_time[index]=new double[NPTS_Cut];

		int index2=0;
		infp.open(Data[index].Waveform);
		while (index2<NPTS_Cut){

			infp >> ScSWaveformTapered_time[index][index2]
			     >> ScSWaveformTapered_amp[index][index2];

			if ( -100.0<ScSWaveformTapered_time[index][index2] &&
				 ScSWaveformTapered_time[index][index2]<100.0 ){

				index2++;
			}
		}
		infp.close();
	}

	// 3. Read in OldESW.
	double *oldESW_amp=new double[NPTS_Cut];
	double *oldESW_time=new double[NPTS_Cut];

	infp.open(Data[0].OldESW);
	int index=0;
	while (index<NPTS_Cut){
		infp >> oldESW_time[index] >> oldESW_amp[index];
		if ( -100.0<oldESW_time[index] && oldESW_time[index]<100.0 ){
			index++;
		}
	}
	infp.close();



	// Step 3. Pre-process ESW and ScS Waveforms by shift T=0 to their Peak.
	//         Peak is searched between t= -10 ~ 20 sec on OldESW.
	//         Then normalize to the Peak so Peak=1 and everything
	//         is pointing upwards.
	//         For ScS Waveforms, taper them properly for deconvolution.


	// 1. Find peak and normalize OldESW.

	int PeakWB=(int)ceil(90/P[delta]),PeakWL=(int)ceil(30/P[delta]),Peak;
	double NormalizeFactor,ShiftTimeFactor;
	double PeakTimeOnESW; // reference to arrival anchor.

	max_ampd(oldESW_amp+PeakWB,PeakWL,&Peak);
	NormalizeFactor=oldESW_amp[PeakWB+Peak];
	ShiftTimeFactor=oldESW_time[PeakWB+Peak];
	PeakTimeOnESW=(PeakWB+Peak)*P[delta]-100.0;

	for (int index=0;index<NPTS_Cut;index++){
		oldESW_amp[index]/=NormalizeFactor;
		oldESW_time[index]-=ShiftTimeFactor;
	}

	// 2. Normalize and taper ScS waveforms.
	int *PeakScS=new int [Data.size()];
	int *PeakS=new int [Data.size()];

	for (size_t index=0;index<Data.size();index++){


		// Find peak for normalize.
		Peak=(int)ceil((Data[index].Peak_ScS+100)/P[delta]);
		findpeak(ScSWaveformTapered_amp[index],NPTS_Cut,&Peak,-100,200);

		NormalizeFactor=ScSWaveformTapered_amp[index][Peak];
		ShiftTimeFactor=ScSWaveformTapered_time[index][Peak];

		PeakScS[index]=Peak;

		for (int index2=0;index2<NPTS_Cut;index2++){
			ScSWaveformTapered_amp[index][index2]/=NormalizeFactor;
			ScSWaveformTapered_time[index][index2]-=ShiftTimeFactor;
		}

		Peak=(int)ceil((Data[index].Peak_S+100+
		                Data[index].PREM_S-Data[index].PREM_ScS)/P[delta]);
		if (Peak>=100){
			findpeak(ScSWaveformTapered_amp[index],NPTS_Cut,&Peak,-100,200);
		}
		PeakS[index]=Peak;

	}

	// Step 4. Make tstar operators and apply them to OldESW.
	//         Only use the center part (-30 ~ 30 sec) of the OldESW to make
	//         tstared ESWs. Before making tstared ESW, taper this portion
	//         of the ESW.
	//         Cut tstared ESWs, only remain the center parts.
	//         Output tstared ESWs for verification.


	// 1. Make tstar operator (no normalized).
	int NPTS_Tstar=8000;
	int *TstarOperator_Peak= new int [PI[nXStretch]];
	double **TstarOperator = new double *[PI[nXStretch]],Ts,TsINC;

	Ts=0;
	TsINC=P[R2]/(PI[nXStretch]-1);
	for(int index=0;index<PI[nXStretch];index++){
		TstarOperator[index]=new double[NPTS_Tstar];
		tstar(P[delta],NPTS_Tstar,Ts,TstarOperator[index]);
		max_ampd(TstarOperator[index],NPTS_Tstar,TstarOperator_Peak+index);
		Ts+=TsINC;
	}


 	// 2. Find the peak of OldESW.
	int Position;
	for (Position=0;Position<NPTS_Cut;Position++){
		if (oldESW_time[Position]*oldESW_time[Position+1]<=0){
			break;
		}
	}
	Position-=(int)ceil(30/P[delta]);

	// 3. Taper the center part and make tapered ESW.
	int NPTS_TstaredESW=(int)ceil(60/P[delta]);
	int *TstaredESW_Peak= new int [PI[nXStretch]];
	double **TstaredESW = new double *[PI[nXStretch]];
	double *TstaredESW_Aux=new double[NPTS_Tstar+NPTS_TstaredESW-1];
	ofstream outfp;

	taperd(oldESW_amp+Position,NPTS_TstaredESW,0.1);

	for(int index=0;index<PI[nXStretch];index++){

		TstaredESW[index]=new double[NPTS_TstaredESW];

		// Make tstared ESWs.
		convolve(oldESW_amp+Position,TstarOperator[index],NPTS_TstaredESW,
		         NPTS_Tstar,TstaredESW_Aux);

		// Find peak for normalize.
		TstaredESW_Peak[index]=TstarOperator_Peak[index]+NPTS_TstaredESW/2;
		findpeak(TstaredESW_Aux,NPTS_Tstar+NPTS_TstaredESW-1,
		         TstaredESW_Peak+index,-100,200);

		NormalizeFactor=TstaredESW_Aux[TstaredESW_Peak[index]];

		for (int index2=0;index2<NPTS_Tstar+NPTS_TstaredESW-1;index2++){
			TstaredESW_Aux[index2]/=NormalizeFactor;
		}

		// Get only the center 60sec.
		for (int index2=0;index2<NPTS_TstaredESW;index2++){
			TstaredESW[index][index2]=
			TstaredESW_Aux[TstaredESW_Peak[index]-NPTS_TstaredESW/2+index2];
		}
		TstaredESW_Peak[index]=NPTS_TstaredESW/2;


		// Output for verification.
		outfp.open(PS[ESWGrid_Pre]+to_string(TsINC*index));
		for (int index2=0;index2<NPTS_TstaredESW;index2++){
			outfp << (index2-TstaredESW_Peak[index])*P[delta] << " "
			      << TstaredESW[index][index2] << endl;
		}
		outfp.close();

	}

	delete[] oldESW_time;
	delete[] oldESW_amp;
	delete[] TstaredESW_Aux;

// 	Step 5'. Post-process ScS waveform, this may choose from:
// 		a. Don't strip S.
// 		b. May strip S by applying a sectioned taper.
// 		c. May strip S by subtracting S ESW at S CCC position.


	for (size_t index=0;index<Data.size();index++){

		int WB,WL;
		if (PeakScS[index]>NPTS_Cut/2){
			WL=2*(NPTS_Cut-PeakScS[index]);
			WB=NPTS_Cut-WL;
		}
		else{
			WB=0;
			WL=2*PeakScS[index];
		}

		// a:
// 		taperd(ScSWaveformTapered_amp[index]+WB,WL,0.1);

		// b:
// 		taperd_section(ScSWaveformTapered_amp[index]+WB,WL,0.4,0.1);

		// c:
		int SubtractWindow=(int)ceil(60/P[delta]);
		if (PeakS[index]<SubtractWindow/2){
			continue;
		}

		double SPeakAMP=ScSWaveformTapered_amp[index][PeakS[index]];
		int ScSBegin,ESWBegin;

		// Find subtraction begin position on ESW and ScS.
		ScSBegin=PeakS[index]-SubtractWindow/2;
		ESWBegin=(int)ceil((Data[index].Peak_S-Data[index].DTS-
		                    PeakTimeOnESW)/P[delta]);

		ESWBegin+=(TstaredESW_Peak[0]-SubtractWindow/2);


		// Subtract ESW from S waveform.
		for (int index2=0;index2<SubtractWindow;index2++){
			if (ScSBegin+index2<0 || ESWBegin+index2<0){
				continue;
			}
			ScSWaveformTapered_amp[index][ScSBegin+index2]-=
			TstaredESW[0][ESWBegin+index2]*SPeakAMP;
		}

		// Normalize to ScS.
		NormalizeFactor=ScSWaveformTapered_amp[index][PeakScS[index]];
		for (int index2=0;index2<NPTS_Cut;index2++){
			ScSWaveformTapered_amp[index][index2]/=NormalizeFactor;
		}

		taperd_section(ScSWaveformTapered_amp[index]+WB,WL,0.4,0.1);

	}

	// Step 5. Since we need to try vertical stretch as well, we need to have
	//         a matrix of altered ESW (named alteredESW);

	double VerINC=(P[V2]-P[V1])/(PI[nYStretch]-1);
	double *TmpSignal,V;
	CompareESW ** alteredESW=new CompareESW *[PI[nXStretch]];

	// 1. Malloc spaces for alteredESW.
	for (int index=0;index<PI[nXStretch];index++){

		alteredESW[index]=new CompareESW [PI[nYStretch]];
		for (int index2=0;index2<PI[nYStretch];index2++){

			alteredESW[index][index2].Ver=P[V1]+VerINC*index2;
			alteredESW[index][index2].Ts=TsINC*index;
			alteredESW[index][index2].Peak=NPTS_TstaredESW/2;
			alteredESW[index][index2].Length=NPTS_TstaredESW;
		}
	}

	// 2. Stretch Vertically.
	int ZeroVerticalIndex=0;

	for (int index=0;index<PI[nYStretch];index++){
		for (int index2=0;index2<PI[nXStretch];index2++){

			TmpSignal=new double [NPTS_TstaredESW];
			V=alteredESW[index2][index].Ver;

			if  (fabs(V)<VerINC/2+VerINC/10){
				ZeroVerticalIndex=index;
			}

			for (int index3=0;index3<NPTS_TstaredESW;index3++){
				TmpSignal[index3]=(TstaredESW[index2][index3]+V)/(1+V);
			}
			alteredESW[index2][index].Signal=TmpSignal;
		}
	}


	// Step 6. Set up original ScS comparison part.
	CompareScS *originalScS = new CompareScS [Data.size()];

	for (size_t index=0;index<Data.size();index++){
		originalScS[index].Signal=ScSWaveformTapered_amp[index];
		originalScS[index].Length=NPTS_Cut;

		for (Position=0;Position<NPTS_Cut;Position++){
			if (ScSWaveformTapered_time[index][Position]*
				ScSWaveformTapered_time[index][Position+1]<=0){
				break;
			}
		}
		originalScS[index].Peak=Position;
	}


	// Step 7. Compare between alteredESW and original ScS.
	//         Apply tstar on ScS if necessary.


	int IndexTs,IndexVer,Shift,TmpShift;
	int L1=(int)ceil(P[C1]/P[delta]),L2=(int)ceil(P[C2]/P[delta]);
	double CCC,CCDiff,Diff,TmpCCDiff,TmpDiff,TmpCCC;
	CompareScS *tstaredScS;
	double *tstaredScS_Aux=new double [NPTS_Cut+NPTS_Tstar-1];
	DeconPair *DeconInput = new DeconPair [Data.size()];

	for (size_t index=0;index<Data.size();index++){

		cout << "Stretching " << Data[index].STNM << ".. ["  << index << " / "
		     << Data.size() << "]:" << endl;

		// Compare between ESW(Ts!=0,Ver==0) and Original ScS.
		CCDiff=1/0.0;
// 		CCDiff=0.0;
		IndexTs=0;

		for (int index2=0;index2<PI[nXStretch];index2++){

			CompareESW_ScS(alteredESW[index2][ZeroVerticalIndex],originalScS[index],
						   &TmpShift,&TmpCCC,&TmpCCDiff,&TmpDiff,
						   P[AMPlevel],L1,L2);

			if (Data[index].STNM=="s101"){
				cout << "		->    Tstar/Compare: " << index2*TsINC << " " << TmpCCDiff << endl;
			}


			if (TmpCCDiff<=CCDiff){
// 			if (TmpCCDiff>=CCDiff){
			    CCDiff=TmpCCDiff;
				IndexTs=index2;
			}

		}

		if (IndexTs!=0){

			cout << "    Tstar on ESW..."  << endl;

			// Fix Ts, compare between ESW(Ver!=0) and Original ScS.
			Diff=1/0.0;
			IndexVer=0;

			for (int index2=0;index2<PI[nYStretch];index2++){
				CompareESW_ScS(alteredESW[IndexTs][index2],originalScS[index],
							   &TmpShift,&TmpCCC,&TmpCCDiff,&TmpDiff,
							   P[AMPlevel],L1,L2);

				if (TmpDiff<=Diff){
					Diff=TmpDiff;
					Shift=TmpShift;              // Shift here means when their
					                             // peak are aligned, how much
												 // shift should applied.
					CCC=TmpCCC;
					IndexVer=index2;
				}

			}

			// Notedown compare result.
			DeconInput[index].Source=alteredESW[IndexTs][IndexVer].Signal;
			DeconInput[index].Signal=originalScS[index].Signal;
			DeconInput[index].Source_Peak=alteredESW[IndexTs][IndexVer].Peak;
			DeconInput[index].Signal_Peak=originalScS[index].Peak;
			DeconInput[index].Ts=IndexTs*TsINC;
			DeconInput[index].Ver=P[V1]+IndexVer*VerINC;
			DeconInput[index].Shift=Shift*P[delta];
			DeconInput[index].CCC=CCC;
			DeconInput[index].Diff=Diff;

		}
		else{

			cout << "    Tstar on ScS..."  << endl;

			// Apply Tstar on ScS.

			tstaredScS = new CompareScS [PI[nXStretch]];

			for (int index2=0;index2<PI[nXStretch];index2++){

				tstaredScS[index2].Signal= new double [NPTS_Cut];
				tstaredScS[index2].Length=NPTS_Cut;

				// Make tstared ScS.
				convolve(originalScS[index].Signal,TstarOperator[index2],
						 NPTS_Cut,NPTS_Tstar,tstaredScS_Aux);

				// Find peak for normalize.

				tstaredScS[index2].Peak=originalScS[index].Peak+
										TstarOperator_Peak[index2];

				findpeak(tstaredScS_Aux,NPTS_Cut,&tstaredScS[index2].Peak,
						 -100,200);

				NormalizeFactor=tstaredScS_Aux[tstaredScS[index2].Peak];

				for (int index3=0;index3<NPTS_Cut+NPTS_Tstar-1;index3++){
					tstaredScS_Aux[index3]/=NormalizeFactor;
				}

				// Get only the NPTS_Cut part sec.
				for (int index3=0;index3<NPTS_Cut;index3++){
					tstaredScS[index2].Signal[index3]=
					tstaredScS_Aux[index3+tstaredScS[index2].Peak-NPTS_Cut/2];
				}
				tstaredScS[index2].Peak=NPTS_Cut/2;

			}


			// Compare between ESW(Ts==0,Ver==0) and Tstared ScS.
			CCDiff=1/0.0;
// 			CCDiff=0.0;
			IndexTs=0;

			for (int index2=0;index2<PI[nXStretch];index2++){

				CompareESW_ScS(alteredESW[0][ZeroVerticalIndex],tstaredScS[index2],
							   &TmpShift,&TmpCCC,&TmpCCDiff,&TmpDiff,
							   P[AMPlevel],L1,L2);


				if (TmpCCDiff<=CCDiff){
// 				if (TmpCCDiff>=CCDiff){
					CCDiff=TmpCCDiff;
					IndexTs=index2;
				}

			}


			// Fix Ts, compare between ESW(Ver!=0) and Tstared ScS.
			Diff=1/0.0;
			IndexVer=0;

			for (int index2=0;index2<PI[nYStretch];index2++){

				CompareESW_ScS(alteredESW[0][index2],tstaredScS[IndexTs],
							   &TmpShift,&TmpCCC,&TmpCCDiff,&TmpDiff,
							   P[AMPlevel],L1,L2);

				if (TmpDiff<=Diff){
					Diff=TmpDiff;
					Shift=TmpShift;              // Shift here means when their
					                             // peak are aligned, how much
												 // shift should applied.
					CCC=TmpCCC;
					IndexVer=index2;
				}

			}

			// Notedown new compare result.
			DeconInput[index].Source=alteredESW[0][IndexVer].Signal;
			DeconInput[index].Signal=tstaredScS[IndexTs].Signal;
			DeconInput[index].Source_Peak=alteredESW[0][IndexVer].Peak;
			DeconInput[index].Signal_Peak=tstaredScS[IndexTs].Peak;
			DeconInput[index].Ts=-1*IndexTs*TsINC;
			DeconInput[index].Ver=P[V1]+IndexVer*VerINC;
			DeconInput[index].Shift=Shift*P[delta];
			DeconInput[index].CCC=CCC;
			DeconInput[index].Diff=Diff;

			// Release memory of tstaredScS.
			for (int index2=0;index2<PI[nXStretch];index2++){
				if (index2!=IndexTs){
					delete[] tstaredScS[index2].Signal;
				}
			}
			delete[] tstaredScS;

		}

		cout << "        Tstar Parameter : " << DeconInput[index].Ts << endl;
		cout << "        Vertical Stretch: " << DeconInput[index].Ver << endl;
	}

	// Step 8. Output stretched ESW / or ScS.
	//         Do taper on them.

	for (size_t index=0;index<Data.size();index++){

		taperd(DeconInput[index].Signal,NPTS_Cut,0.1);
		taperd(DeconInput[index].Source,NPTS_TstaredESW,0.1);

		outfp.open(Data[index].Tapered);
		for (int index2=0;index2<NPTS_Cut;index2++){
			outfp << (index2-DeconInput[index].Signal_Peak)*P[delta] << " "
			      << DeconInput[index].Signal[index2] << endl;
		}
		outfp.close();

		outfp.open(Data[index].NewESW);
		for (int index2=0;index2<NPTS_TstaredESW;index2++){
			outfp << (index2-DeconInput[index].Source_Peak)*P[delta] << " "
			      << DeconInput[index].Source[index2] << endl;
		}
		outfp.close();
	}


	// Chap 2. Decon.


	// Step 1. Do the decon.

	double *Deconed_Aux=new double [2*NPTS_Cut];

	for (size_t index=0;index<Data.size();index++){

		DeconInput[index].Decon=new double [NPTS_Cut];

		waterlevel_decon(&DeconInput[index].Signal,1,NPTS_Cut,
		                 DeconInput[index].Source,NPTS_TstaredESW,
						 DeconInput[index].Source_Peak,
						 &DeconInput[index].Signal_Peak,
						 &Deconed_Aux,P[WaterLevel],P[delta],0,
						 NULL,NULL,NULL,NULL,NULL,NULL);

		// BandPass the decon result.
		butterworth_bp(&Deconed_Aux,1,2*NPTS_Cut,P[delta],2,2,P[F1_D],P[F2_D],
		               &Deconed_Aux);

		// Find peak for normalize.
		DeconInput[index].Decon_Peak=NPTS_Cut;

		findpeak(Deconed_Aux,2*NPTS_Cut,&DeconInput[index].Decon_Peak,
		         -100,200);

		NormalizeFactor=Deconed_Aux[DeconInput[index].Decon_Peak];

		for (int index2=0;index2<2*NPTS_Cut;index2++){
			Deconed_Aux[index2]/=NormalizeFactor;
		}

		// Get only the NPTS_Cut part sec.
		for (int index2=0;index2<NPTS_Cut;index2++){
			DeconInput[index].Decon[index2]=
			Deconed_Aux[index2-NPTS_Cut/2+DeconInput[index].Decon_Peak];
		}
		DeconInput[index].Decon_Peak=NPTS_Cut/2;


		// Output deconed results.
		outfp.open(Data[index].Trace);
		for (int index2=0;index2<NPTS_Cut;index2++){
			outfp << (index2-NPTS_Cut/2)*P[delta] << " "
			      << DeconInput[index].Decon[index2] << endl;
		}
		outfp.close();

	}
	// Step 2. Do SNR measurements.
	double *SNR=new double [Data.size()];
	int P1=(int)ceil(P[S1_D]/P[delta]);
	int N_Len=(int)ceil(P[AN]/P[delta]);
	int S_Len=(int)ceil((P[S2_D]-P[S1_D])/P[delta]);

	for (size_t index=0;index<Data.size();index++){
		SNR[index]=snr_envelope(DeconInput[index].Decon,NPTS_Cut,
		                        NPTS_Cut/2+P1-N_Len,N_Len,NPTS_Cut/2+P1,S_Len)
				  *snr_envelope(DeconInput[index].Decon,NPTS_Cut,
		                        NPTS_Cut/2+P1+S_Len,N_Len,NPTS_Cut/2+P1,S_Len);
	}

	// Step 3. Output measurements.
	outfp.open(PS[outfile]);
	for (size_t index=0;index<Data.size();index++){
		outfp << Data[index].PairName << " "
			  << Data[index].NewESW << " "
              << -10 << " "
              << 10 << " "
              << SNR[index] << " "
              << DeconInput[index].Shift << " "
              << DeconInput[index].CCC << " "
			  << DeconInput[index].Ts << " "
			  << DeconInput[index].Ver << " "
			  << DeconInput[index].Diff << " "
              << 0 << " "
              << -100 << " "
              << -4 << " "
              << -10 << " "
              << 10 << endl;
	}
	outfp.close();

	outfp.open(PS[outfile2]);
	for (size_t index=0;index<Data.size();index++){
		outfp << Data[index].PairName << " "
			  << Data[index].NewESW << endl;
	}
	outfp.close();

    return 0;
}


void CompareESW_ScS(CompareESW X,CompareScS Y,int *Shift,double *CCC,
                    double *CCDiff,double *Diff,double AMPlevel,int L1,int L2){

	// 1. Find AMPlevel begin and end positions.

	int X_AB,X_AE,Y_AB,Y_AE;

	for (X_AB=X.Peak;X_AB>0;X_AB--){
		if (X.Signal[X_AB]<AMPlevel){
			break;
		}
	}

	for (X_AE=X.Peak;X_AE<X.Length;X_AE++){
		if (X.Signal[X_AE]<AMPlevel){
			break;
		}
	}

	for (Y_AB=Y.Peak;Y_AB>0;Y_AB--){
		if (Y.Signal[Y_AB]<AMPlevel){
			break;
		}
	}

	for (Y_AE=Y.Peak;Y_AE<Y.Length;Y_AE++){
		if (Y.Signal[Y_AE]<AMPlevel){
			break;
		}
	}

	// 2. Use CCC to compare and align two traces.
	CC(X.Signal+X_AB,X_AE-X_AB+1,Y.Signal+Y_AB,Y_AE-Y_AB+1,Shift,CCC);

// 	double *x_cc=new double [X_AE-X_AB+1];
// 	double *y_cc=new double [Y_AE-Y_AB+1];
// 	for (int index=0;index<X_AE-X_AB+1;index++){
// 		x_cc[index]=X.Signal[X_AB+index]-AMPlevel;
// 	}
// 	for (int index=0;index<Y_AE-Y_AB+1;index++){
// 		y_cc[index]=Y.Signal[Y_AB+index]-AMPlevel;
// 	}
// 	normalized(x_cc,X_AE-X_AB+1);
// 	normalized(y_cc,Y_AE-Y_AB+1);
// 	CC(x_cc,X_AE-X_AB+1,y_cc,Y_AE-Y_AB+1,Shift,CCC);
// 	delete[] x_cc;
// 	delete[] y_cc;

	int BEGIN_X,BEGIN_Y,TotalLength,T1,T2;
	if ((*Shift)<0){
		BEGIN_X=X_AB;
		BEGIN_Y=Y_AB-(*Shift);
		T1=X_AE-X_AB+1;
		T2=Y_AE-Y_AB+1+(*Shift);
		TotalLength=(T1<T2)?T1:T2;
	}
	else{
		BEGIN_X=X_AB+(*Shift);
		BEGIN_Y=Y_AB;
		T1=X_AE-X_AB+1-(*Shift);
		T2=Y_AE-Y_AB+1;
		TotalLength=(T1<T2)?T1:T2;
	}

	(*CCDiff)=0;
	for (int index=0;index<TotalLength;index++){
		(*CCDiff)+=fabs(X.Signal[BEGIN_X+index]-Y.Signal[BEGIN_Y+index]);
	}
	(*CCDiff)/=TotalLength;


	// 3. Calculate Shift and Diff in the compare window.
	(*Shift)-=((X.Peak-X_AB)-(Y.Peak-Y_AB));

	(*Diff)=0;

	for (int index=L1;index<L2;index++){
		(*Diff)+=fabs(X.Signal[X.Peak+index]-Y.Signal[Y.Peak-(*Shift)+index]);
	}

	return;
}
