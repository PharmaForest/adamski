/*--------------------------------------------------------------
  Original Reporting Effort   : adam_sdtm_workflow_template.final_20260608_1.Rmd
  Program Name                : derive_vars_query.sas
  SAS Version                 : 9.4
  Purpose (short description) : Derive SMQ/CQ AE of Special Interest (SMQ/CQ) query variables 
                                from a metadata excel spreadsheet similar to that used for the
                                pharmaverse Admiral derive_vars_querey() function 
  Author                      : Cursor Grok 4.5 modified by P. Robertson to fit Adamski Repository
  Date                        : 10AUG2026
  Input Datasets or Metadata  : ADAE-like dataset + queries CSV/dataset with AESI metadata
                               
  Modification Log            : 
 
  --- Notes ---
  Pharmaverse Admiral has no derive_var_aesi. AESI are study-defined queries applied via
  derive_vars_query() / create_query_data(). This macro ports that pattern.

  This macro creates flags and related vars for:
       SMQ = Standardised MedDRA Queries
        CQ = Customized Queries (Sponsor defined)
       
  These variables are not defined in CDISC but are generally included by Sponsors in the ADAE dataset.
  They can sometimes be called "AESI" (AE of Special Interest) but that term can also refer to other AE, 
  such "CRS" and "ICANS" (Cytokine Release Syndrom and Immune Effector Cell-Associated Neurotoxicity Syndrome)
  that are often seen in hematology trials. Again, SMQ01/CQ01 variables often support AESI analyses, but SMQs 
  and CQs, alone, are not synonymous with "AESI"s.

  SMQ and CQ metadata is read from CSV files and applied to the AE data through a table-lookup approach.
  The metadata can include variables such as the following example (from bladder CA context); the example
  columns are derived from the Admiral vignette queries_dataset.

    PREFIX      SMQ02
    GRPNAME     Acute renal failure (AESI)
    GRPID       20000003
    SCOPE       NARROW
    SRCVAR      AEDECOD
    TERMCHAR    Blood creatinine increased
    
    Additional SMQ02 metadata records would also exist for ADECDOD of "Renal Failure" "Renal Impairment" 
    "Acute Kidney "Injury" and "Blood Urine Present".

    ADAE datasets may include some or all of these vars. Most commonly included are:

    SMQ01FL  = AE belongs to SMQ01
    SMQ01SC  = Narrow or Broad
    SMQ01NAM = Name of the SMQ

    External sources (define.xml or AD Reviewer's guide might include the SMQ and CQ details
   
  Matching is case-insensitive on TERMCHAR vs the named SRCVAR on analysis data.
  Demo SRCVAR values supported: AEDECOD, AETERM.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


/*******************************************************************************
  %load_query_data — import queries CSV
*******************************************************************************/
%macro load_query_CSV_data(
                          queries_csv =
                                , out = work.aesi_queries
                      );
  %local qcsv;
  %let qcsv = &queries_csv;
  %if %sysfunc(fileexist(&qcsv)) = 0 %then %do;
      %put ERROR: load_query_data - file not found: &qcsv;
      %return;
  %end;

  proc import datafile     = "&qcsv"
              out          = work._aesi_q_imp
              dbms         = csv replace;
              guessingrows = max;
              getnames     = yes;
  run;

  * LENGTH before SET. Rename import vars so PDV lengths are not already set *;
  * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *;
  data &out;
       length PREFIX   $8 
              GRPNAME  $200 
              SRCVAR   $32 
              TERMCHAR $200 
              SCOPE    $20 
              COMMENT  $200
              GRPID    8 
              SCOPEN   8 
              TERMNUM  8;
       set work._aesi_q_imp (rename=(
                                      PREFIX   = __PREFIX 
                                      GRPNAME  = __GRPNAME 
                                      SRCVAR   = __SRCVAR
                                      TERMCHAR = __TERMCHAR 
                                      SCOPE    = __SCOPE 
                                      COMMENT  = __COMMENT
                                      GRPID    = __GRPID 
                                      SCOPEN   = __SCOPEN 
                                      TERMNUM  = __TERMNUM
                                    ));
       PREFIX   = upcase(strip(__PREFIX));
       GRPNAME  = strip(__GRPNAME);
       SRCVAR   = upcase(strip(__SRCVAR));
       TERMCHAR = strip(__TERMCHAR);
       SCOPE    = strip(__SCOPE);
       COMMENT  = strip(__COMMENT);

       * Force numeric ids - PROC IMPORT may guess character *;
       * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *;
       GRPID   = input(cats(__GRPID), ?? best32.);
       SCOPEN  = input(cats(__SCOPEN), ?? best32.);
       TERMNUM = input(cats(__TERMNUM), ?? best32.);
       drop __PREFIX  __GRPNAME __SRCVAR __TERMCHAR __SCOPE
            __COMMENT __GRPID   __SCOPEN __TERMNUM;
  run;

  proc datasets lib=work nolist;
       delete _aesi_q_imp;
  quit;

  %put NOTE: load_query_CSV_data -> &out;

%mend load_query_CSV_data;

* Create a SAS dataset with the SMQ/CQ Query Metadata from the CSV file.*;
* This should be study or compound specific                             *;  
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *; 
%load_query_CSV_data(
            queries_csv = /home/u64416277/Adamski/SAS/metadata/aesi_queries_dementia.csv
                  , out = work.aesi_queries
                      );


*proc print data=work.aesi_queries;
*run;

/*******************************************************************************
  %derive_vars_query — substantial port of admiral::derive_vars_query()
*******************************************************************************/
%macro derive_vars_query(
                             dataset =
                   , dataset_queries = work.aesi_queries
                   ,             out =
                   ,   aesi_flag_var = AESIFL
                        );

  %local npref 
         i 
         pref 
         pfx
         nam_var 
         cd_var 
         sc_var 
         scn_var 
         has_cd 
         has_sc 
         has_scn;

  %if %length(&dataset)         = 0 or 
      %length(&dataset_queries) = 0 or 
      %length(&out)             = 0 %then %do;
      %put ERROR: m_derive_vars_query requires DATASET, DATASET_QUERIES, and OUT.;
      %return;
  %end;
  %if %sysfunc(exist(&dataset_queries)) = 0 %then %do;
      %put ERROR: m_derive_vars_query - queries dataset &dataset_queries not found.;
      %return;
  %end;

  proc sql noprint;
       create table work._q_pref as
       select distinct PREFIX
       from &dataset_queries
       where not missing(PREFIX)
       order by PREFIX
       ;
       select count(*) into :npref trimmed 
       from work._q_pref;
  quit;

  %if &npref = 0 %then %do;
      %put WARNING: m_derive_vars_query - no PREFIX values in queries dataset.;
      data &out;
           set &dataset;
      run;
      %return;
  %end;

  data work._q_out;
       set &dataset;
       _rowid = _n_;
       %if %length(&aesi_flag_var) %then %do;
           length &aesi_flag_var $1;
           &aesi_flag_var = '';
       %end;
  run;

  %do i = 1 %to &npref;
    data _null_;
         set work._q_pref (firstobs=&i obs=&i);
         call symputx('pref', strip(PREFIX), 'l');
    run;

    %let pfx = %superq(pref);
    %let nam_var = &pfx.NAM;
    %let cd_var  = &pfx.CD;
    %let sc_var  = &pfx.SC;
    %let scn_var = &pfx.SCN;

    proc sql noprint;
         select max(case when not missing(GRPID) then 1 else 0 end)
              , max(case when not missing(SCOPE) and strip(SCOPE) ^= '' then 1 else 0 end)
              , max(case when not missing(SCOPEN) then 1 else 0 end)
         into :has_cd trimmed, 
              :has_sc trimmed, 
              :has_scn trimmed
         from &dataset_queries
         where PREFIX = "&pref"
         ;
    quit;

    data work._q_terms;
         set &dataset_queries;
         where PREFIX = "&pref";
         length TERM_U $200;
         if not missing(TERMCHAR) and 
            strip(TERMCHAR) ^= '' then TERM_U = upcase(strip(TERMCHAR));
         else call missing(TERM_U);
         if missing(TERM_U) then delete;
    run;

    data work._q_hit;
         length GRPNAME $200 
                SCOPE   $20 
                SRCVAR  $32 
                TERM_U  $200;
         if _n_ = 1 then do;
            declare hash h(dataset: 'work._q_terms', multidata: 'y');
            h.defineKey('SRCVAR', 'TERM_U');
            h.defineData('GRPNAME', 'GRPID', 'SCOPE', 'SCOPEN');
            h.defineDone();
         end;
         set work._q_out (keep=_rowid AEDECOD AETERM);
         call missing(GRPNAME, GRPID, SCOPE, SCOPEN);
         _hit = 0;

         SRCVAR = 'AEDECOD';
         TERM_U = upcase(strip(AEDECOD));
         if not missing(TERM_U) then do;
              rc = h.find();
              if rc = 0 then _hit = 1;
         end;

         if not _hit then do;
              SRCVAR = 'AETERM';
              TERM_U = upcase(strip(AETERM));
              if not missing(TERM_U) then do;
                 rc = h.find();
                 if rc = 0 then _hit = 1;
              end;
         end;

         if _hit then output;
         keep _rowid GRPNAME GRPID SCOPE SCOPEN;
    run;

    proc sort data=work._q_hit;
         by _rowid;
    run;


    data work._q_out;
         merge work._q_out (in=a)
               work._q_hit (in=b rename=(GRPNAME=_QN 
                                           GRPID=_QCD 
                                           SCOPE=_QSC 
                                          SCOPEN=_QSCN));
         by _rowid;
         length tmpnam $200 tmpsc $20 tmpcd 8 tmpscn 8;
         if a;
         if b then do;
              tmpnam = _QN;
              tmpcd  = _QCD;
              tmpsc  = _QSC;
              tmpscn = _QSCN;
              %if %length(&aesi_flag_var) %then %do;
                  &aesi_flag_var = 'Y';
              %end;
         end;
         else call missing(tmpnam, tmpcd, tmpsc, tmpscn);
         drop _QN _QCD _QSC _QSCN;
    run;

    filename _qcode "%sysfunc(pathname(work))/_qcode.sas";
    data _null_;
         file _qcode;
         put "data work._q_out;";
         put "     set work._q_out;";
         put "     %unquote(%trim(%left(&nam_var))) = tmpnam;";
         %if &has_cd = 1 %then %do;
             put "     %unquote(%trim(%left(&cd_var))) = tmpcd;";
         %end;
         %if &has_sc = 1 %then %do;
             put "     %unquote(%trim(%left(&sc_var))) = tmpsc;";
         %end;
         %if &has_scn = 1 %then %do;
             put "     %unquote(%trim(%left(&scn_var))) = tmpscn;";
         %end;
         put "     drop tmpnam tmpcd tmpsc tmpscn;";
         put "run;";
    run;
    %include _qcode / source2;
    filename _qcode clear;
  %end;

  data &out;
       set work._q_out;
       drop _rowid;
  run;

  proc datasets lib=work nolist;
       delete _q_pref
              _q_out 
              _q_hit
              _q_terms;
  quit;

  %put NOTE: derive_vars_query complete -> &out;

%mend derive_vars_query;


%derive_vars_query(
        dataset = "/home/u64416277/SAS_mirrored_Admiral_safety_ADaM/SAS/adam/adae.sas7bdat",
dataset_queries = work.aesi_queries,
            out = "/home/u64416277/Adamski/SAS/adam/adae2.sas7bdat",
  aesi_flag_var = AESIFL
                  );


