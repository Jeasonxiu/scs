
// Constants
#define Dmaxl 100000                   // Max dlen
#define MAXtrace 3000                  // Max fileN
#define stackloopN 6                   // ESW constructing loops.


// Data Structure.
struct Data{

	// Parameters. (Read from main.c)
	//
    int     fileN;                     // File list Number
	int     dlen;                      // Data length (npts.) after cut and interpolation.
	int     Elen;                      // ESW window width (npts.)
	int     Slen;                      // Signal window width (npts.)
	int     Nlen;                      // Noise window width (npts.)
	int     passes;
	int     order;
	int     eloc;                      // ESW window begin position (npts relative to ploc or stack_p)
	int     sloc;                      // Signal window begin position (npts relative to ppeak)
	int     nloc;                      // Noise window begin position (npts relative to naloc)
	int     stack_p;                   // OnSet location on ESW stack. (npts from beginning)
    char    EQ[20];
	char    PHASE[10];
	char    OUTDIR[200];
	char    INFILE[200];
	char    STDOUT[200];
	char    OUTFILE[200];
    double  C1;                        // First data point time relative to chosen PREM arrival (sec.)
	double  C2;                        // Use C2-C1, delta to get dlen
	double  E1;                        // ESW window begin position (sec relative to ploc or stack_p)
	double  E2;                        // Use E2-E1, delta to get Elen
	double  F1;
	double  F2;
	int     Filter_Flag;
	double  S1;                        // Signal window begin position (sec relative to ppeak)
	double  S2;                        // Use S2-S1, delta to get Slen
	double  N1;                        // Noise window begin position (sec relative to naloc)
	double  N2;                        // Use N2-N1, delta to get Nlen
	double  taperwidth;                // taperwidth when reading data, applied this taper before bandpass.
	double  delta;
	double  SNRLOW;
	double  SNRHIGH;
	double  CCCOFF;
	double  ramp;
	double  WBegin;                    // Find S peak in quick. window begin position (sec. relative to ploc)
	double  WLen;                      // S peak searching window length (sec.)
	double  WBegin_ScS;                // Find ScS peak in quick. window begin position (sec. relative to ploc)
	double  WLen_ScS;                  // ScS peak searching window length (sec.)

	// Trace parameters. (Read from file in ESW_Read.fun.c)
	//
	int     *ploc;                     // OnSet location on each trace. (npts from beginning)
	int     *naloc;                    // Noise Anchor location on each trace. (npts from beginning)
	double  *rad_pat;
	double  **data;
	char    **stnm;

	// Non-parameters.

	int     contribute;                // # of Non-zero weight traces for ESW.
	double  waterlevel;                // Measurement of noise fft amplitude peak value on stack.

    int     *shift;                    // Shift npts for every ESW-windowed section relative to ESW.
	int     *ppeak;                    // Peak position of each trace. (npts from beginning)
	int     *polarity;                 // The sign of p->data[count][ppeak].
    double  *weight;                   // Stack weight for each trace. Allow for negative value, means flip the trace.
	double  *snr;                      // SNR measurements for each trace.
	double  *ccc;                      // Cross-Correlation-Coefficients with ESW for each trace.
	double  *misfit;                   // Half-height width difference between trace pulse and ESW pulse.
	double  *misfit2;                  // Half-height area difference between trace pulse and ESW pulse.
	double  *misfit3;                  // Peak to zero width difference between trace pulse and ESW pulse.
	double  *misfit4;                  // Peak to zero area difference between trace pulse and ESW pulse.
	double  *M1_B;                     // Begin time of misfit (Half height) estimation. (relative to prem)
	double  *M1_E;                     // End time of misfit (Half height) estimation. (relative to prem)
	double  *M2_B;                     // Begin time of misfit (whole trace) estimation. (relative to prem)
	double  *M2_E;                     // End time of misfit (whole trace) estimation. (relative to prem)
	double  *norm2;                    // 2-norm difference between trace and ESW through ESW-window.
	double  *amplitude;                // Waveform absolute amplitude is recored here. In program we usually normalized the peak to 1.
	double  *stack;
	double  *std;
	double  *spectrummax;              // Measurement of noise fft amplitude peak value on each trace.
};


// Functions.
void  ESW_Initialize(struct Data *);
void  ESW_Check(struct Data *);
void  ESW_ReadSAC(struct Data *);
void  ESW_ReadFile(struct Data *);
void  ESW_Work(struct Data *);
void  ESW_Output(struct Data *);
void  CleanUp(int *, char **, double *, int);

// In ESW_Utils.fun.c
void  FindPeak(struct Data *, int);
void  MakeStack(struct Data *, int);
void  MakeWeight(struct Data *, int);
void  PickOnSet(struct Data *, int);

// In ESW_Estimates.fun.c
void  EvaluateSNR(struct Data *);
void  Misfit(struct Data *);
void  MakeNorm(struct Data *);
void  NoiseFreq(struct Data *);
