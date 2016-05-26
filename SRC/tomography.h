
// This header file contains the definition of Tomography struct
// and decleared some functions utility for this structure.

struct Tomography{

    int Ndata;      // number of data points.
    int Ndepth;     // number of depth layer points.
    int Nlat;       // number of latitude points.
    int Nlon;       // number of longitude points.

    double *v;      // velocity data.
    double *depth;  // depth data.
    double *lat;    // latitdue data.
    double *lon;    // longitude data.

    double MinLon;  // Longitude min.
    double MaxLon;  // Longitude max.
    double MinLat;  // Latitude min.
    double MaxLat;  // Latitude max.
    double MinD;    // Depth min.
    double MaxD;    // Depth max.

};

void   read_tomography(struct Tomography *);

void   free_tomography(struct Tomography *);

double getvelocity(struct Tomography *,double,double,double,char *);

void   getindex(struct Tomography *, double , double , double , int *, int *, double *, int *, int *, double *, int *, int *, double *);
