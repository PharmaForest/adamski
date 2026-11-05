/*--------------------------------------------------------------
  Original Reporting Effort   : pharmaverse-admiral-sas-macros
  Program Name                : gs_step1_write.sas
  SAS Version                 : 9.4
  Purpose (short description) : Write one dataset to the output folder
  Author                      : Cursor
  Date                        : 04NOV2026
  Input Datasets or Metadata  : None
  Modification Log            :

  Run this by itself. It does not call a derivation macro.
  A successful run creates &PFDIR/output/gs_step1.sas7bdat
  and &PFDIR/output/gs_step1.txt.
  The log line is NOTE: [STEP1] exists=1.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


%if %symexist(PFDIR) = 0 %then %do;
    %let PFDIR = %sysfunc(strip(%sysget(HOME)))/Adamski/SAS;
%end;

%if %sysfunc(fileexist(&PFDIR/output)) = 0 %then %do;
    %let _gs_dir = %sysfunc(dcreate(output, &PFDIR/));
%end;

options errorcheck=normal nosyntaxcheck obs=max replace notes;

libname gsout "&PFDIR/output";

data gsout.gs_step1;
     length note $40;
     note = "write check";
     output;
run;

%put NOTE: [STEP1] &PFDIR/output/gs_step1.sas7bdat exists=%sysfunc(exist(gsout.gs_step1));

libname gsout clear;

data _null_;
     file "&PFDIR/output/gs_step1.txt";
     put "step1 write check";
run;

%put NOTE: [STEP1] &PFDIR/output/gs_step1.txt exists=%sysfunc(fileexist(&PFDIR/output/gs_step1.txt));
