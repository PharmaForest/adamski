# Adamski (Latest version 0.0.2 on 15Oct2025)
Adamski is a SAS package inspired by the R package {admiral}. It aims to bring the same flexible and modular ADaM derivation framework to the SAS environment. The package follows the {admiral} design principles while adapting to SAS syntax and workflows. It enables consistent, reproducible ADaM dataset creation in compliance with CDISC standards.  
Adamski serves as a bridge between open-source R implementations and traditional SAS programming.  

![adamski](./adamski_logo_small.png)  

Please see more detailed concepts and construction map in [Adamski and Admiral](./Adamski_and_Admiral.md).

---

## %derive_vars_dy() 

### Purpose:
   Generates study day (`DY`) variables from given date variables using a specified reference date(e.g., `TRTSDT`). 
   
### Parameters:
~~~sas
 reference_date   = Reference date variable (e.g. TRTSDT) used as Day 1  
 source_vars      = Space-separated list of source date variables(--DT) for which DY variables will be derived.
~~~

### Example usage: 
~~~sas
data ADAE;
  merge SDTM.AE ADSL;
  by USUBJID;
  %derive_vars_dy(
       reference_date = TRTSDT,  
       source_vars    = AESTDT AEENDT  
   );
run;
~~~

 Author:             Ryo Nakaya  
 Latest update Date: 2025-10-14  

## %derive_var_merged_exist_flag()  

### Purpose:  
    Creates a character flag variable indicating whether the current DATA step row's key(s) exist in another dataset.   

### Parameters:
~~~sas
 - `dataset_add` (required) : Dataset to check for existence (e.g., `SDTM.AE`).
 - `by_vars`     (required) : Space-separated list of key variables used for the lookup.
 - `new_var`     (required) : Name of the output flag variable to create (character).
 - `condition`   (optional) : WHERE clause (as text) applied to `dataset_add` before building  the hash (e.g., `%nrbquote(SEX="F")`). If omitted, all rows are used.
 - `true_value`  (optional) : Value assigned to `new_var` when a match is found.
                              Default: `Y`.
 - `false_value` (optional) : Value assigned to `new_var` when no match is found.
                              Default: (blank).
~~~
### Sample code

~~~sas
data have;
  do SEX="F","M"; do AGE=12 to 17; output; end; end;
run;

data want;
  set have;
  *Single key;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE,
    new_var     = AGE_IN_CLASS,
    true_value  = Y,
    false_value = N
  );

  * Multiple keys;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE SEX,
    new_var     = AGE_SEX_IN_CLASS
  );

  * With condition ;
  %derive_var_merged_exist_flag(
    dataset_add = SASHELP.CLASS,
    by_vars     = AGE,
    condition   = %nrbquote(SEX="F"),
    new_var     = AGE_IN_CLASS_F_ONLY,
    true_value  = Yes,
    false_value = No
  );
run;
~~~

### Note:

- Parameter `dataset` in {admiral} is not defined taking into account how the macro in SAS is used.  

- Parameter `filter_add' is omitted because SAS's mechanism makes it difficult to differentiate it from the condition parameter. Records filtered by condition are the subject of evaluation.

- Parameter  `missing_value` parameter has not been implemented at this time, as there are currently few practical use cases that come to mind.

### URL:

https://github.com/PharmaForest/adamski

Author:                 Yutaka Morioka
Latest update Date:     2025-10-15
---
 
## Version history  
0.0.2(15October2025)	: Add %derive_var_merged_exist_flag()
0.0.1(14October2025)	: Initial version

## What is SAS Packages?

The package is built on top of **SAS Packages Framework(SPF)** developed by Bartosz Jablonski.

For more information about the framework, see [SAS Packages Framework](https://github.com/yabwon/SAS_PACKAGES).

You can also find more SAS Packages (SASPacs) in the [SAS Packages Archive(SASPAC)](https://github.com/SASPAC).

## How to use SAS Packages? (quick start)

### 1. Set-up SAS Packages Framework

First, create a directory for your packages and assign a `packages` fileref to it.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
filename packages "\path\to\your\packages";
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Secondly, enable the SAS Packages Framework.
(If you don't have SAS Packages Framework installed, follow the instruction in 
[SPF documentation](https://github.com/yabwon/SAS_PACKAGES/tree/main/SPF/Documentation) 
to install SAS Packages Framework.)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%include packages(SPFinit.sas)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### 2. Install SAS package

Install SAS package you want to use with the SPF's `%installPackage()` macro.

- For packages located in **SAS Packages Archive(SASPAC)** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located in **PharmaForest** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, mirror=PharmaForest)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located at some network location run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, sourcePath=https://some/internet/location/for/packages)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  (e.g. `%installPackage(ABC, sourcePath=https://github.com/SomeRepo/ABC/raw/main/)`)


### 3. Load SAS package

Load SAS package you want to use with the SPF's `%loadPackage()` macro.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%loadPackage(packageName)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### Enjoy!

---

