#include<stdlib.h>
#include<assert.h>
#include<tomography.h>

/***********************************************************
 * This C function free loaded Tomography model from RAM.
 *
 * struct Tomography *data  ----  input Tomography pointer.
 *
 * Shule Yu
 * May 30 2014
***********************************************************/

void free_tomography(struct Tomography *data){

    assert(data);

    free(data->v);
    free(data->depth);
    free(data->lat);
    free(data->lon);

    return;
}
