/*** HELP START ***//*

### Macro:
    %derive_vars_cat

### Purpose:
    Derive Categorization Variables Like `AVALCATy` and `AVALCAyN`

### Parameters:  

 - `dataset` (required)	: Input dataset (with original observations)

 - `definition` (required) : Rule dataset containing CONDITION and target vars.
 							 (It is a rule table that defines the logical condition and the corresponding category values to assign)

 - `by_vars` (optional)	: Space-separated list of grouping variables (e.g. STUDYID USUBJID PARAMCD)

 - `outdata` (optional, default=&dataset._cat): Output dataset with category variables


### Sample code:

~~~sas

****Input Data;
data advs;
  length USUBJID $12 VSTEST $10;
  infile datalines truncover;
  input USUBJID $ VSTEST $ AVAL;
datalines;
01-701-1015 Height 147.32
01-701-1015 Weight 53.98
01-701-1023 Height 162.56
01-701-1023 Weight .
01-701-1028 Height .
01-701-1028 Weight .
01-701-1033 Height 175.26
01-701-1033 Weight 88.45
;
run;


****Test1;
data definition;
  length CONDITION $200 AVALCAT1 $20 ;
  infile datalines dlm='|' truncover;
  input CONDITION $ AVALCAT1 $ AVALCA1N;
datalines;
AVAL >= 140|>=140 cm|1
AVAL >0 and AVAL < 140|<140 cm|2
;
run;

%derive_vars_cat(
  dataset=advs,
  definition=definition
);


****Test2;
data definition;
  length CONDITION $200 AVALCAT1 $20 NEWCOL $20;
  infile datalines dlm='|' truncover;
  input CONDITION $ AVALCAT1 $ AVALCA1N NEWCOL $;
datalines;
VSTEST="Height" and AVAL>160|>160_cm|1|extra1
VSTEST="Height" and aval ne . and AVAL<=160|<=160_cm|2|extra2
;
run;

%derive_vars_cat(
  dataset=advs,
  definition=definition,
  outdata=advs_test
);


****Test3;
data definition;
    length VSTEST $10 CONDITION $50 AVALCAT1 $10 AVALCA1N 8 AVALCAT2 $6 AVALCA2N 8 AVALCAT3 $7;
    infile datalines dlm='|' dsd truncover;
    input VSTEST $ CONDITION $ AVALCAT1 $ AVALCA1N AVALCAT2 $ AVALCA2N AVALCAT3 $;
datalines;
Height|AVAL>160|>160 cm|1|Tall|1|Group A
Height|AVAL ne . and AVAL<=160|<=160 cm|2|Short|2|Group B
Weight|AVAL>70|>70 kg|3|Heavy|3|Group C
Weight|AVAL ne . and AVAL<=70|<=70 kg|4|Light|4|Group D
;
run;

%derive_vars_cat(
  dataset=advs,
  definition=definition,
  outdata=advs_test
);


****Test4;
data definition;
    length VSTEST $10 CONDITION $50 AVALCAT1 $10 AVALCA1N 8 AVALCAT2 $6 AVALCA2N 8 AVALCAT3 $7;
    infile datalines dlm='|' dsd truncover;
    input VSTEST $ CONDITION $ AVALCAT1 $ AVALCA1N AVALCAT2 $ AVALCA2N AVALCAT3 $;
datalines;
Height|AVAL>160|>160 cm|1|Tall|1|Group A
Height|AVAL ne . and AVAL<=160|<=160 cm|2|Short|2|Group B
Weight|AVAL>70|>70 kg|3|Heavy|3|Group C
Weight|AVAL ne . and AVAL<=70|<=70 kg|4|Light|4|Group D
;
run;


%derive_vars_cat(
  dataset=advs,
  definition=definition,
  by_vars = VSTEST,
  outdata=advs_test
);


****Test5;
data adlb;
  length USUBJID $12 PARAM $10 AVAL 8 AVALU $10 ANRHI 8;
  infile datalines dlm=',' dsd truncover;
  input USUBJID $ PARAM $ AVAL AVALU $ ANRHI;
datalines;
01-701-1015,ALT,150,U/L,40,
01-701-1023,ALT,70,U/L,40,
01-701-1036,ALT,130,U/L,40,
01-701-1048,ALT,30,U/L,40,
01-701-1015,AST,50,U/L,35
;
run;


data definition;
    length PARAM $10 CONDITION $50 MCRIT1ML $15 MCRIT1MN 8;
    infile datalines dlm=',' dsd truncover;
    input PARAM $ CONDITION $ MCRIT1ML $ MCRIT1MN;
datalines;
ALT,AVAL <= ANRHI,<=ANRHI,1
ALT,ANRHI < AVAL & AVAL <= 3 * ANRHI, >1-3*ANRHI,2
ALT,3 * ANRHI < AVAL, >3*ANRHI,3
;
run;

%derive_vars_cat(
  dataset=adlb,
  definition=definition,
  by_vars = PARAM,
  outdata=adlb_test
);


~~~

### Note:

  - Definition dataset must contain:
    The column `condition` which will be converted to a logical expression and will be used on the input `dataset` parameter.
    At least one additional column with the new column name and the category value(s) used by the logical expression.
    The column specified in `by_vars` (if `by_vars` is specified)

    e.g.
    condition      AVALCAT1    AVALCA1N
    AVAL >= 140    >=140 cm     1
    AVAL < 140     <140 cm      2

  - Parameter `outdata` is an additional (optional) parameter in adamski (not exists in admiral) for the output dataset. 
    It returns the input dataset with the new category variables added, based on the rules passed in the `definition` dataset for variable categorization.
  
  
### URL:

https://github.com/PharmaForest/adamski

---

Author:          	    Sharad Chhetri
Latest udpate Date: 	2026-02-28

---

*//*** HELP END ***/



%macro derive_vars_cat(
    dataset=,
    definition=,
    by_vars=,
    outdata=
);
  
  /* set local macro variables */
  %local lib_in mem_in lib_con mem_con drop_common i nby this_by dsid varnum rc;

  /* check required parameters */
  %if %superq(dataset)= or %superq(definition)= %then %do;
    %put ERROR: Required parameters missing. dataset=, definition= are required.;
    %abort cancel;
  %end;


  /* check if output datset name is provided - default to &dataset._cat, if not provided */
  %if %superq(outdata) = %then %do;
    %let outdata=&dataset._cat;
  %end;

        
  /*--------------------------------------------------------------*
   * Parse input dataset name into library and member name        *
   * Assume WORK library if it is not provided                    *
   *--------------------------------------------------------------*/
  %if %index(&dataset,.) %then %do;
      %let lib_in=%upcase(%scan(&dataset,1,.));
      %let mem_in=%upcase(%scan(&dataset,2,.));
  %end;
  %else %do;
      %let lib_in=WORK;
      %let mem_in=%upcase(&dataset);
  %end;

  /*--------------------------------------------------------------*
   * Parse condition dataset name into library and member name    *
   * Assume WORK library if it is not provided                    *
   *--------------------------------------------------------------*/
  %if %index(&definition,.) %then %do;
      %let lib_con=%upcase(%scan(&definition,1,.));
      %let mem_con=%upcase(%scan(&definition,2,.));
  %end;
  %else %do;
      %let lib_con=WORK;
      %let mem_con=%upcase(&definition);
  %end;

  /*--------------------------------------------------------------*
   * If by_vars is provided, check that each BY variable exists  *
   * in input dataset                                            *
   *--------------------------------------------------------------*/
  %if %superq(by_vars) ne %then %do;

      /*----------------------------------------------------------*
       * Count the number of BY variables supplied                *
       *----------------------------------------------------------*/
      %let nby=%sysfunc(countw(%superq(by_vars),%str( )));

      /*----------------------------------------------------------*
       * Loop through each BY variable and validate existence     *
       * in input dataset and condition dataset                   *
       *----------------------------------------------------------*/
      %do i=1 %to &nby;
          %let this_by=%scan(%superq(by_vars),&i,%str( ));

          /*------------------------------------------------------*
           * Open input dataset and check whether current by_vars  *
           * exists                                               *
           *------------------------------------------------------*/
          %let dsid=%sysfunc(open(&dataset,i));
          %if &dsid %then %do;
              %let varnum=%sysfunc(varnum(&dsid,&this_by));
              %let rc=%sysfunc(close(&dsid));
              
              %if &varnum=0 %then %do;
                  %put ERROR: BY variable &this_by does not exist in dataset &dataset..;
                  %return;
              %end;
          %end;
          %else %do;
              %put ERROR: Unable to open dataset &dataset..;
              %return;
          %end;
      %end;
  %end;

  /*------------------------------------------------------------
    If by_vars not provided:
    find common variables and drop them from condition dataset
    this step is needed to ensure the values in input dataset are not overwritten
  --------------------------------------------------------------*/
  
  /* create a new condition dataset name */
  %let _definition=&definition._clean;
 
  %if %superq(by_vars)= %then %do;
	
      proc sql noprint;
          select c.name
            into :drop_common separated by ' '
          from dictionary.columns as i
          inner join dictionary.columns as c
              on i.name = c.name
          where i.libname = "&lib_in"
            and i.memname = "&mem_in"
            and c.libname = "&lib_con"
            and c.memname = "&mem_con";
      quit;

      %if %superq(drop_common) ne %then %do;
          data &_definition;
            set &definition(drop=&drop_common);
          run;
      %end;
      %else %do;
          data &_definition;
              set &definition;
          run;
      %end;

      /* set the new dataset name */
      %let definition=&_definition;
  %end;
  
  /* process based on the by vars */
  %local _has_by _byvar _nvars _nrules;

  %let _has_by = %sysevalf(%superq(by_vars) ne , boolean);
  %if &_has_by %then %let _byvar = &by_vars;


  /*----------------------------------------------*
   * Get variable structure of definition dataset
   *----------------------------------------------*/
  proc contents data=&definition out=_def_meta (keep=name type varnum length) noprint; 
  run;

  proc sort data=_def_meta;
    by varnum;
  run;

  data _def_vars;
    set _def_meta;
    name_up = upcase(name);

    if name_up not in ("CONDITION"
      %if &_has_by %then %do;
        , "%upcase(&_byvar)"
      %end;
    );
  run;

  /* Capture derived variable list */
  proc sql noprint;
    /* get variable names */ 
    select name into :_new_vars separated by ' '
    from _def_vars;

    /* get variable length */ 
    select length into :_new_vars_length separated by ' '
    from _def_vars;

    /* get variable type 1-number, 2-character */ 
    select type into :_new_vars_type separated by ' '
    from _def_vars;

    select count(*) into :_nvars
    from _def_vars;

    select count(*) into :_nrules
    from &definition;
  quit;  

  /*----------------------------------------------*
   * Load definition rows into macro variables
   *----------------------------------------------*/
  data _null_;
    set &definition end=eof;

    call symputx(cats('_cond',_n_), condition);

    %if &_has_by %then %do;
      call symputx(cats('_byval',_n_), &_byvar);
    %end;

    %do i=1 %to &_nvars;
      %let var = %scan(&_new_vars,&i);
      call symputx(cats('_val',_n_,'_',"&var"), &var);
    %end;

    if eof then call symputx('_nrules', _n_);
  run;
  

  /*------------------------------------------------------------------------*
   * Generate DATA steps - Apply condition and process for each new variable
   *------------------------------------------------------------------------*/
  data &outdata;
  
    /* ---- Set LENGTH for character variables ---- */
    %do i=1 %to &_nvars;
      %let var = %scan(&_new_vars,&i);
      %let var_type = %scan(&_new_vars_type,&i);
      %let var_length = %scan(&_new_vars_length,&i);
     
      length &var %if &var_type=2 %then $; &var_length; 	 
    %end;
  
    set &dataset;

    /* Generate rule logic */
    %do r=1 %to &_nrules;

      %if &r=1 %then %do;
        if
      %end;
      %else %do;
        else if
      %end;

      %if &_has_by %then %do;
        (&_byvar = "&&_byval&r" and (&&_cond&r))
      %end;
      %else %do;
        (&&_cond&r)
      %end;
      then do;
		/* Process for each new variable */
        %do i=1 %to &_nvars;
          %let var = %scan(&_new_vars,&i);
          
          %let var_type = %scan(&_new_vars_type,&i);
          %if &var_type=2 %then %do;
            &var = "&&_val&r._&var";
          %end;
          %else %do;
            &var = &&_val&r._&var;
          %end;
        %end;

      end;

    %end;

  run;
 
  /*--------------------------------------------*
   * Cleanup
   *--------------------------------------------*/
  proc datasets lib=work nolist;
      delete _def_meta _def_vars &_definition;
  quit;


%mend derive_vars_cat;
