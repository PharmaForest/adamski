Type : Package
Package : Adamski
Title : Adamski -- A SAS package of toolkit for CDISC ADaM creation
Version : 0.0.5
Author : [Yutaka Morioka],[Hiroki Yamanobe],[Ryo Nakaya],[Sharad Shhetri]
Maintainer : [Yutaka Morioka],[Hiroki Yamanobe],[Ryo Nakaya],[Sharad Shhetri]
License : Apache license 2.0
Encoding : UTF8
Required : "Base SAS Software"
ReqPackages :  

DESCRIPTION START:

##  Adamski

**A SAS package of toolkit for CDISC ADaM creation**
Let's build the spaceship [adamski] together!
PharmaForest is looking for collaborators and contributors to join us on this exciting journey. If you're passionate
about ADaM programming or want to help shape tools for the clinical data community, we'd love to have you onboard! ?
Inspired by the {admiral} package in R, Adamski aims to bring similar functionality to the SAS environment, while introducing original functions and macros.
We strive to maintain consistency by keeping function (macro) and option names as close as possible to their R counterparts.
However, some differences are inevitable due to the distinct nature of SAS and R.
In addition, new functions and macros would be developed to extend the capabilities.
**Please see notice.sas in additional contents(addcnt) in addition to license.sas**

### Main Features
- %derive_vars_dy() : Calculates DY variables
- %derive_var_merged_exist_flag() :  Creates a character flag variable indicating whether the current DATA step row's key(s) exist in another dataset. 
- %derive_var_age_years() : Creates age variable with unit of year  
- %derive_vars_duration() : Derives duration between two dates, specified by the variables present in the input dataset (e.g., duration of adverse events, relative day, age, etc.)  
- %derive_locf_records() : Add LOCF records (Last Observation Carried Forward) to a dataset based on an "expected observations" reference dataset  

### Usage
For more details, please visit https://github.com/PharmaForest/adamski]
---
DESCRIPTION END:
