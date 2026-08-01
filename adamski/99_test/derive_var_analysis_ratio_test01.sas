/*** HELP START ***//*

### Purpose:
	- Unit test for the %derive_var_analysis_ratio() macro
	- Derive ratio variables using BASE and ANRLO
	- Default output variable names (R2BASE and R2ANRLO)

### Expected result:
	- Output dataset contains R2BASE and R2ANRLO
	- Ratio is set to missing when denominator is zero

*//*** HELP END ***/

%loadPackage(valivali)
%set_tmp_lib(lib=TEMP, winpath=C:\Temp, otherpath=/tmp, newfolder=adamski)

/* Expected dataset */
data e_data;
    length USUBJID $10 PARAMCD $8;
    input USUBJID $ PARAMCD $ SEQ AVAL BASE ANRLO R2BASE R2ANRLO;
    datalines;
    P01 ALT 1 27 27 6 1.0000000000 4.5000000000
    P01 ALT 2 41 27 6 1.5185185185 6.8333333333
    P01 ALT 3 17 27 6 0.6296296296 2.8333333333
    P02 ALB 1 38 38 33 1.0000000000 1.1515151515
    P02 ALB 2 39 38 33 1.0263157895 1.1818181818
    P02 ALB 3 37 38 33 0.9736842105 1.1212121212
    P03 ALT 1 10  0  5 .            2.0000000000
    ;
run;

/* Test dataset */
/* ANRHI intentionally not included */
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

/* Derive R2BASE */
%derive_var_analysis_ratio(
    dataset   = t_data,
    numer_var = AVAL,
    denom_var = BASE
	);

/* Derive R2ANRLO */
%derive_var_analysis_ratio(
    dataset   = t_data,
    numer_var = AVAL,
    denom_var = ANRLO
	);

/* Compare */
%mp_assertdataset(
    base=e_data,
    compare=t_data,
    desc=(%nrstr(%derive_var_analysis_ratio))[test01] Compare expected and derived ratio variables using BASE and ANRLO,
    id=USUBJID PARAMCD SEQ,
    by=,
    criterion=1E-10,
    method=absolute,
    outds=TEMP.adamski_test
	);
