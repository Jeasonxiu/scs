	double **ScSWaveformTapered_amp=new double *[Data.size()];
	double **ScSWaveformTapered_time=new double *[Data.size()];
		ScSWaveformTapered_amp[index]=new double[NPTS_Cut];
		ScSWaveformTapered_time[index]=new double[NPTS_Cut];

	double *oldESW_amp=new double[NPTS_Cut];
	double *oldESW_time=new double[NPTS_Cut];
	int *TstarOperator_Peak= new int [PI[nXStretch]];

	double **TstarOperator = new double *[PI[nXStretch]],Ts,TsINC;
		TstarOperator[index]=new double[NPTS_Tstar];

	int *TstaredESW_Peak= new int [PI[nXStretch]];

	double **TstaredESW = new double *[PI[nXStretch]];
		TstaredESW[index]=new double[NPTS_Tstar+NPTS_TstaredESW-1];
