/* En esta parte me voy a dedicar solo al preprocesamiento y modelización, ya que la parte del 
   análisis de datos (distribución de frecuencias, gráficos...) sería común a la desarrollada en
   el código PracticaRaquelRegLogistica.sas */
  
libname datos '/home/rventas0/my_courses/raquel/my_project';

/* Para que nos permita usar caracteres especiales */
/*options validvarname=any;*/

/* Cargamos los datos */
data banco (drop=duration default 'emp.var.rate'n 'cons.price.idx'n 'cons.conf.idx'n 'euribor3m'n 'nr.employed'n y);
	set datos.bank_additional_full;
	EMPVARRATE = 'emp.var.rate'n;
	INDPRICE = 'cons.price.idx'n; 
	INDCONF = 'cons.conf.idx'n;
	EURIBOR = 'euribor3m'n;
	NEMPLOYED = 'nr.employed'n;
	/*transformacion de la variable target*/
	if y = 'no' then contratado = 0; else contratado = 1;
run;

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

/* Tramifico, agrupo los valores de las variables continuas*/
data banco_sample;
	set banco_sample;
	if age <= 25 then age = 1;      			  
	else if 25 < age <= 35 then age = 2; 
	else if 35 < age <= 45 then age = 3; 
	else if 45 < age <= 55 then age = 4; 
	else if 55 < age <= 65 then age = 5; 
	else age = 6; /* mayor de 65 */
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

%macro mglmselect (semi_ini, semi_fin, variables);
ods trace on /listing;
%do frac=3 %to 5;
data t_fraccion;fra=&frac/10;call symput('porcen',left(fra));run;
%do semilla=&semi_ini. %to &semi_fin.;

	ods output   SelectionSummary=modelos;
	ods output   SelectedEffects=efectos;
	ods output   Glmselect.SelectedModel.FitStatistics=ajuste;

	proc glmselect data=banco_sample plots=all seed=&semilla.;
	  partition fraction(validate=&porcen);
	  class job marital education housing loan contact month day_of_week ; 
	  model contratado = &variables.
	  / selection=stepwise(select=aic choose=validate) details=all stats=all;
	run;
	data un1; i=12; set efectos; set ajuste point=i; run; *observación 12 ASEval;
	data t_semilla;
		semilla=&semilla.; output;
	run;
	data un2; set un1; set t_semilla; run;
	data union; set un2; set t_fraccion; run;
    proc append  base=t_models  data=union  force; run;
    proc sql; drop table un1, un2, union, t_semilla; quit; 
%end;
%end;
ods html close; 
proc sql; drop table modelos,efectos,ajuste,t_fraccion; quit;
%mend;

%mglmselect(12355,12385, age job marital education housing loan contact month day_of_week
	  					 campaign pdays previous EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED);
%mglmselect(12355,12385, age job marital education housing loan contact month day_of_week
	  					 campaign pdays previous EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED
	  					 age*job job*marital job*education job*housing job*loan job*EMPVARRATE
	  					 job*INDPRICE job*INDCONF job*EURIBOR job*NEMPLOYED);
%mglmselect(12355,12385, age job marital education housing loan contact month day_of_week
	  					 campaign pdays previous EMPVARRATE INDPRICE INDCONF EURIBOR NEMPLOYED
	  					 age*education education*marital job*education education*housing education*loan
	  					 education*EMPVARRATE education*INDPRICE education*INDCONF education*EURIBOR 
	  					 education*NEMPLOYED);	  					 

proc freq data=t_models (keep=effects);  tables effects /norow nocol nopercent; run;	  					 

/* De los resultados obtenidos, me quedo con los dos modelos con mayor frecuencia */
proc glmselect data=banco_sample plots=all;
  class job marital education  month contact; 
  model contratado = job marital education contact month pdays previous NEMPLOYED	/ selection=none details=all  stats=all;
run; 
proc glmselect data=banco_sample plots=all;
  class job marital education  month contact; 
  model contratado = marital contact month pdays previous NEMPLOYED job*education EURIBOR*job / selection=none details=all  stats=all;
run; 

/* Selecciono el segundo modelo */         
proc glm data=banco_sample;
  class job marital education contact month poutcome;
  model contratado  = marital contact month pdays previous NEMPLOYED job*education EURIBOR*job / solution e;
run;   

/* Realizo la predicción para seleccionar el 10% de clientes */
proc glm data=banco;
   class job marital education contact month poutcome;
   model contratado  = marital contact month pdays previous NEMPLOYED job*education EURIBOR*job;
   output out=banco_pred p=contratadopred;
run;   

proc sort data=banco_pred out=banco_pred_ordenado;
	by descending contratadopred;
run;  

proc SQL;
	create table seleccion1 as
		SELECT * FROM banco_pred_ordenado (OBS=4118);		
quit;

/* Me quedo con el resto de registros y selecciono el 5% de una muestra aleatoria */
proc sql;
	create table seleccion2 as
		SELECT * FROM banco_pred_ordenado
			WHERE contratadopred < 0.3010410813;
quit;

proc surveyselect data=seleccion2 out=seleccion3 seed=1979 
	method=srs rate=.05;	
run;

/* Uno los dos datasets */
data seleccion;
	set seleccion1 seleccion3;
run;



