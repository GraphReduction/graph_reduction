/*=================================================================
 * readmatrix.cpp
 *
 * read matrix from file using c, which is faster than using MATLAB
 * only for symmetric matrix
 *=================================================================*/
#include "mex.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define X_IN prhs[0]
#define Ir plhs[0]
#define Jc plhs[1]
#define V plhs[2]

typedef double unt;

/* Function declarations */
static void	checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

/*
 * Main gateway function called by MATLAB.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *filename;
	char buf[1000];
	int buflen, status, n;
	unt nrow, ncol;
	mwSize nzmax, nn, mm,kk, nonzero, nnz, linenum, i;
	unt *row, *col;
	double *irow, *icol;
	double *vval, *val;
	double v;
	FILE *fp;
	
	checkArguments(nlhs, plhs, nrhs, prhs);

	/* calculate the length of the string */
	buflen = (mxGetM(X_IN)*mxGetN(X_IN))+1;

	/* Allocate memory for the input and output string */
/*	filename = (char*)mxCalloc(buflen, sizeof(char));*/

	/* Copy string data from X_IN to C string */
/*	status = mxGetString(X_IN, filename, buflen);
	mexPrintf("filename: %s\n");
	if(status != 0){
		mexWarnMsgTxt("Not enough space. String is truncated.");
	}*/

	filename = mxArrayToString(X_IN);
	if(filename == NULL){
		mexWarnMsgTxt("Not enough space. String is truncated.");
	}
	
	fp = fopen(filename, "r");
	if(fp == NULL){
		mexWarnMsgTxt("Cannot open file");
	}

	if(fgets(buf, 1000, fp)){
		n = sscanf(buf, "%zd %zd %zd", &nn, &mm, &nnz);
		if(nn != mm){
			 mexErrMsgIdAndTxt( "MATLAB:readmatrix:Invalid input matrix format", "Inut matrix must be square matrix.");
		}
	}

	row = (unt*) mxCalloc(nnz, sizeof(unt));
	col = (unt*) mxCalloc(nnz, sizeof(unt));
	vval = (double*) mxCalloc(nnz, sizeof(double));

	nzmax = nnz;
	linenum = 0;
	nonzero = 0;
	while(fgets(buf, 1000, fp)){

		if(linenum >= nzmax){
			nzmax = nzmax*2-n;
			unt* row_new = (unt*) mxRealloc(row, nzmax*sizeof(unt));
			unt* col_new = (unt*) mxRealloc(col, nzmax*sizeof(unt));		
			double* vval_new = (double*) mxRealloc(vval, nzmax*sizeof(double));

			if(row_new == NULL || vval_new == NULL || col_new == NULL){
		        mexErrMsgTxt( "MATLAB:readmatrix:Allocate memory fail!!");
			}
			row = row_new;
			col = col_new;
			vval = vval_new;
		}

		n = sscanf(buf, "%lf %lf %lf", &nrow, &ncol, &v);
		if(nrow >= ncol){
			row[linenum] = nrow;
			vval[linenum] = v;
			col[linenum] = ncol;
			nonzero++;
			if(nrow > ncol){
				linenum++;
				nonzero++;
				if(linenum >= nzmax){
					nzmax = nzmax*2-n;
					unt* row_new =(unt*) mxRealloc(row, nzmax*sizeof(unt));
					unt* col_new =(unt*) mxRealloc(col, nzmax*sizeof(unt));
					double* vval_new =(double*) mxRealloc(vval, nzmax*sizeof(double));

					if(row_new == NULL || vval_new == NULL || col_new == NULL){
		        		mexErrMsgTxt( "MATLAB:readmatrix:Allocate memory fail!!");
					}
					row = row_new;
					col = col_new;
					vval = vval_new;
				}

				row[linenum] = ncol;
				vval[linenum] = v;
				col[linenum] = nrow;
			}
			linenum++;
		}
	}

	fclose(fp);

	Ir = mxCreateDoubleMatrix(nonzero, 1, mxREAL);
	Jc = mxCreateDoubleMatrix(nonzero, 1, mxREAL);
	V = mxCreateDoubleMatrix(nonzero, 1, mxREAL);

	irow = (double*) mxGetPr(Ir);
	icol = (double*) mxGetPr(Jc);
	val = (double*) mxGetPr(V);

	for(i=0; i<nonzero; i++){
		irow[i] = row[i];
		icol[i] = col[i];
		val[i] = vval[i];
	}



	mxFree(row);
	mxFree(col);
	mxFree(vval);
	mxFree(filename);
}


static void
        checkArguments(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    mwSize n, p;

    /* Check for proper number of input and output arguments */
    if (nrhs != 1) {
        mexErrMsgIdAndTxt( "MATLAB:readmatrix:invalidNumInputs",
                "One input arguments required.");
    }
    if (nlhs != 3) {
        mexErrMsgIdAndTxt( "MATLAB:readmatrix:invalidNumOutputs",
                "Too many output arguments.");
    }
	if(mxIsChar(prhs[0]) != 1){
		mexErrMsgIdAndTxt("MATLAB:readmatrix:Invalid Input", "Input must be a string.");
	}
}
