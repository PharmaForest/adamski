/*** HELP START ***//*

### Purpose:
	- Unit test for the %derive_var_analysis_ratio() macro
	- Verify that the macro reports an error when the denominator variable does not exist in the input dataset.

### Expected result:
	- Macro terminates without creating an output dataset.
	- The following message is written to the SAS log:

	  ERROR: derive_var_analysis_ratio: Variable ANRHI not found in input dataset t_data.
	  ERROR: derive_var_analysis_ratio: Macro execution stopped due to invalid input variable(s).

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/* Test dataset */
/* ANRHI is intentionally not included */
data t_data;
	length USUBJID $10 PARAMCD $8;
	input USUBJID $ PARAMCD $ SEQ AVAL BASE ANRLO;
	datalines;
	P01 ALT 1 27 27 6
	P01 ALT 2 41 27 6
	P01 ALT 3 17 27 6
	P02 ALB 1 38 38 33
	P02 ALB 2 39 38 33
	P02 ALB 3 37 38 33
	P03 ALT 1 10 0 5
	;
run;

/* ANRHI does not exist in t_data */
%derive_var_analysis_ratio(
    dataset   = t_data,
    numer_var = AVAL,
    denom_var = ANRHI
	);
