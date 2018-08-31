libname datos '/home/rventas0/my_courses/raquel/my_project';

/* Para que nos permita usar caracteres especiales */
options validvarname=any;
options nonotes;

/* Cargamos los datos */
data banco (drop=duration 'emp.var.rate'n 'cons.price.idx'n 'cons.conf.idx'n 'euribor3m'n 'nr.employed'n y);
	set datos.bank_additional_full;
	EMPVARRATE = 'emp.var.rate'n;
	INDPRICE = 'cons.price.idx'n; 
	INDCONF = 'cons.conf.idx'n;
	EURIBOR = 'euribor3m'n;
	NEMPLOYED = 'nr.employed'n;
	/*transformacion de la variable target*/
	if y = 'no' then contratado = 0; else contratado = 1;
run;


/*Analisis de frecuencias*/
proc freq data=banco; run;


/*Graficos para variables continuas */
ods listing close; 

ods listing gpath="/home/rventas0/my_courses/raquel/data_output";

proc univariate data=banco normal plot;
 var age EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED;
 qqplot age EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED / NORMAL (MU=EST SIGMA=EST COLOR=RED L=1);
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
run;

ods listing close;

/*Me quedo con una muestra de los datos que sea equitativa en valores positivos y negativos de la variable target*/
proc sql noprint;
	create table banco_si as select * from banco where (contratado EQ 1);	
quit;
proc sql noprint;
	create table banco_no as select * from banco where (contratado EQ 0);	
quit;
proc sort data=banco_no out=banco_no_ordenado;
	by job marital education month day_of_week;
run;
proc surveyselect data=banco_no_ordenado out=banco_no_sample seed=1979 
	method=srs sampsize=4640;
	strata job marital education month day_of_week / alloc=prop;
run;

data banco_sample;
	set banco_si banco_no_sample;
run;
proc delete data=banco_no_ordenado banco_si banco_no banco_no_sample;
data banco_sample (drop= Total AllocProportion SampleSize ActualProportion SelectionProb SamplingWeight);
	set banco_sample;
run;

/* Distribución de las variables por target */
ods noproctitle;
ods listing close; 

ods listing gpath="/home/rventas0/my_courses/raquel/data_output";

proc freq data=banco_sample;
	tables (job) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (marital) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (education) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (default) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (housing) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (loan) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
tables (contact) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (month) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
ods noproctitle;
proc freq data=banco_sample;
	tables (day_of_week) *(contratado) / missing nopercent nocum plots(only)=(mosaicplot);
run;
proc sort data=banco_sample out=banco_sample_ordenada;
	by contratado;
run;
proc univariate data=banco_sample_ordenada normal plot;
 var age EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED campaign; 
 HISTOGRAM /NORMAL(COLOR=MAROON W=4) CFILL = BLUE CFRAME = LIGR;
 INSET MEAN STD /CFILL=BLANK FORMAT=5.2;
 by contratado;
run;
proc delete data=banco_sample_ordenada; run;

ods listing close;

/* Tramifico la edad, preparo las variables categóricas para dumificarlas y agrupo
   los valores de las variables continuas. Elimino default, que es una variable con
   mala calidad*/
data banco_sample (drop=default);
	set banco_sample;
run;
data banco_sample;
	set banco_sample;
	if age <= 25 then age = 1;      			  
	else if 25 < age <= 35 then age = 2; 
	else if 35 < age <= 45 then age = 3; 
	else if 45 < age <= 55 then age = 4; 
	else if 55 < age <= 65 then age = 5; 
	else age = 6; /* mayor de 65 */
run;
data banco_sample (drop=job);
	set banco_sample;
	if job = 'admin.' then njob = 1;
	else if job = 'blue-collar' then njob = 2;
	else if job = 'entrepreneur' then njob = 3;
	else if job = 'housemaid' then njob = 4;
	else if job = 'management' then njob = 5;
	else if job = 'retired' then njob = 6;
	else if job = 'self-employed' then njob = 7;
	else if job = 'services' then njob = 8;
	else if job = 'student' then njob = 9;
	else if job = 'technician' then njob = 10;
	else if job = 'unemployed' then njob = 11;
	else if job = 'unknown' then njob = 1;
run;
data banco_sample (drop=marital);
	set banco_sample;
	if marital = 'divorced' then nmarital = 1;
	else if marital = 'married' then nmarital = 2;
	else if marital = 'single' then nmarital = 3;
	else if marital = 'unknown' then nmarital = 2;
run;
data banco_sample (drop=education);
	set banco_sample;	
	if education = 'basic.4y' then neducation = 1;
	else if education = 'basic.6y' then neducation = 2;
	else if education = 'basic.9y' then neducation = 3;
	else if education = 'high.school' then neducation = 4;
	else if education = 'illiterate' then neducation = 5;
	else if education = 'professional.course' then neducation = 6;
	else if education = 'university.degree' then neducation = 7;
	else if education = 'unknown' then neducation = 8;
run;
data banco_sample (drop=housing);
	set banco_sample;
	if housing = 'no' then nhousing = 1;
	else if housing = 'unknown' then nhousing = 2;
	else if housing = 'yes' then nhousing = 3;
run;
data banco_sample (drop=loan);
	set banco_sample;
	if loan = 'no' then nloan = 1;
	else if loan = 'unknown' then nloan = 2;
	else if loan = 'yes' then nloan = 3;
run;
data banco_sample (drop=contact);
	set banco_sample;	
	if contact = 'cellular' then ncontact = 1;
	else if contact = 'telephone' then ncontact = 2;
run;
data banco_sample (drop=month);
	set banco_sample;
	if month = 'apr' then nmonth = 1;
	else if month = 'aug' then nmonth = 2;
	else if month = 'dec' then nmonth = 3;
	else if month = 'jul' then nmonth = 4;
	else if month = 'jun' then nmonth = 5;
	else if month = 'mar' then nmonth = 6;
	else if month = 'may' then nmonth = 7;
	else if month = 'nov' then nmonth = 8;
	else if month = 'oct' then nmonth = 9;
	else if month = 'sep' then nmonth = 10;
run;
data banco_sample (drop=day_of_week);
	set banco_sample;	
	/* Codificamos variable de dia */
	if day_of_week = 'fri' then nday = 1;
	else if day_of_week = 'mon' then nday = 2;
	else if day_of_week = 'thu' then nday = 3;
	else if day_of_week = 'tue' then nday = 4;
	else if day_of_week = 'wed' then nday = 5;
run;
data banco_sample;
	set banco_sample;	
	if campaign > 3 then campaign = 4;
run;
data banco_sample;
	set banco_sample;
	if pdays = 999 then pdays = 0; /*no contactado*/
	else pdays = 1;                /*contactado*/
run;
data banco_sample (drop = poutcome);
	set banco_sample;
	if poutcome = 'failure' then npoutcome = 1;
	else if poutcome = 'nonexistent' then npoutcome = 2;
	else if poutcome = 'success' then npoutcome = 3;
run;
data banco_sample;
	set banco_sample;
	if previous > 0 then previous = 1; /*contactado*/	
run;
data banco_sample;
	set banco_sample;
	if EMPVARRATE <= -1.9 then EMPVARRATE = 1;
	else if -1.9 < EMPVARRATE <= -0.1 then EMPVARRATE = 2;
	else EMPVARRATE = 3;
run;
data banco_sample;
	set banco_sample;
	if INDPRICE <= 93 then INDPRICE = 1;
	else if 93 < INDPRICE < 94.2 then INDPRICE = 2;
	else INDPRICE = 3;
run;
data banco_sample;
	set banco_sample;
	if INDCONF <= -46.8 then INDCONF = 1;
	else if -46.8 < INDCONF < -34.8 then INDCONF = 2;
	else INDCONF = 3;
run;
data banco_sample;
	set banco_sample;
	if EURIBOR < 1.25 then EURIBOR = 1;
	else if 1.25 <= EURIBOR < 3.95 then EURIBOR = 2;
	else if 3.95 <= EURIBOR < 4.85 then EURIBOR = 3;
	else EURIBOR = 4;
run;
data banco_sample;
	set banco_sample;
	if NEMPLOYED < 5091 then NEMPLOYED = 1;
	else if 5091 <= NEMPLOYED <= 5181 then NEMPLOYED = 2;
	else if 5181 < NEMPLOYED <= 5217 then NEMPLOYED = 3;
	else NEMPLOYED = 4;
run;

%macro crearDummy (t_input, nomvar, nomarray, numNiveles);
*Ordenar las categorias de la variable(s) dummy;
proc sort data=&t_input.; BY &nomvar.; run;

*Creacion de variables dummy o variables ficticias ;
data &t_input. (drop=i &nomvar.);
 set &t_input.;
 array &nomarray.(&numNiveles.);	  
  do i=1 to &numNiveles.;	 
   if &nomvar. = i then &nomarray.(i)= 1; else &nomarray.(i)= 0;
  end;
%mend;

%crearDummy (banco_sample, age, edad_, 6);
%crearDummy (banco_sample, njob, job_, 11);
%crearDummy (banco_sample, nmarital, marital_, 3);
%crearDummy (banco_sample, neducation, education_, 8);
%crearDummy (banco_sample, nhousing, housing_, 3);
%crearDummy (banco_sample, nloan, loan_, 3);
%crearDummy (banco_sample, ncontact, contact_, 2);
%crearDummy (banco_sample, nmonth, month_, 10);
%crearDummy (banco_sample, nday, day_, 5);
%crearDummy (banco_sample, npoutcome, poutcome_, 3);
%crearDummy (banco_sample, campaign, campaign_, 4);
%crearDummy (banco_sample, EMPVARRATE, EMPVARRATE_, 3);
%crearDummy (banco_sample, INDPRICE, INDPRICE_, 3);
%crearDummy (banco_sample, INDCONF, INDCONF_, 3);
%crearDummy (banco_sample, EURIBOR, EURIBOR_, 4);
%crearDummy (banco_sample, NEMPLOYED, NEMPLOYED_, 4);



/* Macro regresión logísitca */
%macro logistic (t_input, vardepen, varindep, interaccion, semi_ini, semi_fin );
ods trace on /listing;
%do semilla=&semi_ini. %to &semi_fin.;

 ods output EffectInModel= efectoslog;/*Test de Wald de efectos en el modelo*/
 ods output FitStatistics= ajustelog; /*"Estadisticos de ajuste", AIC */
 ods output ParameterEstimates= estimalog;/*"Estimadores de parametro"*/
 ods output ModelBuildingSummary=modelolog; /*Resumen modelo, efectos*/
 ods output RSquare=ajusteRlog; /*R-cuadrado y Max-rescalado R-cuadrado*/

 proc logistic data=&t_input. EXACTOPTIONS (seed=&semilla.) ;
  class &varindep.; 
  model &vardepen. = &varindep. &interaccion. 
     / selection=stepwise details rsquare NOCHECK;
 run;

 data un1; i=12; set efectoslog; set ajustelog; point=i; run;
 data un2; i=12; set un1; set estimalog; point=i; run;
 data un3; i=12; set un2; set modelolog; point=i; run;
 data union&semilla.; i=12; set un3; set ajusteRlog; point=i; run;

 proc append  base=t_models  data=union&semilla.  force; run;
 proc sql; drop table union&semilla.; quit; 

%end;
ods html close; 
proc sql; drop table efectoslog,ajustelog,ajusteRlog,estimalog,modelolog; quit;

%mend;

ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4, ,12345, 12354);
ods results;

ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
		   job_1*marital_1 job_1*marital_2 job_1*marital_3 
		   job_2*marital_1 job_2*marital_2 job_2*marital_3 
		   job_3*marital_1 job_3*marital_2 job_3*marital_3 
		   job_4*marital_1 job_4*marital_2 job_4*marital_3 
		   job_5*marital_1 job_5*marital_2 job_5*marital_3 
		   job_6*marital_1 job_6*marital_2 job_6*marital_3 
		   job_7*marital_1 job_7*marital_2 job_7*marital_3 
		   job_8*marital_1 job_8*marital_2 job_8*marital_3 
		   job_9*marital_1 job_9*marital_2 job_9*marital_3 
		   job_10*marital_1 job_10*marital_2 job_10*marital_3 
		   job_11*marital_1 job_11*marital_2 job_11*marital_3, 12345, 12354);
ods results;

ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
		   job_1*education_1 job_1*education_2 job_1*education_3 job_1*education_4 job_1*education_5 job_1*education_6 
		   job_2*education_1 job_2*education_2 job_2*education_3 job_2*education_4 job_2*education_5 job_2*education_6 
		   job_3*education_1 job_3*education_2 job_3*education_3 job_3*education_4 job_3*education_5 job_3*education_6 
		   job_4*education_1 job_4*education_2 job_4*education_3 job_4*education_4 job_4*education_5 job_4*education_6 
		   job_5*education_1 job_5*education_2 job_5*education_3 job_5*education_4 job_5*education_5 job_5*education_6 
		   job_6*education_1 job_6*education_2 job_6*education_3 job_6*education_4 job_6*education_5 job_6*education_6 
		   job_7*education_1 job_7*education_2 job_7*education_3 job_7*education_4 job_7*education_5 job_7*education_6 
		   job_8*education_1 job_8*education_2 job_8*education_3 job_8*education_4 job_8*education_5 job_8*education_6 
		   job_9*education_1 job_9*education_2 job_9*education_3 job_9*education_4 job_9*education_5 job_9*education_6 
		   job_10*education_1 job_10*education_2 job_10*education_3 job_10*education_4 job_10*education_5 job_10*education_6 
		   job_11*education_1 job_11*education_2 job_11*education_3 job_11*education_4 job_11*education_5 job_11*education_6,
		   12345, 12354);
ods results;
ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
	       job_1*education_1 job_1*education_2 job_1*education_3 job_1*education_4 job_1*education_5 job_1*education_6
		   job_2*education_1 job_2*education_2 job_2*education_3 job_2*education_4 job_2*education_5 job_2*education_6 
		   job_3*education_1 job_3*education_2 job_3*education_3 job_3*education_4 job_3*education_5 job_3*education_6 
		   job_4*education_1 job_4*education_2 job_4*education_3 job_4*education_4 job_4*education_5 job_4*education_6 
		   job_5*education_1 job_5*education_2 job_5*education_3 job_5*education_4 job_5*education_5 job_5*education_6
		   job_6*education_1 job_6*education_2 job_6*education_3 job_6*education_4 job_6*education_5 job_6*education_6
		   job_7*education_1 job_7*education_2 job_7*education_3 job_7*education_4 job_7*education_5 job_7*education_6
		   job_8*education_1 job_8*education_2 job_8*education_3 job_8*education_4 job_8*education_5 job_8*education_6 
		   job_9*education_1 job_9*education_2 job_9*education_3 job_9*education_4 job_9*education_5 job_9*education_6 
		   job_10*education_1 job_10*education_2 job_10*education_3 job_10*education_4 job_10*education_5 job_10*education_6
		   job_11*education_1 job_11*education_2 job_11*education_3 job_11*education_4 job_11*education_5 job_11*education_6
	       job_1*marital_1 job_1*marital_2 job_1*marital_3 
		   job_2*marital_1 job_2*marital_2 job_2*marital_3 
		   job_3*marital_1 job_3*marital_2 job_3*marital_3 
		   job_4*marital_1 job_4*marital_2 job_4*marital_3 
		   job_5*marital_1 job_5*marital_2 job_5*marital_3 
		   job_6*marital_1 job_6*marital_2 job_6*marital_3 
		   job_7*marital_1 job_7*marital_2 job_7*marital_3 
		   job_8*marital_1 job_8*marital_2 job_8*marital_3 
		   job_9*marital_1 job_9*marital_2 job_9*marital_3 
		   job_10*marital_1 job_10*marital_2 job_10*marital_3 
		   job_11*marital_1 job_11*marital_2 job_11*marital_3 
	       job_1*nemployed_1 job_1*nemployed_2 job_1*nemployed_3 job_1*nemployed_4
		   job_2*nemployed_1 job_2*nemployed_2 job_2*nemployed_3 job_2*nemployed_4
		   job_3*nemployed_1 job_3*nemployed_2 job_3*nemployed_3 job_3*nemployed_4
		   job_4*nemployed_1 job_4*nemployed_2 job_4*nemployed_3 job_4*nemployed_4
		   job_5*nemployed_1 job_5*nemployed_2 job_5*nemployed_3 job_5*nemployed_4
		   job_6*nemployed_1 job_6*nemployed_2 job_6*nemployed_3 job_6*nemployed_4
		   job_7*nemployed_1 job_7*nemployed_2 job_7*nemployed_3 job_7*nemployed_4
		   job_8*nemployed_1 job_8*nemployed_2 job_8*nemployed_3 job_8*nemployed_4
		   job_9*nemployed_1 job_9*nemployed_2 job_9*nemployed_3 job_9*nemployed_4
		   job_10*nemployed_1 job_10*nemployed_2 job_10*nemployed_3 job_10*nemployed_4
		   job_11*nemployed_1 job_11*nemployed_2 job_11*nemployed_3 job_11*nemployed_4,
		   12345, 12354);
ods results;	
ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
	       edad_1*marital_1 edad_1*marital_2 edad_1*marital_3 
		   edad_2*marital_1 edad_2*marital_2 edad_2*marital_3 
		   edad_3*marital_1 edad_3*marital_2 edad_3*marital_3 
		   edad_4*marital_1 edad_4*marital_2 edad_4*marital_3 
		   edad_5*marital_1 edad_5*marital_2 edad_5*marital_3 
		   edad_6*marital_1 edad_6*marital_2 edad_6*marital_3 
	       job_1*edad_1 job_1*edad_2 job_1*edad_3 job_1*edad_4 job_1*edad_5 job_1*edad_6
		   job_2*edad_1 job_2*edad_2 job_2*edad_3 job_2*edad_4 job_2*edad_5 job_2*edad_6
		   job_3*edad_1 job_3*edad_2 job_3*edad_3 job_3*edad_4 job_3*edad_5 job_3*edad_6
		   job_4*edad_1 job_4*edad_2 job_4*edad_3 job_4*edad_4 job_4*edad_5 job_4*edad_6
		   job_5*edad_1 job_5*edad_2 job_5*edad_3 job_5*edad_4 job_5*edad_5 job_5*edad_6
		   job_6*edad_1 job_6*edad_2 job_6*edad_3 job_6*edad_4 job_6*edad_5 job_6*edad_6
		   job_7*edad_1 job_7*edad_2 job_7*edad_3 job_7*edad_4 job_7*edad_5 job_7*edad_6
		   job_8*edad_1 job_8*edad_2 job_8*edad_3 job_8*edad_4 job_8*edad_5 job_8*edad_6
		   job_9*edad_1 job_9*edad_2 job_9*edad_3 job_9*edad_4 job_9*edad_5 job_9*edad_6
		   job_10*edad_1 job_10*edad_2 job_10*edad_3 job_10*edad_4 job_10*edad_5 job_10*edad_6
		   job_11*edad_1 job_11*edad_2 job_11*edad_3 job_11*edad_4 job_11*edad_5 job_11*edad_6,
		   12345, 12354);
ods results;
ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
	       education_1*marital_1 education_1*marital_2 education_1*marital_3 
		   education_2*marital_1 education_2*marital_2 education_2*marital_3 
		   education_3*marital_1 education_3*marital_2 education_3*marital_3 
		   education_4*marital_1 education_4*marital_2 education_4*marital_3 
		   education_5*marital_1 education_5*marital_2 education_5*marital_3 
		   education_6*marital_1 education_6*marital_2 education_6*marital_3 
		   education_7*marital_1 education_7*marital_2 education_7*marital_3 
		   education_8*marital_1 education_8*marital_2 education_8*marital_3 
	       job_1*nemployed_1 job_1*nemployed_2 job_1*nemployed_3 job_1*nemployed_4
		   job_2*nemployed_1 job_2*nemployed_2 job_2*nemployed_3 job_2*nemployed_4
		   job_3*nemployed_1 job_3*nemployed_2 job_3*nemployed_3 job_3*nemployed_4
		   job_4*nemployed_1 job_4*nemployed_2 job_4*nemployed_3 job_4*nemployed_4
		   job_5*nemployed_1 job_5*nemployed_2 job_5*nemployed_3 job_5*nemployed_4
		   job_6*nemployed_1 job_6*nemployed_2 job_6*nemployed_3 job_6*nemployed_4
		   job_7*nemployed_1 job_7*nemployed_2 job_7*nemployed_3 job_7*nemployed_4
		   job_8*nemployed_1 job_8*nemployed_2 job_8*nemployed_3 job_8*nemployed_4
		   job_9*nemployed_1 job_9*nemployed_2 job_9*nemployed_3 job_9*nemployed_4
		   job_10*nemployed_1 job_10*nemployed_2 job_10*nemployed_3 job_10*nemployed_4
		   job_11*nemployed_1 job_11*nemployed_2 job_11*nemployed_3 job_11*nemployed_4
	       job_1*education_1 job_1*education_2 job_1*education_3 job_1*education_4 job_1*education_5 job_1*education_6
		   job_2*education_1 job_2*education_2 job_2*education_3 job_2*education_4 job_2*education_5 job_2*education_6 
		   job_3*education_1 job_3*education_2 job_3*education_3 job_3*education_4 job_3*education_5 job_3*education_6 
		   job_4*education_1 job_4*education_2 job_4*education_3 job_4*education_4 job_4*education_5 job_4*education_6 
		   job_5*education_1 job_5*education_2 job_5*education_3 job_5*education_4 job_5*education_5 job_5*education_6
		   job_6*education_1 job_6*education_2 job_6*education_3 job_6*education_4 job_6*education_5 job_6*education_6
		   job_7*education_1 job_7*education_2 job_7*education_3 job_7*education_4 job_7*education_5 job_7*education_6
		   job_8*education_1 job_8*education_2 job_8*education_3 job_8*education_4 job_8*education_5 job_8*education_6 
		   job_9*education_1 job_9*education_2 job_9*education_3 job_9*education_4 job_9*education_5 job_9*education_6 
		   job_10*education_1 job_10*education_2 job_10*education_3 job_10*education_4 job_10*education_5 job_10*education_6
		   job_11*education_1 job_11*education_2 job_11*education_3 job_11*education_4 job_11*education_5 job_11*education_6
	       job_1*marital_1 job_1*marital_2 job_1*marital_3 
		   job_2*marital_1 job_2*marital_2 job_2*marital_3 
		   job_3*marital_1 job_3*marital_2 job_3*marital_3 
		   job_4*marital_1 job_4*marital_2 job_4*marital_3 
		   job_5*marital_1 job_5*marital_2 job_5*marital_3 
		   job_6*marital_1 job_6*marital_2 job_6*marital_3 
		   job_7*marital_1 job_7*marital_2 job_7*marital_3 
		   job_8*marital_1 job_8*marital_2 job_8*marital_3 
		   job_9*marital_1 job_9*marital_2 job_9*marital_3 
		   job_10*marital_1 job_10*marital_2 job_10*marital_3 
		   job_11*marital_1 job_11*marital_2 job_11*marital_3, 		   
		   12345, 12354);
ods results;		
ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
	       education_1*marital_1 education_1*marital_2 education_1*marital_3 
		   education_2*marital_1 education_2*marital_2 education_2*marital_3 
		   education_3*marital_1 education_3*marital_2 education_3*marital_3 
		   education_4*marital_1 education_4*marital_2 education_4*marital_3 
		   education_5*marital_1 education_5*marital_2 education_5*marital_3 
		   education_6*marital_1 education_6*marital_2 education_6*marital_3 
		   education_7*marital_1 education_7*marital_2 education_7*marital_3 
		   education_8*marital_1 education_8*marital_2 education_8*marital_3 
		   education_1*nemployed_1 education_1*nemployed_2 education_1*nemployed_3 education_1*nemployed_4
		   education_2*nemployed_1 education_2*nemployed_2 education_2*nemployed_3 education_2*nemployed_4
		   education_3*nemployed_1 education_3*nemployed_2 education_3*nemployed_3 education_3*nemployed_4
		   education_4*nemployed_1 education_4*nemployed_2 education_4*nemployed_3 education_4*nemployed_4
		   education_5*nemployed_1 education_5*nemployed_2 education_5*nemployed_3 education_5*nemployed_4
		   education_6*nemployed_1 education_6*nemployed_2 education_6*nemployed_3 education_6*nemployed_4
		   education_7*nemployed_1 education_7*nemployed_2 education_7*nemployed_3 education_7*nemployed_4
		   education_8*nemployed_1 education_8*nemployed_2 education_8*nemployed_3 education_8*nemployed_4
	       job_1*nemployed_1 job_1*nemployed_2 job_1*nemployed_3 job_1*nemployed_4
		   job_2*nemployed_1 job_2*nemployed_2 job_2*nemployed_3 job_2*nemployed_4
		   job_3*nemployed_1 job_3*nemployed_2 job_3*nemployed_3 job_3*nemployed_4
		   job_4*nemployed_1 job_4*nemployed_2 job_4*nemployed_3 job_4*nemployed_4
		   job_5*nemployed_1 job_5*nemployed_2 job_5*nemployed_3 job_5*nemployed_4
		   job_6*nemployed_1 job_6*nemployed_2 job_6*nemployed_3 job_6*nemployed_4
		   job_7*nemployed_1 job_7*nemployed_2 job_7*nemployed_3 job_7*nemployed_4
		   job_8*nemployed_1 job_8*nemployed_2 job_8*nemployed_3 job_8*nemployed_4
		   job_9*nemployed_1 job_9*nemployed_2 job_9*nemployed_3 job_9*nemployed_4
		   job_10*nemployed_1 job_10*nemployed_2 job_10*nemployed_3 job_10*nemployed_4
		   job_11*nemployed_1 job_11*nemployed_2 job_11*nemployed_3 job_11*nemployed_4
	       job_1*education_1 job_1*education_2 job_1*education_3 job_1*education_4 job_1*education_5 job_1*education_6
		   job_2*education_1 job_2*education_2 job_2*education_3 job_2*education_4 job_2*education_5 job_2*education_6 
		   job_3*education_1 job_3*education_2 job_3*education_3 job_3*education_4 job_3*education_5 job_3*education_6 
		   job_4*education_1 job_4*education_2 job_4*education_3 job_4*education_4 job_4*education_5 job_4*education_6 
		   job_5*education_1 job_5*education_2 job_5*education_3 job_5*education_4 job_5*education_5 job_5*education_6
		   job_6*education_1 job_6*education_2 job_6*education_3 job_6*education_4 job_6*education_5 job_6*education_6
		   job_7*education_1 job_7*education_2 job_7*education_3 job_7*education_4 job_7*education_5 job_7*education_6
		   job_8*education_1 job_8*education_2 job_8*education_3 job_8*education_4 job_8*education_5 job_8*education_6 
		   job_9*education_1 job_9*education_2 job_9*education_3 job_9*education_4 job_9*education_5 job_9*education_6 
		   job_10*education_1 job_10*education_2 job_10*education_3 job_10*education_4 job_10*education_5 job_10*education_6
		   job_11*education_1 job_11*education_2 job_11*education_3 job_11*education_4 job_11*education_5 job_11*education_6
	       job_1*marital_1 job_1*marital_2 job_1*marital_3 
		   job_2*marital_1 job_2*marital_2 job_2*marital_3 
		   job_3*marital_1 job_3*marital_2 job_3*marital_3 
		   job_4*marital_1 job_4*marital_2 job_4*marital_3 
		   job_5*marital_1 job_5*marital_2 job_5*marital_3 
		   job_6*marital_1 job_6*marital_2 job_6*marital_3 
		   job_7*marital_1 job_7*marital_2 job_7*marital_3 
		   job_8*marital_1 job_8*marital_2 job_8*marital_3 
		   job_9*marital_1 job_9*marital_2 job_9*marital_3 
		   job_10*marital_1 job_10*marital_2 job_10*marital_3 
		   job_11*marital_1 job_11*marital_2 job_11*marital_3, 		   
		   12345, 12354);
ods results;
ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
	       indprice_1*marital_1 indprice_1*marital_2 indprice_1*marital_3 
		   indprice_2*marital_1 indprice_2*marital_2 indprice_2*marital_3 
		   indprice_3*marital_1 indprice_3*marital_2 indprice_3*marital_3 
	       job_1*nemployed_1 job_1*nemployed_2 job_1*nemployed_3 job_1*nemployed_4
		   job_2*nemployed_1 job_2*nemployed_2 job_2*nemployed_3 job_2*nemployed_4
		   job_3*nemployed_1 job_3*nemployed_2 job_3*nemployed_3 job_3*nemployed_4
		   job_4*nemployed_1 job_4*nemployed_2 job_4*nemployed_3 job_4*nemployed_4
		   job_5*nemployed_1 job_5*nemployed_2 job_5*nemployed_3 job_5*nemployed_4
		   job_6*nemployed_1 job_6*nemployed_2 job_6*nemployed_3 job_6*nemployed_4
		   job_7*nemployed_1 job_7*nemployed_2 job_7*nemployed_3 job_7*nemployed_4
		   job_8*nemployed_1 job_8*nemployed_2 job_8*nemployed_3 job_8*nemployed_4
		   job_9*nemployed_1 job_9*nemployed_2 job_9*nemployed_3 job_9*nemployed_4
		   job_10*nemployed_1 job_10*nemployed_2 job_10*nemployed_3 job_10*nemployed_4
		   job_11*nemployed_1 job_11*nemployed_2 job_11*nemployed_3 job_11*nemployed_4
		   job_1*indprice_1 job_1*indprice_2 job_1*indprice_3 
		   job_2*indprice_1 job_2*indprice_2 job_2*indprice_3 
		   job_3*indprice_1 job_3*indprice_2 job_3*indprice_3 
		   job_4*indprice_1 job_4*indprice_2 job_4*indprice_3 
		   job_5*indprice_1 job_5*indprice_2 job_5*indprice_3 
		   job_6*indprice_1 job_6*indprice_2 job_6*indprice_3 
		   job_7*indprice_1 job_7*indprice_2 job_7*indprice_3 
		   job_8*indprice_1 job_8*indprice_2 job_8*indprice_3 
		   job_9*indprice_1 job_9*indprice_2 job_9*indprice_3 
		   job_10*indprice_1 job_10*indprice_2 job_10*indprice_3 
		   job_11*indprice_1 job_11*indprice_2 job_11*indprice_3
	       job_1*euribor_1 job_1*euribor_2 job_1*euribor_3 job_1*euribor_4
		   job_2*euribor_1 job_2*euribor_2 job_2*euribor_3 job_2*euribor_4
		   job_3*euribor_1 job_3*euribor_2 job_3*euribor_3 job_3*euribor_4
		   job_4*euribor_1 job_4*euribor_2 job_4*euribor_3 job_4*euribor_4
		   job_5*euribor_1 job_5*euribor_2 job_5*euribor_3 job_5*euribor_4
		   job_6*euribor_1 job_6*euribor_2 job_6*euribor_3 job_6*euribor_4
		   job_7*euribor_1 job_7*euribor_2 job_7*euribor_3 job_7*euribor_4
		   job_8*euribor_1 job_8*euribor_2 job_8*euribor_3 job_8*euribor_4
		   job_9*euribor_1 job_9*euribor_2 job_9*euribor_3 job_9*euribor_4
		   job_10*euribor_1 job_10*euribor_2 job_10*euribor_3 job_10*euribor_4
		   job_11*euribor_1 job_11*euribor_2 job_11*euribor_3 job_11*euribor_4,		   
		   12345, 12354);
ods results;

ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
		   job_1*empvarrate_1 job_1*empvarrate_2 job_1*empvarrate_3 
		   job_2*empvarrate_1 job_2*empvarrate_2 job_2*empvarrate_3 
		   job_3*empvarrate_1 job_3*empvarrate_2 job_3*empvarrate_3 
		   job_4*empvarrate_1 job_4*empvarrate_2 job_4*empvarrate_3 
		   job_5*empvarrate_1 job_5*empvarrate_2 job_5*empvarrate_3 
		   job_6*empvarrate_1 job_6*empvarrate_2 job_6*empvarrate_3 
		   job_7*empvarrate_1 job_7*empvarrate_2 job_7*empvarrate_3 
		   job_8*empvarrate_1 job_8*empvarrate_2 job_8*empvarrate_3 
		   job_9*empvarrate_1 job_9*empvarrate_2 job_9*empvarrate_3 
		   job_10*empvarrate_1 job_10*empvarrate_2 job_10*empvarrate_3 
		   job_11*empvarrate_1 job_11*empvarrate_2 job_11*empvarrate_3
		   edad_1*empvarrate_1 edad_1*empvarrate_2 edad_1*empvarrate_3 
		   edad_2*empvarrate_1 edad_2*empvarrate_2 edad_2*empvarrate_3 
		   edad_3*empvarrate_1 edad_3*empvarrate_2 edad_3*empvarrate_3 
		   edad_4*empvarrate_1 edad_4*empvarrate_2 edad_4*empvarrate_3 
		   edad_5*empvarrate_1 edad_5*empvarrate_2 edad_5*empvarrate_3 
		   edad_6*empvarrate_1 edad_6*empvarrate_2 edad_6*empvarrate_3 , 12345, 12354);
ods results;

ods noresults;
%logistic (banco_sample, contratado, edad_1-edad_6 job_1-job_11 marital_1-marital_3
<<<<<<< HEAD
           education_1-education_8 housing_1-housing_3 loan_1-loan_3 contact_1-contact_2 month_1-month_10 
           day_1-day_5 campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
=======
           education_1-education_8 contact_1-contact_2 month_1-month_10 
           campaign_1-campaign_4 previous poutcome_1-poutcome_3 pdays 
>>>>>>> a5d9c62cdf1be832a01c68a5e3d66fd4decb4f39
           EMPVARRATE_1-EMPVARRATE_3 INDPRICE_1-INDPRICE_3 INDCONF_1-INDCONF_3 
           EURIBOR_1-EURIBOR_4 NEMPLOYED_1-NEMPLOYED_4,
		   job_1*EURIBOR_1 job_1*EURIBOR_2 job_1*EURIBOR_3 job_1*EURIBOR_4 
		   job_2*EURIBOR_1 job_2*EURIBOR_2 job_2*EURIBOR_3 job_2*EURIBOR_4
		   job_3*EURIBOR_1 job_3*EURIBOR_2 job_3*EURIBOR_3 job_3*EURIBOR_4
		   job_4*EURIBOR_1 job_4*EURIBOR_2 job_4*EURIBOR_3 job_4*EURIBOR_4
		   job_5*EURIBOR_1 job_5*EURIBOR_2 job_5*EURIBOR_3 job_5*EURIBOR_4
		   job_6*EURIBOR_1 job_6*EURIBOR_2 job_6*EURIBOR_3 job_6*EURIBOR_4
		   job_7*EURIBOR_1 job_7*EURIBOR_2 job_7*EURIBOR_3 job_7*EURIBOR_4
		   job_8*EURIBOR_1 job_8*EURIBOR_2 job_8*EURIBOR_3 job_8*EURIBOR_4
		   job_9*EURIBOR_1 job_9*EURIBOR_2 job_9*EURIBOR_3 job_9*EURIBOR_4
		   job_10*EURIBOR_1 job_10*EURIBOR_2 job_10*EURIBOR_3 job_10*EURIBOR_4 
		   job_11*EURIBOR_1 job_11*EURIBOR_2 job_11*EURIBOR_3 job_11*EURIBOR_4, 12345, 12354);
ods results;			
/*Analisis de los resultados obtenidos de la macro*/
proc freq data=t_models (keep=effect ProbChiSq);  tables effect*ProbChiSq /norow nocol nopercent; run;
proc sql; select distinct * from t_models (keep=effect nvalue1 rename=(nvalue1=RCuadrado)) order by RCuadrado desc; quit;
proc sql; select distinct * from t_models (keep=effect StdErr) order by StdErr; quit;

/*** CURVA ROC ***/
ods graphics on;

proc logistic data=banco_sample desc  PLOTS(MAXPOINTS=NONE); 
 class job_1 job_2 job_10 nemployed_1 nemployed_2 education_4 education_7
 	   marital_1 month_4 pdays;
 model contratado = job_1 job_2 job_10 nemployed_1 nemployed_2 education_4 education_7
 	   marital_1 month_4 pdays
 /ctable pprob = (.05 to 1 by .05)  outroc=roc; 
run;
   
