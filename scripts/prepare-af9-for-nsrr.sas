*******************************************************************************;
* Program           : prepare-af9-for-nsrr.sas
* Project           : National Sleep Research Resource (sleepdata.org)
* Author            : Michael Rueschman (MR)
* Date Created      : 20190401
* Purpose           : Prepare Air Force Nine (AF9) for NSRR deposition.
* Revision History  :
*   Date      Author    Revision
*
*******************************************************************************;

*******************************************************************************;
* set options and libnames ;
*******************************************************************************;
  %let release = 0.1.0.pre;

  %let sourcepath = \\rfawin\bwh-sleepepi-nsrr\data-preparation\af9\source;
  %let releasepath = \\rfawin\bwh-sleepepi-nsrr\data-preparation\af9\releases;

*******************************************************************************;
* pull in source data ;
*******************************************************************************;
  proc import datafile="&sourcepath\AFOSR9_demographics_subjectinfo_20190319.csv"
    out=af9demo_in
    dbms=csv
    replace;
  run;

  proc sort data=af9demo_in;
    by subject_code;
  run;

*******************************************************************************;
* prepare dataset ;
*******************************************************************************;
  data af9demo;
    length nsrrid visit 8.;
    set af9demo_in;

    nsrrid = 2400000 + _n_;
    visit = 1;

    *create sexn variable;
    if sex = 'f' then sexn = 2;
    else if sex = 'm' then sexn = 1;

    *create ethnicity variable;
    if ethnic_category = 'not_hispanic_or_latino' then ethnicity = 0;
    else if ethnic_category = 'hispanic_or_latino' then ethnicity = 1;

    *create race3 variable;
    if race = 'white' then race3 = 1;
    else if race = 'black_or_african_american' then race3 = 2;
    else if race = 'other' then race3 = 3;

    keep 
      nsrrid
      visit
      study_year
      age
      sexn
      ethnicity
      race3
      height
      weight
      owl_lark_score
      ;
  run;

*******************************************************************************;
* make all variable names lowercase ;
*******************************************************************************;
  options mprint;
  %macro lowcase(dsn);
       %let dsid=%sysfunc(open(&dsn));
       %let num=%sysfunc(attrn(&dsid,nvars));
       %put &num;
       data &dsn;
             set &dsn(rename=(
          %do i = 1 %to &num;
          %let var&i=%sysfunc(varname(&dsid,&i));    /*function of varname returns the name of a SAS data set variable*/
          &&var&i=%sysfunc(lowcase(&&var&i))         /*rename all variables*/
          %end;));
          %let close=%sysfunc(close(&dsid));
    run;
  %mend lowcase;

  %lowcase(af9demo);

*******************************************************************************;
* export csv dataset for release ;
*******************************************************************************;
  proc export data=af9demo
    outfile="&releasepath\af9-dataset-&release..csv"
    dbms=csv
    replace;
  run;
