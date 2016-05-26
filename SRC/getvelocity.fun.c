#include<stdio.h>
#include<math.h>
#include<string.h>
#include<ASU_tools.h>
#include<tomography.h>

/***********************************************************************
 * Assume tomography model covers all longitude ( -180 ~ 180 lon. ).
 * Assume the depth array in the model is monotonously increasing.
 *
 * This C function locate the position of a given point in the tomography
 * model and then use linear interpolation ( 2D if the depth is at
 * a discontinuity, 3D if the depth is not ) to get the velocity at the
 * given point.
 *
 * The velocity array is a 1D array, arranged in the
 * order of Depth , Latitude , Longitude. Which means the increasing
 * index of the 1D array first loop through Longitude. When
 * Longitude is counted data->Nlon times, Latitude++. When Latitude is
 * counted data->Nlat times, Depth++.
 *
 * For locations outside the Model range, two work around is provided:
 * 1. Return PREM velocity at the given depth.
 * 2. Return model value at latitude and depth boundary near that point.
 * For locations outside earth .. Er .. notify and return -1.
 *
 * struct Tomography *data  ----  Tomography model.
 * double            lon    ----  Given point longitude.
 * double            lat    ----  Given point latitude.
 * double            depth  ----  Given point depth.
 *
 * Shule Yu
 * May 26 2014
***********************************************************************/

void getindex(struct Tomography *data, double lon, double lat, double depth, int *indexD1, int *indexD2, double *ddepth, int *indexLo1, int *indexLo2, double *dlon, int *indexLa1, int *indexLa2, double *dlat){


	// Find depth layer.

	int depthP;

    for (depthP=0;depthP<data->Ndepth-1;depthP++){
        if ( data->depth[depthP]<=depth && depth<=data->depth[depthP+1] ){
            break;
        }
    }

    *indexD1=depthP;
    *indexD2=depthP+1;

    // If the point is on a discontinuity depth, use the value on the shallower side into interpolation.
    if (data->depth[*indexD1]==data->depth[*indexD2]){
        *ddepth=0;
    }
    else{
        *ddepth=(depth-data->depth[*indexD1])/(data->depth[*indexD2]-data->depth[*indexD1]);
    }

    // Find longitude position.

	int lonP,flag;
    double abs1,abs2,dx;

    flag=0;
	abs1=1e6;
	abs2=1e6;

	// If given point is on the longitude boundary of model cubic.
    for (lonP=0;lonP<data->Nlon;lonP++){
        if (lon==data->lon[lonP]){
            *indexLo1=lonP;
            *indexLo2=lonP;
            *dlon=0;
            flag=1;
            break;
        }
    }

    if (flag==0){
        if ( lon < data->MinLon || lon > data->MaxLon ){ // If given point is on the east of MaxLon and west of MinLon.
            min_vald(data->lon,data->Nlon,indexLo1);
            max_vald(data->lon,data->Nlon,indexLo2);
            *dlon=(lon<0?(data->MinLon-lon):(360+data->MinLon-lon))/(360+data->MinLon-data->MaxLon);
        }
        else{ // If given point is inside model range. Due to the un-sorted longitude order for some model.
			  // We need to find the nearest two longitude boundaries to the given point.
            for (lonP=0;lonP<data->Nlon;lonP++){
                dx=fabs(data->lon[lonP]-lon);
                if ( abs2>dx ){
                    abs2=abs1;
                    if (abs1<dx){
                        abs2=dx;
                        *indexLo2=lonP;
                    }
                    else{
                        abs1=dx;
                        *indexLo2=*indexLo1;
                        *indexLo1=lonP;
                    }
                }
            }
            *dlon=(abs1)/(abs1+abs2);
        }
    }

    // Find latitude position.
    int latP;

    flag=0;
	abs1=1e6;
	abs2=1e6;

	// If given point is on the latitude boundary of model cubic.
    for (latP=0;latP<data->Nlat;latP++){
        if (lat==data->lat[latP]){
            *indexLa1=latP;
            *indexLa2=latP;
            *dlat=0;
            flag=1;
            break;
        }
    }
    if (flag==0){ // If given point is inside model range. Due to the un-sorted latitude order for some model.
			      // We need to find the nearest two latitude boundaries to the given point.
        for (latP=0;latP<data->Nlat;latP++){
            dx=fabs(data->lat[latP]-lat);
            if ( abs2>dx ){
                abs2=abs1;
                if (abs1<dx){
                    abs2=dx;
                    *indexLa2=latP;
                }
                else{
                    abs1=dx;
                    *indexLa2=*indexLa1;
                    *indexLa1=latP;
                }
            }
        }
        *dlat=(abs1)/(abs1+abs2);
    }

    return;
}

double getvelocity(struct Tomography *data, double lon, double lat, double depth, char *COMP){

	// Check if the given point is outside of earth.

    if (depth<0 || depth>6371){
        printf("In %s: given point is outside of earth :0 \n",__func__);
        return -1;
    }

	// Convert longitude between -180 ~ 180.

	lon=lon2180(lon);

	// Set up PREM velocity just in case.
    double (*v)(double);

    if (strcmp(COMP,"P")==0){
        v=d_vp;
    }
    else {
        v=d_vs;
    }


	// If the given point locate outside of the tomography model:

	// Work around 1. Use PREM value.

    if ( depth < data->MinD || depth > data->MaxD ){
        printf("In %s: point outside model. Depth: %.2lf ( %.2lf ~ %.2lf ) ..\n",__func__,depth,data->MinD,data->MaxD);
		printf("Using PREM value at this point...");
        return v(depth);
    }

    if ( lat < data->MinLat || lat > data->MaxLat ){
        printf("In %s: point outside model. Lat: %.2lf ( %.2lf ~ %.2lf )..\n",__func__,lat,data->MinLat,data->MaxLat);
		printf("Using PREM value at this point...");
        return v(depth);
    }

	// Work around 2. Treat the given point as they are at boundary.

//     if (depth < data->MinD ){
//         depth = data->MinD;
//     }
//     if (depth > data->MaxD ){
//         depth = data->MaxD;
//     }
//     if (lat < data->MinLat ){
//         lat = data->MinLat;
//     }
//     if (lat > data->MaxLat ){
//         lat = data->MaxLat;
//     }

    // Locate which model cubic contains the given point.

    int    indexD1,indexD2,indexLo1,indexLo2,indexLa1,indexLa2;
    double ddepth,dlon,dlat;

    getindex(data,lon,lat,depth,&indexD1,&indexD2,&ddepth,&indexLo1,&indexLo2,&dlon,&indexLa1,&indexLa2,&dlat);

	// Debug information:
// printf("%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\t%.2lf\n",ddepth,dlon,dlat,data->depth[indexD1],data->depth[indexD2],data->lon[indexLo1],data->lon[indexLo2],data->lat[indexLa1],data->lat[indexLa2]);


	// Linear interpolate within this model cubic.

	double cubic[8];

	cubic[0]=data->v[indexD1*data->Nlon*data->Nlat+indexLa1*data->Nlon+indexLo1];
	cubic[1]=data->v[indexD1*data->Nlon*data->Nlat+indexLa1*data->Nlon+indexLo2];
	cubic[2]=data->v[indexD1*data->Nlon*data->Nlat+indexLa2*data->Nlon+indexLo1];
	cubic[3]=data->v[indexD1*data->Nlon*data->Nlat+indexLa2*data->Nlon+indexLo2];
	cubic[4]=data->v[indexD2*data->Nlon*data->Nlat+indexLa1*data->Nlon+indexLo1];
	cubic[5]=data->v[indexD2*data->Nlon*data->Nlat+indexLa1*data->Nlon+indexLo2];
	cubic[6]=data->v[indexD2*data->Nlon*data->Nlat+indexLa2*data->Nlon+indexLo1];
	cubic[7]=data->v[indexD2*data->Nlon*data->Nlat+indexLa2*data->Nlon+indexLo2];

	return interp3_linear(cubic,dlon,dlat,ddepth);
}
