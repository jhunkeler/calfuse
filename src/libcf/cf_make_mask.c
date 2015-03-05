/***********************************************************************
 *
 *                  CF_MAKE_MASK
 *
 *    Procedure to create a mask of the bad pixels from the pixel list
 *    generated by cf_bad_pixels
 *
 *    CALL: cf_make_mask(header, ap, nout, wave_out, bny, bymin, bpmask)
 *
 *    Arguments: fitsfile    header   name of the input IDF 
 *               int         ap       Aperture designation
 *               long        nout     number of points in wavelength array
 *               float       wave_out wavelength array
 *               int         bny      Y dimension of the output image -
 *                                    should be same as background
 *               int         bymin    Y coordinate of first element in 
 *                                    output array. Should match background
 *               float       bpmask   Output bad pixel mask - dimensions
 *                                    are nout * bny 
 *
 *    History:	04/29/03  rdr  v1.0	Begin work 
 *		04/30/03  wvd  v1.1	Install
 *		09/30/03  wvd  v1.2	Use cf_read_col to read BPM_CAL
 *					file.
 *		11/11/03  wvd  v1.3	Fix bug in normalization of
 *					pothole map.
 *		07/21/04  wvd  v1.4	Fix bug in construction of
 *					pothole mask: change & to && 
 *		11/25/05  wvd  v1.5	Fill gaps in the mask that
 *					open when the bad-pixel map
 *					is converted from pixels to
 *					wavelengths.
 *
 ***********************************************************************/

#include "calfuse.h"

int cf_make_mask(fitsfile *header, int ap, long nout, float *wave_out, 
int bny, int bymin, float **bpmask){

    char CF_PRGM_ID[] = "cf_make_mask";
    char CF_VER_NUM[] = "1.5";

    char bpm_file[FLEN_VALUE], *chan;
    int *bphist, nhist, status=0;
    long bpsum, i, j, k, ndx, nsam, npix, npts;
    float *bpmaskt, w0, wpc, pnorm=1;
    float *x, *y, *wt, *lam ;
    float bpmax ;
    fitsfile *bpmfits ;

    cf_error_init(CF_PRGM_ID, CF_VER_NUM, stderr);
    cf_timestamp(CF_PRGM_ID, CF_VER_NUM, "Begin Processing");

    cf_verbose(3, "Entering routine cf_make_mask") ;

    /* Generate an array (nout * bny) to contain the map. */
    npix = nout * bny;
    bpmaskt = cf_calloc(npix, sizeof(float)) ;

    /* Read wavelength information from input file header. */
    FITS_movabs_hdu(header, 1, NULL, &status);
    FITS_read_key(header, TFLOAT, "WPC", &wpc, NULL, &status);
    w0 = wave_out[0];
    cf_verbose(3, "Wavelengths: w0=%g, dw=%g", w0, wpc);

    /* Open the bad-pixel file. */
    if (fits_read_key(header, TSTRING, "BPM_CAL", bpm_file, NULL, &status)) {
	cf_verbose(0,
	    "No bad pixel (BPM_CAL) file specified.  Assuming no potholes.") ;
	for (i=0; i<npix; i++) bpmaskt[i] = 1.;
	*bpmask = bpmaskt;
	return 0;
    }
    cf_verbose(3, "Bad Pixel file = %s ", bpm_file) ;
    if (fits_open_file(&bpmfits, bpm_file, READONLY, &status) ) {
	cf_verbose(0,
	    "No bad pixel (BPM_CAL) file found.  Assuming no potholes.");
	for (i=0; i<npix; i++) bpmaskt[i] = 1.;
	*bpmask = bpmaskt;
	return 0;
    };

    /* Read the BPM file. */
    FITS_movabs_hdu(bpmfits, 2, NULL, &status);
    npts = cf_read_col(bpmfits, TFLOAT, "X",       (void **) &x);
    npts = cf_read_col(bpmfits, TFLOAT, "Y",       (void **) &y);
    npts = cf_read_col(bpmfits, TFLOAT, "WEIGHT",  (void **) &wt);
    npts = cf_read_col(bpmfits, TFLOAT, "LAMBDA",  (void **) &lam);
    npts = cf_read_col(bpmfits, TBYTE,  "CHANNEL", (void **) &chan);

    /* Fill the map with pothole information. */
    nsam = 0;
    for (i=0; i<npts; i++) {
	if (chan[i] == ap) {
	    j = (long) ( (lam[i] - w0)/wpc + 0.5 ) ;
	    k = (long) ( (y[i] - bymin) + 0.5 ) ;
	    if (j < nout && k < bny) {
		nsam++ ;
		ndx = k*nout + j ;
		if (ndx > 0 && ndx < npix) bpmaskt[ndx] += wt[i] ;
	    }
	}
    }
    cf_verbose(3, "Channel %d contains %d bad pixels.", ap, nsam) ;

    /* If any potholes are present, generate the pothole map. */
    if(nsam > 0) {

	/* Determine a normalization for the potholes. This is done by
	creating a histogram of the weights between 0 and the maximum
	and then selecting the 95% level as the normalization factor.
	We use 95%, rather than the maximum, to avoid the possibility
	of having a few spurious points define the normalization. */

	/* Determine the maximum value. */
	bpmax = 0.;
	for (i=0; i<npix; i++)
	    if (bpmaskt[i] > bpmax) bpmax = bpmaskt[i] ;

	/* Generate the histogram. */
	nhist = (int) (bpmax * 10.) + 1 ;
	bphist = (int *) cf_calloc(nhist, sizeof(int)) ;
	bpsum = 0;
	for (i=0; i < npix; i++) {
	    ndx = (int) (bpmaskt[i] * 10.) ;
	    if (ndx > 0 && ndx < nhist) {
		bphist[ndx]++;
		bpsum++;
	    }
	}

	/* Now select the 95% level. */
	nsam = 0;
	i = nhist-1 ;
	while (nsam < bpsum/20 && i >= 0) {
	    nsam += bphist[i] ;
	    pnorm = bpmax - (nhist-1-i) / 10. ;
	    i--;
	}

	cf_verbose(3, "bpmax = %.1f, normalizing factor = %.2f", bpmax, pnorm) ;      

	/* Normalize and invert the mask so that the center of the
	pothole is zero and the region outside is 1. */

	for (i=0; i<npix; i++) {
	    bpmaskt[i] = 1. - (bpmaskt[i] / pnorm) ;
	    if (bpmaskt[i] < 0.) bpmaskt[i] = 0. ;
	}

	/* If a pixel in the mask is higher than both of its neighbors,
	it probably represents a gap that opened when converting from
	pixels to wavelengths.  Fill it. */

	for (j = 1; j < nout-1; j++) {
	    for (k = 0; k < bny; k++) {
		ndx = k*nout + j ;
		if (bpmaskt[ndx-1] < bpmaskt[ndx] && bpmaskt[ndx] > bpmaskt[ndx+1])
			bpmaskt[ndx] = (bpmaskt[ndx-1] + bpmaskt[ndx+1]) / 2.;
	    }
	}
    }

    /* If there are no potholes, generate an array with all ones. */
    else 
	for (i=0; i<npix; i++) bpmaskt[i] = 1. ;

    /* Redirect the pointer. */
    *bpmask = bpmaskt;

    cf_timestamp(CF_PRGM_ID, CF_VER_NUM, "Done processing");

    return status ;
}