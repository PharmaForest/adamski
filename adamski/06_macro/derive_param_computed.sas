/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : derive_param_computed.sas
  SAS Version                 : 9.4
  Purpose (short description) : SAS macro to create most derived variables for CDISC BDS datasets
  Author                      : Cursor 4.7 edited by Paul Robertson
  Date                        : 31OCT2026
  Input Datasets or Metadata  : SAS work dataset containing ADSL vars and variables for computation of
                                a derived parameter from a single SDTM "findings" dataset (e.g. VS, EG, LB), 
                                having one record (row) per parameter component variable. 
  Modification Log            : 

  %derive_param_computed

  The SAS program calling this macro should have created a work datast that joins pertinent ADSL variables
  with selected variables from a SINGLE SDTM "Findings" dataset (e.g. VS, EG, LB). This input work dataset
  should have one record (row) for each variable that is included in the calculation needed for creation of
  the derived parameter. Thus, this macro performs the following tasks:  
 
    1. Create subset work datasets, one for each component variable for the derived parameter.
       These work datasets are generally sorted by USUBJID, AVISIT, ATPT, etc.
    2. Merge subset work datasets and compute the new parameter and assign PARAMCD, PARAM, AVAL values.
    3. Append the new parameter to the original input dataset.

  Note that this macro should not be used to create derived parameters that involve more than one SDTM
  Findings dataset. Thus, this macro should not be used to derive the Framingham study derived parameter
  that mixes units: systolic blood pressure in mmHg and cholesterol tests in mg/dL.

  Most derived parameters from a single SDTM Findings dataset include only two component variables. But
  this macro can handle more than two variables from a single SDTM findings dataset. Thus, the derived
  MAP parameter can be derived, it is computed from SYSBP, DIABP and HR. Again, note that Framingham is \
  not in scope.

  This macro also allows derived parameter computation using "constant_tests", measures collected once
  per subject, such as HEIGHT. Each of those is merged by USUBJID only and repeated onto every visit.

  The formula uses the test codes. Those names are the result columns after the split, not the original 
  EGSTRESN, LBSTRESN, VSSTRESN or AVAL column.


  EXAMPLE MACRO CALLS ----
  BMI derived with only one height measurement per subject -- note CONSTANT_TESTS macro parameter:

    %derive_param_computed(
             dataset = work.adsl_vs
    ,       test_var = VSTESTCD
    ,     result_var = VSSTRESN
    ,        usubjid = USUBJID
    ,          visit = VISIT
    ,            tpt = VSTPT
    ,          tests = WEIGHT
    , constant_tests = HEIGHT
    ,        formula = %str(WEIGHT / ((HEIGHT/100)**2))
    ,        paramcd = BMI
    ,          param = %str(Body Mass Index (kg/m^2))
    ,            out = work.adsl_vs_bmi
    );

  MAP derived from systolic and diastolic pressure at the same time point:

    %derive_param_computed(
             dataset = work.adsl_vs
    ,       test_var = VSTESTCD
    ,     result_var = VSSTRESN
    ,        usubjid = USUBJID
    ,          visit = VISIT
    ,            tpt = VSTPT
    ,          tests = SYSBP DIABP
    ,        formula = %str((2*DIABP + SYSBP)/3)
    ,        paramcd = MAP
    ,          param = %str(Mean Arterial Pressure (mmHg))
    ,            out = work.adsl_vs_map
    );

  MAP derived with heart rate as a third component at a single time point:

    %derive_param_computed(
             dataset = work.adsl_vs
    ,       test_var = VSTESTCD
    ,     result_var = VSSTRESN
    ,          tests = SYSBP DIABP HR
    ,        formula = %str(DIABP + 0.01 * exp(4.14 - 40.74 / HR) * (SYSBP - DIABP))
    ,        paramcd = MAP
    ,          param = %str(Mean Arterial Pressure (mmHg))
    ,            out = work.adsl_vs_map
    );

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%macro derive_param_computed(
         dataset =
,            out =
,       test_var = PARAMCD
,     result_var = AVAL
,        usubjid = USUBJID
,          visit = VISIT
,            tpt =
,          carry =
,          tests =
, constant_tests =
,        formula =
,        paramcd =
,          param =
);

  %local keys 
         lastkey 
         ntest 
         nconst 
         i 
         t 
         _cmp2_bad;

  %if %length(&dataset)=0 or
      %length(&out)=0     or 
      %length(&tests)=0   or
      %length(&formula)=0 or
      %length(&paramcd)=0 %then %do;
         %put WARNING: derive_param_computed requires dataset=, out=, tests=, formula=, and paramcd=.;
         %return;
  %end;

  /* Subject, visit, and optional time point. */
  %let keys = &usubjid &visit &tpt;

  %if %length(&tpt) %then %let lastkey = &tpt;
  %else                   %let lastkey = &visit;

  /* Visit-level tests, then subject-level tests. */
  %let ntest = 0;
  %let i     = 1;
  %let t     = %scan(&tests, &i, %str( ));
  %do %while(%length(&t));
      %let ntest      = %eval(&ntest + 1);
      %let test&ntest = &t;
      %let i          = %eval(&i + 1);
      %let t          = %scan(&tests, &i, %str( ));
  %end;

  %let nconst = 0;
  %let i = 1;
  %let t = %scan(&constant_tests, &i, %str( ));
  %do %while(%length(&t));
      %let nconst       = %eval(&nconst + 1);
      %let ctest&nconst = &t;
      %let i            = %eval(&i + 1);
      %let t            = %scan(&constant_tests, &i, %str( ));
  %end;

  %if &ntest = 0 %then %do;
      %put WARNING: derive_param_computed tests= did not contain a test code.;
      %return;
  %end;

  /* ------------------------------------------------------------------
     1. Subset to the named tests and the key variables.
     ------------------------------------------------------------------ */
  data work._cmp2_sub;
       set &dataset;
       where &test_var in (
                            %do i = 1 %to &ntest;
                                %if &i > 1 %then ,;
                                "&&test&i"
                            %end;
                            %do i = 1 %to &nconst;
                                , "&&ctest&i"
                            %end;
                          );
       keep &keys 
            &carry 
            &test_var 
            &result_var;
  run;

  /* ------------------------------------------------------------------
     2. One dataset per test. The result column is named with the test code.
        The first visit-level test also keeps the subject, visit, and carry vars.
     ------------------------------------------------------------------ */
  %do i = 1 %to &ntest;
      %let t = &&test&i;

      data work._cmp2_t&i;
           set work._cmp2_sub;
           where &test_var = "&t";
           &t = &result_var;
           %if &i = 1 %then %do;
               keep &keys &carry &t;
           %end;
           %else %do;
               keep &keys &t;
           %end;
      run;
  %end;

  %do i = 1 %to &nconst;
      %let t = &&ctest&i;

      data work._cmp2_c&i;
           set work._cmp2_sub;
           where &test_var = "&t";
           &t = &result_var;
           keep &usubjid &t;
      run;
  %end;

  /* One result per key. A repeated test at the same key stops the macro. */
  %let _cmp2_bad = 0;

  %do i = 1 %to &ntest;
      proc sort data=work._cmp2_t&i;
           by &keys;
      run;

      data _null_;
           set work._cmp2_t&i;
           by &keys;
           if not (first.&lastkey and last.&lastkey) then do;
              put "WARNING: More than one &&test&i. " &usubjid= &visit=
                   %if %length(&tpt) %then &tpt=;
              ;
              call symputx('_cmp2_bad', '1', 'F');
           end;
      run;
  %end;

  %do i = 1 %to &nconst;
      proc sort data=work._cmp2_c&i;
           by &usubjid;
      run;

      data _null_;
           set work._cmp2_c&i;
           by &usubjid;
           if not (first.&usubjid and last.&usubjid) then do;
              put "WARNING: More than one &&ctest&i for " &usubjid=;
              call symputx('_cmp2_bad', '1', 'F');
           end;
      run;
  %end;

  %if &_cmp2_bad = 1 %then %do;
      %put WARNING: derive_param_computed stopped. Each test must occur once per merge key.;
      %return;
  %end;

  /* ------------------------------------------------------------------
     3. Merge every visit-level test on the subject, visit, and time point.
        Then merge each subject-level test by USUBJID and compute.
     ------------------------------------------------------------------ */
  data work._cmp2_new;
       merge %do i = 1 %to &ntest;
                 work._cmp2_t&i (in=in&i)
             %end;
       ;
       by &keys;
       if %do i = 1 %to &ntest;
              %if &i > 1 %then and;
              in&i
          %end;
       ;
  run;

  %do i = 1 %to &nconst;
      proc sort data=work._cmp2_new;
           by &usubjid;
      run;

      data work._cmp2_new;
           merge work._cmp2_new (in=in_visit)
                 work._cmp2_c&i (in=in_const);
           by &usubjid;
           if in_visit and in_const;
      run;
  %end;

  data work._cmp2_new;
       set work._cmp2_new;
       AVAL = &formula;
       if not missing(AVAL);

       length PARAMCD $8 
              PARAM   $200;

       PARAMCD = "&paramcd";
       PARAM   = "&param";

       keep &keys 
            &carry 
            PARAMCD 
            PARAM 
            AVAL;
  run;

  /* ------------------------------------------------------------------
     4. Append the new rows to the original ADSL-plus-findings data.
     ------------------------------------------------------------------ */
  /* Clear the program vector before each read so a new row does not
     keep values from the previous source row. */
  data &out;
       if 0 then set &dataset work._cmp2_new;
       call missing(of _all_);
       set &dataset
           work._cmp2_new;
  run;

  proc datasets lib=work nolist;
       delete _cmp2_sub 
              _cmp2_new
              %do i = 1 %to &ntest;
                  _cmp2_t&i
              %end;
              %do i = 1 %to &nconst;
                  _cmp2_c&i
              %end;
        ;
  quit;

%mend derive_param_computed;
