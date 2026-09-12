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

/* To collect expected errors */
%let error1_found=0;
%let error2_found=0;
%let abort_found=0;

filename testlog temp;

proc printto log=testlog new;
run;

/* ANRHI does not exist in t_data */
%derive_var_analysis_ratio(
    dataset   = t_data,
    numer_var = AVAL,
    denom_var = ANRHI
	);

proc printto;
run;

data _null_;
  infile testlog truncover;
  input line $char1000.;

  /* 1. Missing variable */
  if index(line, 'ERROR: derive_var_analysis_ratio: Variable ANRHI not found') > 0 then
    call symputx('error1_found', 1);

  /* 2. Macro stopped due to invalid input */
  if index(line, 'ERROR: derive_var_analysis_ratio: Macro execution stopped due to invalid input variable(s).') > 0 then
    call symputx('error2_found', 1);
run;

%mp_assert(
  iftrue=(
    &error1_found = 1
    and &error2_found = 1
  ),
  desc=(%nrstr(%derive_var_analysis_ratio))[test02] Check if expected errors are output,
  outds=TEMP.adamski_test
)
