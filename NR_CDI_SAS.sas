/*  importing data  */
PROC IMPORT OUT=cdiff
            DATAFILE= "C:\Users\nr644\Desktop\CDI\CDI_retro_final.csv" DBMS=csv replace;
     GETNAMES=yes;
RUN;
data cdi ;
set cdiff;
array _a $ _character_;
do over _a;
  if _a="NA" then call missing(_a);
end;
run;
proc print data=cdi (obs=5);
run;
proc contents data=cdi;
run;
/*  recategorizing variables  */
data cdi_2;
set cdi;
currentant_1=0;   
if v1_currentabx_abx1 in ("NA"," ") then currentant_1=0;
else currentant_1=1;
currentant_2=0;   
if v1_currentabx_abx2 in ("NA"," ") then currentant_2=0;
else currentant_2=1;
currentant_3=0;   
if v1_currentabx_abx3 in ("NA"," ") then currentant_3=0;
else currentant_3=1;
currentant_4=0;   
if v1_currentabx_abx4 in ("NA"," ") then currentant_4=0;
else currentant_4=1;
currentant= currentant_1 + currentant_2 + currentant_3 + currentant_4;
/* current antibiotics:  0-4  */
priorant_1=0;   
if v1_priorabx_abx1 in ("NA"," ") then priorant_1=0;
else priorant_1=1;
priorant_2=0;   
if v1_priorabx_abx2 in ("NA"," ") then priorant_2=0;
else priorant_2=1;
priorant_3=0;   
if v1_priorabx_abx3 in ("NA"," ") then priorant_3=0;
else priorant_3=1;
priorant_4=0;   
if v1_priorabx_abx4 in ("NA"," ") then priorant_4=0;
else priorant_4=1;
priorant= priorant_1 + priorant_2 + priorant_3 + priorant_4;
/* prior antibiotics:  0-4  */
if v1_chem_score_2= 1 then severity=0;
if v1_chem_score_2 in (2 3) then severity=1;
/* severity:  0= mild-moderate,  1= moderate-severe (w/ complicated), 0= missing  */
surgery= sum(v1_hosp1_surgery, v1_hosp2_surgery, v1_hosp3_surgery);
/* surgery:  # of prior surgeries (past 6 months/3 max) */
if v1_demog_race= 1 then race= 1;
if v1_demog_race= 2 then race= 2;
if v1_demog_race= 3 then race= 3;
if v1_demog_race= 4 then race= 3;
if v1_demog_race= 5 then race= .;
/* Race: 1=caucasian, 2=african american, 3= Non-caucasian/african american, .= missing */
if v1_study_enroll= 2 then cdiff=0;
if v1_study_enroll= 1 then cdiff=1;
/*  cdiff 0=control, 1=case */
if v1_course_referral= 1 then HC_referral=0;
if v1_course_referral= 2 then HC_referral=1;
if v1_course_referral= 3 then HC_referral=1;
if v1_course_referral= 4 then HC_referral=1;
if v1_course_referral= 5 then HC_referral=0;
/*  HC_referral=0, not referred by HCF;
HC_referral=1, referred by HCF*/
if v1_epi_insurance in (6 7 8 9 10) then insurance= 1;
if v1_epi_insurance in (1 2 3 4 5) then insurance= 2;
/*  insurance=1, private insurance type;
insurance=2, non-private insurance type*/
gastro= v1_comorbid_gi___1;
reinfection= v1_conseq_cdi_recur;
if v1_chem_creatinine =< 0 then v1_chem_creatinine= .;
log_creatinine= log(v1_chem_creatinine);
run;
/*  formatting responses  */
proc format;
Value v1_demog_gender
	1= "Male"
	2= "Female";
Value race
	1= "Caucasian"
	2= "African American"
	3= "Non-caucasian/african american"
	.= "Missing";
Value v1_course_icu
	0="No"
	1="Yes"
	.="Missing";
Value v1_currentabx_proton
	0="No"
	1="Yes"
	.="Missing";
Value v1_currentabx_steroid
	0="No"
	1="Yes"
	.="Missing";
Value v1_currentabx_chemo
	0="No"
	1="Yes"
	.="Missing";
Value v1_currentabx_radio
	0="No"
	1="Yes"
	.="Missing";
Value v1_priorabx_proton
	0="No"
	1="Yes"
	.="Missing";
Value v1_priorabx_steroid
	0="No"
	1="Yes"
	.="Missing";
Value v1_priorabx_chemo
	0="No"
	1="Yes"
	.="Missing";
Value v1_priorabx_radio
	0="No"
	1="Yes"
	.="Missing";
Value insurance
	1="Private"
	2="Non-private"
	0="Missing";
Value HC_referral
	0="Non-healthcare"
	1="Healthcare"
	.="Missing";
Value severity
	0="Mild-moderate" 
	1="Moderate-severe"
	.="Missing";
Value v1_comorbid_transplant 
	0="No"
	1="Yes"
	.="Missing";
Value cdiff
	0="Control"
	1="Case"
	.="Missing";
Value v1_conseq_cdi_recur
	0="No"
	1="Yes"
	.="Missing";
Value gastro
	0= "No"
	1= "Yes"
	.="Missing";
Value reinfection
	0= "No"
	1= "Yes"
	.= "Missing";
run;
proc contents data=cdi_2;
run;
/* ALREADY EXPORTED- Set the file path and name for the CSV file
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_infection.csv';
 Export the dataset to CSV 
proc export data=cdi_2
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_infection.csv"
    dbms=csv replace;
    run;*/
/*Exploratory analysis for cont. var*/
proc univariate data=cdi_2;
var v1_demog_bmi v1_demog_age v1_course_los v1_chem_creatinine v1_chem_wbc v1_cci_total log_creatinine;
histogram;
run;
/*comparing distribution for log creatinine and creatinine*/
proc univariate data=cdi_2;
var v1_chem_creatinine log_creatinine;
histogram;
run;
/* all continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous all";
proc means data=cdi_2 mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run; title "continuous all";
/* controls continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous controls";
proc means data=cdi_2 mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE v1_study_enroll= 2;
run; title "continuous controls";
/* cases continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous cases";
proc means data=cdi_2 mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE v1_study_enroll= 1;
run;title "continuous cases";
/*  all categorical  */
title "categorical all";
proc freq data=cdi_2; 
table cdiff v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing;
run;title "categorical all"
/*  controls categorical  */
title "categorical controls";
proc freq data=cdi_2; 
table cdiff v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
WHERE cdiff= 0;
run;title "categorical controls";
/*  cases categorical  */
title "categorical cases";
proc freq data=cdi_2; 
table cdiff v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
WHERE cdiff= 1;
run;title "categorical cases";
/*  calculating p-values for aim 1: CDI  */
/* Used t-test for continuous variables of normal distribution*/
proc ttest data=cdi_2 sides=2 alpha=0.05 h0=0;
var  v1_demog_age v1_demog_bmi;
class cdiff;
run;
/* Wilcoxon two sample test for continuous variables of non-normal distribution */
proc npar1way data=cdi_2 wilcoxon;
class cdiff;
var v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run;
/* chi-square test for categorical variables */
proc freq data=cdi_2; 
table cdiff v1_demog_gender  * cdiff race * cdiff v1_course_icu *  cdiff currentant 
* cdiff v1_currentabx_proton * cdiff v1_currentabx_steroid 
* cdiff  v1_currentabx_chemo * cdiff v1_currentabx_radio * cdiff priorant* cdiff v1_priorabx_proton 
* cdiff v1_priorabx_steroid * cdiff v1_priorabx_chemo * cdiff v1_priorabx_radio * cdiff insurance * cdiff surgery 
* cdiff HC_referral * cdiff v1_comorbid_transplant * cdiff gastro * cdiff quantile75 * cdiff quantile90 *cdiff / norow missing nocum chisq; 
Run;
/* Aim 1: CDI logistic model using backwards selection */
proc logistic descending data=CDI_2;
class cdiff (Ref= first) v1_demog_gender (Ref= first)  race (Ref= first)  v1_course_icu (Ref= first) currentant (Ref= first) 
v1_currentabx_proton (Ref= first) v1_currentabx_steroid (Ref= first)  v1_currentabx_chemo (Ref= first) 
v1_currentabx_radio (Ref= first) priorant (Ref= first) v1_priorabx_proton (Ref= first) v1_priorabx_steroid (Ref= first) 
v1_priorabx_chemo (Ref= first) v1_priorabx_radio  (Ref= first) insurance  (Ref= first) surgery (Ref= first) 
HC_referral (Ref= first) v1_comorbid_transplant (Ref= first) gastro (Ref= first) / param= ref;
model cdiff= v1_demog_age v1_demog_gender race v1_demog_bmi v1_course_los v1_course_icu currentant 
v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio priorant v1_priorabx_proton 
v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio v1_chem_wbc v1_chem_creatinine insurance surgery HC_referral
v1_cci_total v1_comorbid_transplant gastro
/ selection= backward
	slstay= 0.2 
	details
	lackfit 
	;
run;
/* According to backward selection, we should include LOS, ICU stay, current and prior antibiotic use, current and 
prior steroid use, insurance type and referral type, also included Age per Neals suggestion*/
proc logistic data=CDI_2 descending;
class v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance  (Ref= first) HC_referral (Ref= first);
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant priorant v1_currentabx_steroid v1_priorabx_steroid
insurance HC_referral;
run;
/*INFECTION VALIDATION SECTION**************randomizing the dataset*/
data analytic / view=analytic;
set cdi_2;
seed=1347;
s= rand('uniform');
run;
/**************sorting by the random variable and them removing it*/
proc sort data=analytic out=chunkable2 (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*creating test datasets in SAS into 5 even-ish sets;*/
Data Test1a;
set chunkable2 (firstobs = 1 obs = 135);  /* each set 1/5 of total */
run;
Data Test2a;
set chunkable2 (firstobs = 136 obs = 271);
run;
Data Test3a;
set chunkable2 (firstobs = 272 obs = 407);
run;
Data Test4a;
set chunkable2 (firstobs = 408 obs = 543);
run;
Data Test5a;
set chunkable2 (firstobs = 544 obs = 682);
run;
/*creating the 5 training sets*/
data Training1a;
set Test2a Test3a Test4a Test5a;
run;
data Training2a;
set Test1a Test3a Test4a Test5a;
run;
data Training3a;
set Test2a Test1a Test4a Test5a;
run;
data Training4a;
set Test2a Test3a Test1a Test5a;
run;
data Training5a;
set Test2a Test3a Test4a Test1a;
run;
proc logistic data=CDI_2;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first)/ param= ref;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=FULLROC ;
roc; roccontrast;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first)/ param= ref;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC ;
score data= Test1a out=testpred1 outroc=TestROC1 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1;
model cdiff=;
roc pred=P_case; /* new pred var*/
where P_case ~=.;
roccontrast;
run;
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC2;
score data= Test2a out=testpred2 outroc=TestROC2 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred2;
model cdiff=;
roc pred=P_case; /* new pred var*/
where P_case ~=.;
roccontrast;
run; /*p < 0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC3;
score data= Test3a out=testpred3 outroc=TestROC3 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred3;
model cdiff=;
roc pred=P_case; /* new pred var*/
where P_case ~=.;
roccontrast;
run; /*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC4;
score data= Test4a out=testpred4 outroc=TestROC4 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred4;
model cdiff=;
roc pred=P_case; /* new pred var*/
where P_case ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC5;
score data= Test5a out=testpred5 outroc=TestROC5 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred5;
model cdiff=;
roc pred=P_case; /* new pred var*/
where P_case ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_;  
        datalines;
        train 0 0 
        ;
proc logistic data=cdi_2;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=cdiffmodel;
score data= cdi_2 out=pred1 fitstat;
roc; roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_infection.probs.csv';
 /*Export the dataset to CSV
proc export data=pred1
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_infection.probs.csv"
    dbms=csv replace;
    run;*/
data Plotdata;
set zero cdiffmodel; 
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0 
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1(in=CV) TestROC2(in=CV2) TestROC3(in=CV3) TestROC4(in=CV4) TestROC5(in=CV5) 
cdiffmodel(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.82" "CV1 AUC" = "0.84" "CV2 AUC"="0.76" "CV3 AUC"="0.79" "CV4 AUC"="0.81"
		"CV5 AUC"="0.72") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*infection confusion matrix*/
data confusion2;
set pred1;    
if F_cdiff=0 and I_cdiff=0 then final="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then final="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then final="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then final="FN"; /*false negative*/
run;
proc freq data=confusion2;
table final;
run;
data confusion1a;
set testpred1; 
if F_cdiff=0 and I_cdiff=0 then test1="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test1="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test1="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test1="FN"; /*false negative*/
run;
proc freq data=confusion1a;
table test1;
run;
data confusion2a;
set testpred2;
if F_cdiff=0 and I_cdiff=0 then test2="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test2="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test2="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test2="FN"; /*false negative*/
run;
proc freq data=confusion2a;
table test2;
run;
data confusion3a;
set testpred3;
if F_cdiff=0 and I_cdiff=0 then test3="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test3="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test3="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test3="FN"; /*false negative*/
run;
proc freq data=confusion3a;
table test3;
run;
data confusion4a;
set testpred4;
if F_cdiff=0 and I_cdiff=0 then test4="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test4="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test4="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test4="FN"; /*false negative*/
run;
proc freq data=confusion4a;
table test4;
run;
data confusion5a;
set testpred5;
if F_cdiff=0 and I_cdiff=0 then test5="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test5="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test5="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test5="FN"; /*false negative*/
run;
proc freq data=confusion5a;
table test5;
run;
/*infection aim weighted-IPW, validation, confusion matrices*/
/*IPW for 75th quantile*/
proc logistic data= cdi_2 descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile75= SDI_score v1_demog_age race insurance;
	output out=est_75prob p=p_75quant; *this is outputing estimated probabilities for being in the 75th percentile;
run;
/*prop of ppl falling within 75% catchment=74.93% or 0.7493*/
proc freq data=cdi_2; 
table quantile75;
run;
/*putting this 0.7493 in numerator instead of 1 to stablizie- is this right?*/
data cdi2_wt;
	set est_75prob;
	if quantile75=1 then w= 0.7493/p_75quant;
	else if quantile75=0 then w= 0.7493/(1-p_75quant);
run;
/* before stabilizing-weight range 1.02 to 38.89 with a mean of 1.90, after stabilizing-weight range 0.76 to 29.15 */
proc univariate data=cdi2_wt;
	id study_redcap_id;
	var w;
run;
/* redoing model using the weight statement add statement: weight w;*/ 
proc logistic data=cdi2_wt descending;
class v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance  (Ref= first) HC_referral (Ref= first);
weight w;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant priorant v1_currentabx_steroid v1_priorabx_steroid
insurance HC_referral;
run;
/* VALIDATION SECTION WITH WEIGHTS- 75th percentile
/**************randomizing the dataset*/
data analytic / view=analytic;
set cdi2_wt;
seed=1347;
s= rand('uniform');
run;
/**************sorting by the random variable and them removing it*/
proc sort data=analytic out=chunkable2 (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*creating test datasets in SAS into 5 even-ish sets;*/
Data Test1a;
set chunkable2 (firstobs = 1 obs = 135);  /* each set 1/5 of total */
run;
Data Test2a;
set chunkable2 (firstobs = 136 obs = 271);
run;
Data Test3a;
set chunkable2 (firstobs = 272 obs = 407);
run;
Data Test4a;
set chunkable2 (firstobs = 408 obs = 543);
run;
Data Test5a;
set chunkable2 (firstobs = 544 obs = 682);
run;
/*creating the 5 training sets*/
data Training1a;
set Test2a Test3a Test4a Test5a;
run;
data Training2a;
set Test1a Test3a Test4a Test5a;
run;
data Training3a;
set Test2a Test1a Test4a Test5a;
run;
data Training4a;
set Test2a Test3a Test1a Test5a;
run;
data Training5a;
set Test2a Test3a Test4a Test1a;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first)/ param= ref;
weight w;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC ;
score data= Test1a out=testpred1_75 outroc=TestROC1 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC2;
score data= Test2a out=testpred2_75 outroc=TestROC2 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred2_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p < 0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC3;
score data= Test3a out=testpred3_75 outroc=TestROC3 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred3_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1~=.;
roccontrast;
run; /*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC4;
score data= Test4a out=testpred4_75 outroc=TestROC4 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred4_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC5;
score data= Test5a out=testpred5_75 outroc=TestROC5 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred5_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_;  
        datalines;
        train 0 0 
        ;
/*increased a little bit after stabilizing- went from 0.8064 to 0.8098*/
proc logistic data=cdi2_wt descending;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=cdiffmodel;
score data= cdi2_wt out=pred1_75 fitstat;
roc; roccontrast;
run;
proc logistic data=pred1_75 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_infection.75probs.csv';
Export the dataset to CSV 
proc export data=pred1_75
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_infection.75probs.csv"
    dbms=csv replace;
    run;*/
data Plotdata;
set zero cdiffmodel; 
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0 
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1(in=CV) TestROC2(in=CV2) TestROC3(in=CV3) TestROC4(in=CV4) TestROC5(in=CV5) 
cdiffmodel(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.81" "CV1 AUC" = "0.82" "CV2 AUC"="0.81" "CV3 AUC"="0.79" "CV4 AUC"="0.82"
		"CV5 AUC"="0.83") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*infection confusion matrix*/
data confusion2;
set pred1_75;    
if F_cdiff=0 and I_cdiff=0 then final_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then final_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then final_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then final_75="FN"; /*false negative*/
run;
proc freq data=confusion2;
table final_75;
run;
data confusion1a;
set testpred1_75; 
if F_cdiff=0 and I_cdiff=0 then test1_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test1_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test1_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test1_75="FN"; /*false negative*/
run;
proc freq data=confusion1a;
table test1_75;
run;
data confusion2a;
set testpred2_75;
if F_cdiff=0 and I_cdiff=0 then test2_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test2_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test2_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test2_75="FN"; /*false negative*/
run;
proc freq data=confusion2a;
table test2_75;
run;
data confusion3a;
set testpred3_75;
if F_cdiff=0 and I_cdiff=0 then test3_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test3_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test3_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test3_75="FN"; /*false negative*/
run;
proc freq data=confusion3a;
table test3_75;
run;
data confusion4a;
set testpred4_75;
if F_cdiff=0 and I_cdiff=0 then test4_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test4_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test4_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test4_75="FN"; /*false negative*/
run;
proc freq data=confusion4a;
table test4_75;
run;
data confusion5a;
set testpred5_75;
if F_cdiff=0 and I_cdiff=0 then test5_75="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test5_75="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test5_75="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test5_75="FN"; /*false negative*/
run;
proc freq data=confusion5a;
table test5_75;
run;
/*IPW for 90th quantile*/
proc logistic data= cdi_2 descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile90= SDI_score v1_demog_age race insurance;
	output out=est_90prob_inf p=p_90quant_inf; *this is outputing estimated probabilities for being in the 90th percentile;
run;
data cdi2_wt90;
	set est_90prob_inf;
	if quantile90=1 then w= 0.90/p_90quant_inf;
	else if quantile90=0 then w= 0.90/(1-p_90quant_inf);
run;
/* weight range 0.91 to 54.45 with a mean of 1.75 */
proc univariate data=cdi2_wt90;
	id study_redcap_id;
	var w;
run;
/* redoing model using the weight statement add statement: weight w;*/ 
proc logistic data=cdi2_wt90 descending;
class v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance  (Ref= first) HC_referral (Ref= first);
weight w;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant priorant v1_currentabx_steroid v1_priorabx_steroid
insurance HC_referral;
run;
/* VALIDATION SECTION WITH WEIGHTS- 90th percentile
/**************randomizing the dataset*/
data analytic90 / view=analytic90;
set cdi2_wt90;
seed=1345;
s= rand('uniform');
run;
/**************sorting by the random variable and them removing it*/
proc sort data=analytic90 out=chunkable2_90 (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*creating test datasets in SAS into 5 even-ish sets;*/
Data Test1a_90;
set chunkable2_90 (firstobs = 1 obs = 135);  /* each set 1/5 of total */
run;
Data Test2a_90;
set chunkable2_90 (firstobs = 136 obs = 271);
run;
Data Test3a_90;
set chunkable2_90 (firstobs = 272 obs = 407);
run;
Data Test4a_90;
set chunkable2_90 (firstobs = 408 obs = 543);
run;
Data Test5a_90;
set chunkable2_90 (firstobs = 544 obs = 682);
run;
/*creating the 5 training sets*/
data Training1a_90;
set Test2a_90 Test3a_90 Test4a_90 Test5a_90;
run;
data Training2a_90;
set Test1a_90 Test3a_90 Test4a_90 Test5a_90;
run;
data Training3a_90;
set Test2a_90 Test1a_90 Test4a_90 Test5a_90;
run;
data Training4a_90;
set Test2a_90 Test3a_90 Test1a_90 Test5a_90;
run;
data Training5a_90;
set Test2a_90 Test3a_90 Test4a_90 Test1a_90;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a_90;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) 
priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first)/ param= ref;
weight w;
model cdiff= v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC_90 ;
score data= Test1a_90 out=testpred1_90 outroc=TestROC1_90 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a_90;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
	/ outroc=TrainROC2_90;
score data= Test2a_90 out=testpred2_90 outroc=TestROC2_90 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred2_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p =0.0138 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a_90;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC3_90;
score data= Test3a_90 out=testpred3_90 outroc=TestROC3_90 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred3_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1~=.;
roccontrast;
run; /*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a_90;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC4_90;
score data= Test4a_90 out=testpred4_90 outroc=TestROC4_90 fitstat;
roc; roccontrast;
run;
proc logistic data=testpred4_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a_90;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=TrainROC5_90;
score data= Test5a_90 out=testpred5_90 outroc=TestROC5_90 fitstat_90;
roc; roccontrast;
run;
proc logistic data=testpred5_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;/*p < .0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_;  
        datalines;
        train 0 0 
        ;
proc logistic data=cdi2_wt90 descending;
class cdiff (Ref= last) v1_course_icu (Ref= first) currentant (Ref= first) v1_currentabx_steroid (Ref= first) priorant (Ref= first) v1_priorabx_steroid (Ref= first) insurance (Ref= first) HC_referral (Ref=first) / param= ref;
weight w;
model cdiff=v1_demog_age v1_course_los v1_course_icu currentant v1_currentabx_steroid priorant v1_priorabx_steroid insurance 
HC_referral       
/ outroc=cdiffmodel_90;
score data= cdi2_wt90 out=pred1_90 fitstat;
roc; roccontrast;
run;
proc logistic data=pred1_90 descending;
model cdiff=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_infection.90probs.csv';
proc export data=pred1_90
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_infection.90probs.csv"
    dbms=csv replace;
    run;*/
data Plotdata;
set zero cdiffmodel_90; 
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0 
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1_90(in=CV) TestROC2_90(in=CV2) TestROC3_90(in=CV3) TestROC4_90(in=CV4) TestROC5_90(in=CV5) 
cdiffmodel_90(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.80" "CV1 AUC" = "0.81" "CV2 AUC"="0.81" "CV3 AUC"="0.82" "CV4 AUC"="0.80"
		"CV5 AUC"="0.80") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*infection confusion matrix-90th percentile*/
data confusion2_90;
set pred1_90;    
if F_cdiff=0 and I_cdiff=0 then final="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then final="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then final="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then final="FN"; /*false negative*/
run;
proc freq data=confusion2_90;
table final;
run;
data confusion1a_90;
set testpred1_90; 
if F_cdiff=0 and I_cdiff=0 then test1="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test1="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test1="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test1="FN"; /*false negative*/
run;
proc freq data=confusion1a_90;
table test1;
run;
data confusion2a_90;
set testpred2_90;
if F_cdiff=0 and I_cdiff=0 then test2="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test2="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test2="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test2="FN"; /*false negative*/
run;
proc freq data=confusion2a_90;
table test2;
run;
data confusion3a_90;
set testpred3_90;
if F_cdiff=0 and I_cdiff=0 then test3="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test3="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test3="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test3="FN"; /*false negative*/
run;
proc freq data=confusion3a_90;
table test3;
run;
data confusion4a_90;
set testpred4_90;
if F_cdiff=0 and I_cdiff=0 then test4="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test4="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test4="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test4="FN"; /*false negative*/
run;
proc freq data=confusion4a_90;
table test4;
run;
data confusion5a_90;
set testpred5_90;
if F_cdiff=0 and I_cdiff=0 then test5="TN";/*true negative*/
if F_cdiff=1 and I_cdiff=1 then test5="TP"; /*true positive*/
if F_cdiff=0 and I_cdiff=1 then test5="FP"; /*false positive*/
if F_cdiff=1 and I_cdiff=0 then test5="FN"; /*false negative*/
run;
proc freq data=confusion5a_90;
table test5;
run;
/*  SEVERITY  */
/*  Creating severity dataset (cases only)  */
data cdi_severity;
set cdi_2;
WHERE cdiff= 1 and severity is not missing;
run;
/* ALREADY DID THIS- Set the file path and name for the CSV file
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_severity.csv';
Export the dataset to CSV 
proc export data=cdi_severity
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_severity.csv"
    dbms=csv replace;
    run;*/
/* all cases continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous all";
proc means data=cdi_severity mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run; title "continuous all cases";
/* mild to moderate cases continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous mild to moderate cases";
proc means data=cdi_severity mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE severity= 0;
run; title "continuous mild to moderate cases";
/* moderate-severe continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous moderate to severe cases";
proc means data=cdi_severity mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE severity= 1;
run;title "continuous moderate to severe cases";
/*  all categorical  */
title "categorical all cases";
proc freq data=cdi_severity; 
table severity v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
run;title "categorical all cases";
/*  mild to moderate cases categorical  */
title "categorical mild to moderate cases";
proc freq data=cdi_severity; 
table severity v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
WHERE severity= 0;
run;title "categorical mild to moderate cases";
/*  moderate to severe cases categorical  */
title "categorical moderate to severe cases";
proc freq data=cdi_severity; 
table severity v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
WHERE severity= 1;
run;title "categorical moderate to severe cases";
/*  calculating p-values for aim 2: Severity  */
/* Used t-test for continuous variables of normal distribution*/
proc ttest data=cdi_severity sides=2 alpha=0.05 h0=0;
var  v1_demog_age v1_demog_bmi;
class severity;
run;
/* Wilcoxon two sample test for continuous variables of non-normal distribution */
proc npar1way data=cdi_severity wilcoxon;
class severity;
var v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run;
/* chi-square test for categorical variables */
proc freq data=cdi_severity; 
table severity v1_demog_gender  * severity race * severity v1_course_icu *  severity currentant 
* severity v1_currentabx_proton * severity v1_currentabx_steroid 
* severity  v1_currentabx_chemo * severity v1_currentabx_radio * severity priorant * severity v1_priorabx_proton 
* severity v1_priorabx_steroid * severity v1_priorabx_chemo * severity v1_priorabx_radio * severity insurance 
* severity surgery * severity HC_referral * severity v1_comorbid_transplant * severity gastro * severity quantile75 * severity quantile90 * severity/ norow missing nocum chisq; 
run;
/* Aim 2: CDI severity logistic model using backwards selection-WBC and creatinine not included in model because proxy for severity. */
proc logistic data=CDI_severity descending;
class v1_demog_gender (Ref= first)  race (Ref= first)  v1_course_icu (Ref= first) currentant (Ref= first) 
v1_currentabx_proton (Ref= first) v1_currentabx_steroid (Ref= first)  v1_currentabx_chemo (Ref= first) 
v1_currentabx_radio (Ref= first) priorant (Ref= first) v1_priorabx_proton (Ref= first) v1_priorabx_steroid (Ref= first) 
v1_priorabx_chemo (Ref= first) v1_priorabx_radio  (Ref= first) insurance  (Ref= first) surgery (Ref= first) 
HC_referral (Ref= first) v1_comorbid_transplant (Ref= first) v1_comorbid_gi___1 (Ref= first) / param= ref;
model severity= v1_demog_age v1_demog_gender race v1_demog_bmi v1_course_los v1_course_icu currentant 
v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio priorant v1_priorabx_proton 
v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio insurance surgery HC_referral
v1_cci_total v1_comorbid_transplant gastro
/ selection= backward
	slstay= 0.2 
	details
	lackfit 
	;
run;
/* According to backward selection, we should include current antibiotic use,
current chemo, prior proton, insurance type, current transplant surgery- INCLUDE AGE AND LOS BECAUSE MATCHED ON*/
proc logistic data=CDI_severity descending;
class currentant (Ref= first) v1_currentabx_chemo (Ref= first) 
v1_priorabx_proton (Ref=first) insurance  (Ref= first) 
v1_comorbid_transplant (Ref=first);
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo 
v1_priorabx_proton insurance v1_comorbid_transplant;
run;
/*SEVERITY MODEL randomly sorting the parent dataset*/
data analytic / view=analytic;
set cdi_severity;
seed=1347;
s= rand('uniform');
run;
proc sort data=analytic out=chunkable2 (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*chunking the datasets in SAS into 5 even-ish sets;*/
Data Test1a;
set chunkable2 (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a;
set chunkable2 (firstobs = 46 obs = 91);
run;
Data Test3a;
set chunkable2 (firstobs = 92 obs = 137);
run;
Data Test4a;
set chunkable2 (firstobs = 138 obs = 183);
run;
Data Test5a;
set chunkable2 (firstobs = 184 obs = 225);
run;
/*creating the training sets*/
data Training1a;
set Test2a Test3a Test4a Test5a;
run;
data Training2a;
set Test1a Test3a Test4a Test5a;
run;
data Training3a;
set Test1a Test2a Test4a Test5a;
run;
data Training4a;
set Test1a Test2a Test3a Test5a;
run;
data Training5a;
set Test1a Test2a Test3a Test4a;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first) insurance (Ref=last) 
v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
	/ outroc=TrainROC ;
score data= Test1a out=testpreds1 outroc=TestROC1 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpreds1;
model severity (event='1')=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = 0.1285 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant
/ outroc=TrainROC2;
score data= Test2a out=testpreds2 outroc=TestROC2 fitstat;
roc; roccontrast;
run;
proc logistic data=testpreds2;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p < 0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC3;
score data= Test3a out=testpreds3 outroc=TestROC3 fitstat;
roc; roccontrast;
run;
proc logistic data=testpreds3;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p = 0.2122 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC4;
score data= Test4a out=testpreds4 outroc=TestROC4 fitstat;
roc; roccontrast;
run;
proc logistic data=testpreds4;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.4871 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC5;
score data= Test5a out=testpreds5 outroc=TestROC5 fitstat;
roc; roccontrast;
run;
proc logistic data=testpreds5;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.0008 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
data Zero;
        input data $ _1mspec_ _sensit_;
        datalines;
        train 0 0
        ;
proc logistic data=cdi_severity;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=last) insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
/ outroc=sevmodel;
score data= cdi_severity out=preds1 fitstat;
roc; roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_severity.probs.csv';
proc export data=preds1
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_severity.probs.csv"
    dbms=csv replace;
    run;*/
/*p <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
data Plotdata;
set zero sevmodel;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1(in=CV) TestROC2(in=CV2) TestROC3(in=CV3) TestROC4(in=CV4) TestROC5(in=CV5) 
sevmodel(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.70" "CV1 AUC" = "0.65" "CV2 AUC"="0.80" "CV3 AUC"="0.38" "CV4 AUC"="0.57"
		"CV5 AUC"="0.80") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*severity model confusion matrix*/
data confusion2;
set preds1;
if F_severity=0 and I_severity=0 then final="TN";/*true negative*/
if F_severity=1 and I_severity=1 then final="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then final="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then final="FN"; /*false negative*/
run;
proc freq data=confusion2;
table final;
run;
data confusion2;
set testpreds1;
if F_severity=0 and I_severity=0 then test1="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test1="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test1="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test1="FN"; /*false negative*/
run;
proc freq data=confusion2;
table test1;
run;
data confusion2;
set testpreds2;
if F_severity=0 and I_severity=0 then test2="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test2="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test2="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test2="FN"; /*false negative*/
run;
proc freq data=confusion2;
table test2;
run;
data confusion2;
set testpreds3;
if F_severity=0 and I_severity=0 then test3="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test3="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test3="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test3="FN"; /*false negative*/
run;
proc freq data=confusion2;
table test3;
run;
data confusion2;
set testpreds4;
if F_severity=0 and I_severity=0 then test4="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test4="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test4="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test4="FN"; /*false negative*/
run;
proc freq data=confusion2;
table test4;
run;
data confusion2;
set testpreds5;
if F_severity=0 and I_severity=0 then test5="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test5="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test5="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test5="FN"; /*false negative*/
run;
proc freq data=confusion2;
table test5;
run;
/*severity model with weights-IPW, validation, confusion matrices*/
/*severity model IPW for 75th quantile*/
proc logistic data= CDI_severity descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile75= SDI_score v1_demog_age race insurance;
	output out=est_75prob_sev p=p_75quant_sev; *this is outputing estimated probabilities for being in the 75th percentile;
run;
/*prop of ppl falling within 75% catchment=78.67% or 0.7867*/
proc freq data=CDI_severity; 
table quantile75;
run;
/*putting this 0.7867 in numerator instead of 1 to stablizie- is this right?*/
data CDI_severity_wt;
	set est_75prob_sev;
	if quantile75=1 then w= 0.7867/p_75quant_sev;
	else if quantile75=0 then w= 0.7867/(1-p_75quant_sev);
run;
/* after stabilizing-weight range 0.79 to 50.03 */
proc univariate data=CDI_severity_wt;
	id study_redcap_id;
	var w;
run;
/* 75th percentile regression with weights */
proc logistic data=CDI_severity_wt;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first) insurance (Ref=first) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant;
run;
/*cross-validation-75th percentile SEVERITY MODEL randomly sorting the parent dataset*/
data analytic75s / view=analytic75s;
set cdi_severity_wt;
seed=1347;
s= rand('uniform');
run;
proc sort data=analytic75s out=chunkable75s (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*chunking the datasets in SAS into 5 even-ish sets;*/
Data Test1a_75s;
set chunkable75s (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a_75s;
set chunkable75s (firstobs = 46 obs = 91);
run;
Data Test3a_75s;
set chunkable75s (firstobs = 92 obs = 137);
run;
Data Test4a_75s;
set chunkable75s (firstobs = 138 obs = 183);
run;
Data Test5a_75s;
set chunkable75s (firstobs = 184 obs = 225);
run;
/*creating the training sets*/
data Training1a_75s;
set Test2a_75s Test3a_75s Test4a_75s Test5a_75s;
run;
data Training2a_75s;
set Test1a_75s Test3a_75s Test4a_75s Test5a_75s;
run;
data Training3a_75s;
set Test1a_75s Test2a_75s Test4a_75s Test5a_75s;
run;
data Training4a_75s;
set Test1a_75s Test2a_75s Test3a_75s Test5a_75s;
run;
data Training5a_75s;
set Test1a_75s Test2a_75s Test3a_75s Test4a_75s;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a_75s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first) insurance (Ref=last) 
v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
	/ outroc=TrainROC1_75s ;
score data= Test1a_75s out=testpred1_75s outroc=TestROC1_75s fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_75s;
model severity (event='1')=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = 0.0066 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a_75s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant
/ outroc=TrainROC2_75s;
score data= Test2a_75s out=testpred2_75s outroc=TestROC2_75s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred2_75s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p =.4292 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a_75s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC3_75s;
score data= Test3a_75s out=testpred3_75s outroc=TestROC3_75s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred3_75s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p = 0.7197 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a_75s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC4_75s;
score data= Test4a_75s out=testpred4_75s outroc=TestROC4_75s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred4_75s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.8651 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a_75s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC5_75s;
score data= Test5a_75s out=testpred5_75s outroc=TestROC5_75s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred5_75s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.5906 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
data Zero;
        input data $ _1mspec_ _sensit_;
        datalines;
        train 0 0
        ;
proc logistic data=cdi_severity_wt;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=last) insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
/ outroc=sevmodel_75s;
score data= cdi_severity_wt out=pred1_75s fitstat;
roc; roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_severity.75probs.csv';
proc export data=pred1_75s
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_severity.75probs.csv"
    dbms=csv replace;
    run; */
/*p <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
data Plotdata_75s;
set zero sevmodel_75s;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1_75s;
set zero1 TestROC1_75s(in=CV) TestROC2_75s(in=CV2) TestROC3_75s(in=CV3) TestROC4_75s(in=CV4) TestROC5_75s(in=CV5) 
sevmodel_75s(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1_75s (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.69" "CV1 AUC" = "0.66" "CV2 AUC"="0.69" "CV3 AUC"="0.73" "CV4 AUC"="0.73"
		"CV5 AUC"="0.71") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*75th percentile severity model confusion matrix*/
data confusion2_75s;
set pred1_75s;
if F_severity=0 and I_severity=0 then final="TN";/*true negative*/
if F_severity=1 and I_severity=1 then final="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then final="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then final="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table final;
run;
data confusion2_75s;
set testpred1_75s;
if F_severity=0 and I_severity=0 then test1="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test1="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test1="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test1="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table test1;
run;
data confusion2_75s;
set testpred2_75s;
if F_severity=0 and I_severity=0 then test2="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test2="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test2="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test2="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table test2;
run;
data confusion2_75s;
set testpred3_75s;
if F_severity=0 and I_severity=0 then test3="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test3="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test3="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test3="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table test3;
run;
data confusion2_75s;
set testpred4_75s;
if F_severity=0 and I_severity=0 then test4="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test4="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test4="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test4="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table test4;
run;
data confusion2_75s;
set testpred5_75s;
if F_severity=0 and I_severity=0 then test5="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test5="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test5="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test5="FN"; /*false negative*/
run;
proc freq data=confusion2_75s;
table test5;
run;
/*severity model IPW for 90th quantile*/
proc logistic data= CDI_severity descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile90= SDI_score v1_demog_age race insurance;
	output out=est_90prob_sev p=p_90quant_sev; *this is outputing estimated probabilities for being in the 90th percentile;
run;
/*prop of ppl falling within 90% catchment=90.67% or 0.9067*/
proc freq data=CDI_severity; 
table quantile90;
run;
/*putting this 0.9067 in numerator instead of 1 to stablizie- is this right?*/
data CDI_severity_wt_90;
	set est_90prob_sev;
	if quantile90=1 then w= 0.9067/p_90quant_sev;
	else if quantile90=0 then w= 0.9067/(1-p_90quant_sev);
run;
/* after stabilizing-weight range 0.91 to 100.39 */
proc univariate data=CDI_severity_wt_90;
	id study_redcap_id;
	var w;
run;
/*90th percentile regression with weights */
proc logistic data=CDI_severity_wt_90;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first) insurance (Ref=first) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant;
run;
/*cross-validation-90th percentile SEVERITY MODEL randomly sorting the parent dataset*/
data analytic90s / view=analytic90s;
seed=1347;
set cdi_severity_wt_90;
s= rand('uniform');
run;
proc sort data=analytic90s out=chunkable90s (drop=s);
by s;
run;
/*chunking the data into test and training*/
/*chunking the datasets in SAS into 5 even-ish sets;*/
Data Test1a_90s;
set chunkable90s (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a_90s;
set chunkable90s (firstobs = 46 obs = 91);
run;
Data Test3a_90s;
set chunkable90s (firstobs = 92 obs = 137);
run;
Data Test4a_90s;
set chunkable90s (firstobs = 138 obs = 183);
run;
Data Test5a_90s;
set chunkable90s (firstobs = 184 obs = 225);
run;
/*creating the training sets*/
data Training1a_90s;
set Test2a_90s Test3a_90s Test4a_90s Test5a_90s;
run;
data Training2a_90s;
set Test1a_90s Test3a_90s Test4a_90s Test5a_90s;
run;
data Training3a_90s;
set Test1a_90s Test2a_90s Test4a_90s Test5a_90s;
run;
data Training4a_90s;
set Test1a_90s Test2a_90s Test3a_90s Test5a_90s;
run;
data Training5a_90s;
set Test1a_90s Test2a_90s Test3a_90s Test4a_90s;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a_90s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first) insurance (Ref=last) 
v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
	/ outroc=TrainROC1_90s ;
score data= Test1a_90s out=testpred1_90s outroc=TestROC1_90s fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_90s;
model severity (event='1')=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = 0.0631 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a_90s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant
/ outroc=TrainROC2_90s;
score data= Test2a_90s out=testpred2_90s outroc=TestROC2_90s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred2_90s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p =.0407 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a_90s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC3_90s;
score data= Test3a_90s out=testpred3_90s outroc=TestROC3_90s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred3_90s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p < 0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a_90s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC4_90s;
score data= Test4a_90s out=testpred4_90s outroc=TestROC4_90s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred4_90s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.9783 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a_90s;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=first)
insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance 
v1_comorbid_transplant/ outroc=TrainROC5_90s;
score data= Test5a_90s out=testpred5_90s outroc=TestROC5_90s fitstat;
roc; roccontrast;
run;
proc logistic data=testpred5_90s;
model severity (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; /*p 0.6008 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
data Zero;
        input data $ _1mspec_ _sensit_;
        datalines;
        train 0 0
        ;
proc logistic data=cdi_severity_wt_90;
class severity (Ref= first)  currentant (Ref= first) v1_currentabx_chemo (Ref=first) v1_priorabx_proton (Ref=last) insurance (Ref=last) v1_comorbid_transplant (Ref=first) / param= ref;
weight w;
model severity= v1_demog_age v1_course_los currentant v1_currentabx_chemo v1_priorabx_proton insurance v1_comorbid_transplant
/ outroc=sevmodel_90s;
score data= cdi_severity_wt_90 out=pred1_90s fitstat;
roc; roccontrast;
run;
/*p <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_severity.90probs.csv';
proc export data=pred1_90s
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_severity.90probs.csv"
    dbms=csv replace;
    run;*/
data Plotdata_90s;
set zero sevmodel_90s;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1_90s;
set zero1 TestROC1_90s(in=CV) TestROC2_90s(in=CV2) TestROC3_90s(in=CV3) TestROC4_90s(in=CV4) TestROC5_90s(in=CV5) 
sevmodel_90s(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1_90s (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1_90s dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.69" "CV1 AUC" = "0.70" "CV2 AUC"="0.65" "CV3 AUC"="0.68" "CV4 AUC"="0.71"
		"CV5 AUC"="0.71") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*90th percentile severity model confusion matrix*/
data confusion2_90s;
set pred1_90s;
if F_severity=0 and I_severity=0 then final="TN";/*true negative*/
if F_severity=1 and I_severity=1 then final="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then final="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then final="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table final;
run;
data confusion2_90s;
set testpred1_90s;
if F_severity=0 and I_severity=0 then test1="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test1="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test1="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test1="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table test1;
run;
data confusion2_90s;
set testpred2_90s;
if F_severity=0 and I_severity=0 then test2="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test2="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test2="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test2="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table test2;
run;
data confusion2_90s;
set testpred3_90s;
if F_severity=0 and I_severity=0 then test3="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test3="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test3="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test3="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table test3;
run;
data confusion2_90s;
set testpred4_90s;
if F_severity=0 and I_severity=0 then test4="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test4="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test4="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test4="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table test4;
run;
data confusion2_90s;
set testpred5_90s;
if F_severity=0 and I_severity=0 then test5="TN";/*true negative*/
if F_severity=1 and I_severity=1 then test5="TP"; /*true positive*/
if F_severity=0 and I_severity=1 then test5="FP";; /*false positive*/
if F_severity=1 and I_severity=0 then test5="FN"; /*false negative*/
run;
proc freq data=confusion2_90s;
table test5;
run;
/*  RECURRENCE  */
/*  Creating reinfection dataset (cases only)  */
data cdi_reinfection;
set cdi_2; 
WHERE cdiff= 1 and v1_conseq_cdi_recur is not missing;
run;
/* ALREADY DID THIS- Set the file path and name for the CSV file
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_reinfection.csv';
/* Export the dataset to CSV 
proc export data=cdi_reinfection
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_reinfection.csv"
    dbms=csv replace;
    run;*/
/* all cases continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous all cases";
proc means data=cdi_reinfection mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run; title "continuous all cases";
/* non-reinfection cases continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous non-reinfection cases";
proc means data=cdi_reinfection mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE reinfection= 0;
run; title "continuous non-reinfection cases";
/* yes reinfection continuous variables
non-normal=LOS, WBC, creatinine, comorbid score
normal=age, BMI*/
title "continuous reinfection cases";
proc means data=cdi_reinfection mean std median Q1 Q3;
var v1_demog_age v1_demog_bmi v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
WHERE reinfection= 1;
run;title "continuous reinfection cases";
/*  all categorical  */
title "categorical all cases";
proc freq data=cdi_reinfection; 
table v1_conseq_cdi_recur v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing;
run;title "categorical all cases";
/*  non-reinfection cases categorical  */
title "categorical non-reinfection cases";
proc freq data=cdi_reinfection; 
table  v1_conseq_cdi_recur v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90  /norow nocol nocum missing; 
WHERE reinfection= 0;
run;title "categorical non-reinfection cases";
/*  yes reinfection cases categorical  */
title "categorical reinfection cases";
proc freq data=cdi_reinfection; 
table v1_conseq_cdi_recur v1_demog_gender race v1_course_icu currentant v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio 
priorant v1_priorabx_proton v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio
insurance surgery HC_referral v1_comorbid_transplant gastro quantile75 quantile90 /norow nocol nocum missing; 
WHERE v1_conseq_cdi_recur= 1;
run;title "categorical reinfection cases";
/*  calculating p-values for aim 3: Reinfection  */
/* Used t-test for continuous variables of normal distribution*/
proc ttest data=cdi_reinfection sides=2 alpha=0.05 h0=0;
var  v1_demog_age v1_demog_bmi;
class reinfection;
run;
/* Wilcoxon two sample test for continuous variables of non-normal distribution */
proc npar1way data=cdi_reinfection wilcoxon;
class reinfection;
var v1_course_los v1_chem_wbc v1_chem_creatinine v1_cci_total;
run;
/* chi-square test for categorical variables */
proc freq data=cdi_reinfection; 
table reinfection v1_demog_gender  * reinfection race * reinfection v1_course_icu *  reinfection currentant * reinfection v1_currentabx_proton * reinfection v1_currentabx_steroid 
* reinfection  v1_currentabx_chemo * reinfection v1_currentabx_radio
* reinfection priorant * reinfection v1_priorabx_proton * reinfection v1_priorabx_steroid 
* reinfection v1_priorabx_chemo * reinfection v1_priorabx_radio * reinfection insurance
* reinfection surgery * reinfection HC_referral 
* reinfection v1_comorbid_transplant * reinfection gastro * reinfection quantile75 * reinfection quantile90 * reinfection/ norow missing nocum chisq; 
run;
/* Aim 3: CDI reinfection logistic model using backwards selection-GUNNER INCLUDED WBC AND LOG CREATANINE IN HIS.. 
I HAVE NOT CREATED A LOG CREATININE VARIABLE YET SO I USED THE ORIGINAL ONE? */
proc logistic data=CDI_reinfection descending;
class v1_demog_gender (Ref= first)  race (Ref= first)  v1_course_icu (Ref= first) currentant (Ref= first) 
v1_currentabx_proton (Ref= first) v1_currentabx_steroid (Ref= first)  v1_currentabx_chemo (Ref= first) 
v1_currentabx_radio (Ref= first) priorant (Ref= first) v1_priorabx_proton (Ref= first) v1_priorabx_steroid (Ref= first) 
v1_priorabx_chemo (Ref= first) v1_priorabx_radio  (Ref= first) insurance  (Ref= first) surgery (Ref= first) 
HC_referral (Ref= first) v1_comorbid_transplant (Ref= first) v1_comorbid_gi___1 (Ref= first) / param= ref;
model reinfection= v1_demog_age v1_demog_gender race v1_demog_bmi v1_course_los v1_course_icu currentant 
v1_currentabx_proton v1_currentabx_steroid v1_currentabx_chemo v1_currentabx_radio priorant v1_priorabx_proton 
v1_priorabx_steroid v1_priorabx_chemo v1_priorabx_radio v1_chem_wbc v1_chem_creatinine insurance surgery HC_referral
v1_cci_total v1_comorbid_transplant gastro
/ selection= backward
	slstay= 0.2 
	details
	lackfit 
	;
run;
/* According to backward selection, we should include current antibiotic use, prior proton, WBC, current transplant surgery,
comorbidity score and gastro surgery- INCLUDE AGE AND LOS SINCE MATCHED ON */
proc logistic data=CDI_reinfection descending;
class currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro;
run;
/* Re-Infection cross validation*/
/*randomly sorting the parent dataset*/
data analytic / view=analytic;
set cdi_reinfection;
seed=1347;
s= rand('uniform');
run;
proc sort data=analytic out=chunkable2 (drop=s);
by s;
run;
Data Test1a;
set chunkable2 (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a;
set chunkable2 (firstobs = 46 obs = 91);
run;
Data Test3a;
set chunkable2 (firstobs = 92 obs = 137);
run;
Data Test4a;
set chunkable2 (firstobs = 138 obs = 183);
run;
Data Test5a;
set chunkable2 (firstobs = 184 obs = 227);
run;
/*creating the training sets*/
data Training1a;
set Test2a Test3a Test4a Test5a;
run;
data Training2a;
set Test1a Test3a Test4a Test5a;
run;
data Training3a;
set Test2a Test1a Test4a Test5a;
run;
data Training4a;
set Test2a Test3a Test1a Test5a;
run;
data Training5a;
set Test2a Test3a Test4a Test1a;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC1 ;
score data= Test1a out=testpredr1 outroc=TestROC1 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpredr1;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = 0.0607 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC2 ;
score data= Test2a out=testpredr2 outroc=TestROC2 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpredr2;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.2000 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC3 ;
score data= Test3a out=testpredr3 outroc=TestROC3 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpredr3;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.97 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC4 ;
score data= Test4a out=testpredr4 outroc=TestROC4 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpredr4;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.189 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC5 ;
score data= Test5a out=testpredr5 outroc=TestROC5 fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpredr5;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.0337 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_; 
        datalines;
        train 0 0
        ;
proc logistic data=cdi_reinfection;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro   
/ outroc=reinfmodel;
score data= cdi_reinfection out=predr1 fitstat;
roc;  roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_reinfection.probs.csv';
proc export data=predr1
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_reinfection.probs.csv"
    dbms=csv replace;
    run;*/
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
data Plotdata;
set zero reinfmodel;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1(in=CV) TestROC2(in=CV2) TestROC3(in=CV3) TestROC4(in=CV4) TestROC5(in=CV5) 
reinfmodel(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.78" "CV1 AUC" = "0.70" "CV2 AUC"="0.66" "CV3 AUC"="0.51" "CV4 AUC"="0.65"
		"CV5 AUC"="0.71") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*reinfection model confusion matrix*/
data confusion2;
set predr1;
if F_reinfection=0 and I_reinfection=0 then final="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then final="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then final="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then final="FN"; /*false negative */
run;
proc freq data=confusion2;
table final;
run;
data confusion2;
set testpredr1;
if F_reinfection=0 and I_reinfection=0 then test1="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test1="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test1="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test1="FN"; /*false negative */
run;
proc freq data=confusion2;
table test1;
run;
data confusion2;
set testpredr2;
if F_reinfection=0 and I_reinfection=0 then test2="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test2="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test2="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test2="FN"; /*false negative */
run;
proc freq data=confusion2;
table test2;
run;
data confusion2;
set testpredr3;
if F_reinfection=0 and I_reinfection=0 then test3="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test3="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test3="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test3="FN"; /*false negative */
run;
proc freq data=confusion2;
table test3;
run;
data confusion2;
set testpredr4;
if F_reinfection=0 and I_reinfection=0 then test4="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test4="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test4="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test4="FN"; /*false negative */
run;
proc freq data=confusion2;
table test4;
run;
data confusion2;
set testpredr5;
if F_reinfection=0 and I_reinfection=0 then test5="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test5="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test5="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test5="FN"; /*false negative */
run;
proc freq data=confusion2;
table test5;
run;
/*reinfection model with weights-IPW, validation, confusion matrices*/
/*reinfection model IPW for 75th quantile*/
proc logistic data= CDI_reinfection descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile75= SDI_score v1_demog_age race insurance;
	output out=est_75prob_reinf p=p_75quant_reinf; *this is outputing estimated probabilities for being in the 75th percentile;
run;
/*prop of ppl falling within 75% catchment=78.85% or 0.7885*/
proc freq data=CDI_reinfection; 
table quantile75;
run;
/*putting this 0.7885 in numerator instead of 1 to stablizie- is this right?*/
data CDI_reinfection_wt;
	set est_75prob_reinf;
	if quantile75=1 then w= 0.7885/p_75quant_reinf;
	else if quantile75=0 then w= 0.7885/(1-p_75quant_reinf);
run;
/* after stabilizing-weight range 0.80 to 42.9 */
proc univariate data=CDI_reinfection_wt;
	id study_redcap_id;
	var w;
run;
/* 75th percentile for reinfection model, running regression w weights */
proc logistic data=CDI_reinfection_wt descending;
class currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro;
run;
/*randomly sorting the parent dataset*/
data analytic75r / view=analytic75r;
set CDI_reinfection_wt;
s= rand('uniform');
run;
proc sort data=analytic75r out=chunkable75r (drop=s);
by s;
run;
Data Test1a_75r;
set chunkable75r (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a_75r;
set chunkable75r (firstobs = 46 obs = 91);
run;
Data Test3a_75r;
set chunkable75r (firstobs = 92 obs = 137);
run;
Data Test4a_75r;
set chunkable75r (firstobs = 138 obs = 183);
run;
Data Test5a_75r;
set chunkable75r (firstobs = 184 obs = 227);
run;
/*creating the training sets*/
data Training1a_75r;
set Test2a_75r Test3a_75r Test4a_75r Test5a_75r;
run;
data Training2a_75r;
set Test1a_75r Test3a_75r Test4a_75r Test5a_75r;
run;
data Training3a_75r;
set Test2a_75r Test1a_75r Test4a_75r Test5a_75r;
run;
data Training4a_75r;
set Test2a_75r Test3a_75r Test1a_75r Test5a_75r;
run;
data Training5a_75r;
set Test2a_75r Test3a_75r Test4a_75r Test1a_75r;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a_75r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC1_75r ;
score data= Test1a_75r out=testpred1_75r outroc=TestROC1_75r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_75r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a_75r descending;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC2_75r ;
score data= Test2a_75r out=testpred2_75r outroc=TestROC2_75r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred2_75r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.5343 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a_75r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC3_75r ;
score data= Test3a_75r out=testpred3_75r outroc=TestROC3_75r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred3_75r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 1 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a_75r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC4_75r ;
score data= Test4a_75r out=testpred4_75r outroc=TestROC4_75r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred4_75r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.2446 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a_75r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC5_75r ;
score data= Test5a_75r out=testpred5_75r outroc=TestROC5_75r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred5_75r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_; 
        datalines;
        train 0 0
        ;
proc logistic data=cdi_reinfection_wt;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro   
/ outroc=reinfmodel_75;
score data= cdi_reinfection_wt out=pred1_75r fitstat;
roc;  roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_rec.75probs.csv';
proc export data=pred1_75r
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_rec.75probs.csv"
    dbms=csv replace;
    run; */
/*p = <0.0001 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
data Plotdata;
set zero reinfmodel_75;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1_75r(in=CV) TestROC2_75r(in=CV2) TestROC3_75r(in=CV3) TestROC4_75r(in=CV4) TestROC5_75r(in=CV5) 
reinfmodel_75(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.77" "CV1 AUC" = "0.75" "CV2 AUC"="0.83" "CV3 AUC"="0.80" "CV4 AUC"="0.75"
		"CV5 AUC"="0.76") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;
/*reinfection model confusion matrix-75th percentile*/
data confusion2_75r;
set pred1_75r;
if F_reinfection=0 and I_reinfection=0 then final="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then final="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then final="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then final="FN"; /*false negative */
run;

proc freq data=confusion2_75r;
table final;
run;
data confusion1a_75r;
set testpred1_75r;
if F_reinfection=0 and I_reinfection=0 then test1="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test1="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test1="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test1="FN"; /*false negative */
run;
proc freq data=confusion1a_75r;
table test1;
run;
data confusion2a_75r;
set testpred2_75r;
if F_reinfection=0 and I_reinfection=0 then test2="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test2="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test2="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test2="FN"; /*false negative */
run;
proc freq data=confusion2a_75r;
table test2;
run;
data confusion3a_75r;
set testpred3_75r;
if F_reinfection=0 and I_reinfection=0 then test3="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test3="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test3="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test3="FN"; /*false negative */
run;
proc freq data=confusion3a_75r;
table test3;
run;
data confusion4a_75r;
set testpred4_75r;
if F_reinfection=0 and I_reinfection=0 then test4="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test4="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test4="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test4="FN"; /*false negative */
run;
proc freq data=confusion4a_75r;
table test4;
run;
data confusion5a_75r;
set testpred5_75r;
if F_reinfection=0 and I_reinfection=0 then test5="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test5="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test5="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test5="FN"; /*false negative */
run;
proc freq data=confusion5a_75r;
table test5;
run;

/*reinfection model IPW for 90th quantile*/
proc logistic data= CDI_reinfection descending;
	ods exclude ClassLevelInfo ModelAnova Association FitStatistics GlobalTests;
	class race insurance;
	model quantile90= SDI_score v1_demog_age race insurance;
	output out=est_90prob_reinf p=p_90quant_reinf; *this is outputing estimated probabilities for being in the 90th percentile;
run;
/*prop of ppl falling within 90% catchment=90.75% or 0.9075*/
proc freq data=CDI_reinfection; 
table quantile90;
run;
/*putting this 0.9075 in numerator instead of 1 to stablizie- is this right?*/
data CDI_reinfection_wt_90;
	set est_90prob_reinf;
	if quantile90=1 then w= 0.9075/p_90quant_reinf;
	else if quantile90=0 then w= 0.9075/(1-p_90quant_reinf);
run;
/* after stabilizing-weight range 0.91 to 100.39 */
proc univariate data=CDI_reinfection_wt_90;
	id study_redcap_id;
	var w;
run;
/* weighted 90th percentile regression estimates */
proc logistic data=CDI_reinfection_wt_90 descending;
class currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro;
run;
/*randomly sorting the parent dataset*/
data analytic90r / view=analytic90r;
seed=1347;
set CDI_reinfection_wt_90;
s= rand('uniform');
run;
proc sort data=analytic90r out=chunkable90r (drop=s);
by s;
run;
Data Test1a_90r;
set chunkable90r (firstobs = 1 obs = 45);  /* each set 1/5 of total */
run;
Data Test2a_90r;
set chunkable90r (firstobs = 46 obs = 91);
run;
Data Test3a_90r;
set chunkable90r (firstobs = 92 obs = 137);
run;
Data Test4a_90r;
set chunkable90r (firstobs = 138 obs = 183);
run;
Data Test5a_90r;
set chunkable90r (firstobs = 184 obs = 227);
run;
/*creating the training sets*/
data Training1a_90r;
set Test2a_90r Test3a_90r Test4a_90r Test5a_90r;
run;
data Training2a_90r;
set Test1a_90r Test3a_90r Test4a_90r Test5a_90r;
run;
data Training3a_90r;
set Test2a_90r Test1a_90r Test4a_90r Test5a_90r;
run;
data Training4a_90r;
set Test2a_90r Test3a_90r Test1a_90r Test5a_90r;
run;
data Training5a_90r;
set Test2a_90r Test3a_90r Test4a_90r Test1a_90r;
run;
/*Running Set 1 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test1)*/
proc logistic data=Training1a_90r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC1_90r ;
score data= Test1a_90r out=testpred1_90r outroc=TestROC1_90r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred1_90r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run; 
/*p = 0.3879 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 2 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test2)*/
proc logistic data=Training2a_90r descending;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC2_90r ;
score data= Test2a_90r out=testpred2_90r outroc=TestROC2_90r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred2_90r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.3247 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 3 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test3)*/
proc logistic data=Training3a_90r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC3_90r ;
score data= Test3a_90r out=testpred3_90r outroc=TestROC3_90r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred3_90r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = .4602 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*Running Set 4 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test4)*/
proc logistic data=Training4a_90r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC4_90r ;
score data= Test4a_90r out=testpred4_90r outroc=TestROC4_90r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred4_90r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = 0.0023 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
/*Running Set 5 - first proc logistic generates AUROCs
second proc logistic obtains confidence interval and test of AUC for 
validation data (test5)*/
proc logistic data=Training5a_90r;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro     
	/ outroc=TrainROC5_90r ;
score data= Test5a_90r out=testpred5_90r outroc=TestROC5_90r fitstat; /* pred prob */
roc; roccontrast;
run;
proc logistic data=testpred5_90r;
model reinfection (event= last)=;
roc pred=P_1; /* new pred var*/
where P_1 ~=.;
roccontrast;
run;
/*p = .9840 indicate that fitted model is not better than uninformative model when applied to 
the validation data*/
/*PLOTTING ROC CURVES ON OVERLAY*/
 data Zero;
        input data $ _1mspec_ _sensit_; 
        datalines;
        train 0 0
        ;
proc logistic data=cdi_reinfection_wt_90;
class reinfection (Ref= first) currentant (Ref= first) v1_priorabx_proton (Ref=first) v1_comorbid_transplant (Ref=first) gastro (Ref=first);
weight w;
model reinfection= v1_demog_age v1_course_los currentant v1_priorabx_proton v1_chem_wbc v1_cci_total 
v1_comorbid_transplant gastro   
/ outroc=reinfmodel_90;
score data= cdi_reinfection_wt_90 out=pred1_90r fitstat;
roc;  roccontrast;
run;
/* ALREADY EXPORTED probs- Set the file path and name for the CSV file 
%let output_path = 'C:\Users\nr644\Desktop\CDI\cdi_rec.90probs.csv';
proc export data=pred1_90r
    outfile= "C:\Users\nr644\Desktop\CDI\cdi_rec.90probs.csv"
    dbms=csv replace;
    run; */
/*p = 0.0007 indicate that fitted model is better than uninformative model when applied to 
the validation data*/
data Plotdata;
set zero reinfmodel_90;
if train then data="Model";
run;
 data Zero1;
        input data $ _1mspec_ _sensit_;
        datalines;
		predict 0 0
        CV1 0 0
		CV2 0 0
		CV3 0 0 
		CV4 0 0 
		CV5 0 0 
        ;
data Plotdata1;
set zero1 TestROC1_90r(in=CV) TestROC2_90r(in=CV2) TestROC3_90r(in=CV3) TestROC4_90r(in=CV4) TestROC5_90r(in=CV5) 
reinfmodel_90(in=predict);
if predict then data="predict";
if CV then data="CV1";
if CV2 then data="CV2";
if CV3 then data="CV3";
if CV4 then data="CV4";
if CV5 then data="CV5";
run;
data myattrmap;
set Plotdata1 (keep=data _1mspec_ _sensit_);
if data="predict" then linecolor="0000FF";
if data="CV1" then linecolor="FF0000" ;
if data="CV2" then linecolor="FF8000";
if data="CV3" then linecolor="FFFF00" ;
if data="CV4" then linecolor="00FF00" ;
if data="CV5" then linecolor="FF00FF";
id="myreg";
rename data=value;
run;
data myattrmap;
retain id "myid";
input value $ linecolor $ linepattern linethickness;
linecolor = linecolor;
linethickness = linethickness;
linepattern = linepattern;
datalines;
predict Black 1 2
CV1 Gray 2 1
CV2 Gray 3 1
CV3 Gray 26 1
CV4 Gray 5 1
CV5 Gray 8 1
RUN;
ODS graphics on;
proc sgplot data=plotdata1 dattrmap=myattrmap aspect=1;
        styleattrs wallcolor=grayEE;
        xaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05; 
        yaxis values=(0 to 1 by 0.25) offsetmin=.05 offsetmax=.05;
        lineparm x=0 y=0 slope=1 / transparency=.5 lineattrs=(color=black pattern=longdash);
        series x=_1mspec_ y=_sensit_ / group=data attrid=myid;
		inset ("predict AUC" = "0.72" "CV1 AUC" = "0.73" "CV2 AUC"="0.80" "CV3 AUC"="0.71" "CV4 AUC"="0.69"
		"CV5 AUC"="0.76") / 
              border position=bottomright;
        title "ROC curves for prediction and cross-validation data";
        run;

/*reinfection model confusion matrix-90th percentile*/
data confusion2_90r;
set pred1_90r;
if F_reinfection=0 and I_reinfection=0 then final="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then final="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then final="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then final="FN"; /*false negative */
run;
proc freq data=confusion2_90r;
table final;
run;
data confusion1a_90r;
set testpred1_90r;
if F_reinfection=0 and I_reinfection=0 then test1="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test1="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test1="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test1="FN"; /*false negative */
run;
proc freq data=confusion1a_90r;
table test1;
run;
data confusion2a_90r;
set testpred2_90r;
if F_reinfection=0 and I_reinfection=0 then test2="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test2="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test2="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test2="FN"; /*false negative */
run;
proc freq data=confusion2a_90r;
table test2;
run;
data confusion3a_90r;
set testpred3_90r;
if F_reinfection=0 and I_reinfection=0 then test3="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test3="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test3="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test3="FN"; /*false negative */
run;
proc freq data=confusion3a_90r;
table test3;
run;
data confusion4a_90r;
set testpred4_90r;
if F_reinfection=0 and I_reinfection=0 then test4="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test4="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test4="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test4="FN"; /*false negative */
run;
proc freq data=confusion4a_90r;
table test4;
run;
data confusion5a_90r;
set testpred5_90r;
if F_reinfection=0 and I_reinfection=0 then test5="TN";/*true negative*/
if F_reinfection=1 and I_reinfection=1 then test5="TP"; /*true positive*/
if F_reinfection=0 and I_reinfection=1 then test5="FP";; /*false positive*/
if F_reinfection=1 and I_reinfection=0 then test5="FN"; /*false negative */
run;
proc freq data=confusion5a_90r;
table test5;
run;
