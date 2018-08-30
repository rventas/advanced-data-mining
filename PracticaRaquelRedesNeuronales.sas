/* En esta parte me voy a dedicar solo al preprocesamiento y modelización, ya que la parte del 
   análisis de datos (distribución de frecuencias, gráficos...) sería común a la desarrollada en
   el código PracticaRaquelRegLogistica.sas */
  
libname datos '/home/rventas0/my_courses/raquel/my_project';

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
/* Paso las variables categóricas a numéricas, y luego hago dummy.
   Elimino default, que es una variable con mala calidad*/
data banco_sample (drop=default);
	set banco_sample;
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


/* macro redes neuronales:
	t_input  = Tabla Input
	vardepen = Variable Dependiente
	nparam   = Numero de Parametros
	nnodos   = Numero de Nodos
	semi_ini = Valor Inicial de la semilla
	semi_fin = Valor Final de la semilla
	factiva = funcion de activacion (tanh=tangente hiperbolica; LIN=funcion de activacion lineal).NORMALMENTE PARA DATOS NO LINEALES MEJOR ACT=TANH
	varindep = Variable(s) Independiente(s)
*/

%macro cruzaneural(t_input,vardepen,nparam,nnodos, semi_ini, semi_fin, factiva, varindep );
data t_output;run;
%do semilla=&semi_ini. %to &semi_fin.;
data dos;set &t_input.; u=ranuni(&semilla.); run;
proc sort data=dos; by u; run;

data dos;
retain grupo 1;
set dos nobs=nume;
if _n_>grupo*nume/&nparam. then grupo=grupo+1;
run;

data fantasma;run;
%do exclu=1 %to &nparam.;
data trestr tresval;
set dos;if grupo ne &exclu. then output trestr; else output tresval; run;

PROC DMDB DATA=trestr dmdbcat=catatres;
target &vardepen.;
var &vardepen. &varindep.; run;

proc neural data=trestr dmdbcat=catatres random=789 
validata=tresval;
input &varindep.;

target &vardepen.;
hidden &nnodos. / act=&factiva.;
prelim 30;
train maxiter=1000 outest=mlpest technique=dbldog;
score data=tresval role=valid out=sal ;
run;

data sal;set sal;resi2=(p_&vardepen.-&vardepen.)**2;run;
data fantasma;set fantasma sal;run;
%end; /* Del primer do */
proc means data=fantasma sum noprint;var resi2;
output out=sumaresi sum=suma;
run;
data sumaresi;set sumaresi;semilla=&semilla.;
data t_output (keep=suma semilla);set t_output sumaresi;if suma=. then delete;run;
%end; /* Del segundo do */
proc sql; drop table dos,trestr,tresval,fantasma,mlpest,sumaresi,sal,_namedat; quit;
%mend; /* De la macro */

/* Modelo 1: 
   con funcion de activacion tangente hiperbolica,
   metodo de particion validacion cruzada, con 4 nodos y 5 semillas. 
*/
%cruzaneural(banco_sample, contratado, 4, 4, 12345, 12349, tanh, 
             age job_1-job_11 marital_1-marital_3 education_1-education_8
             housing_1-housing_3 loan_1-loan_3 contact_1-contact_2
             month_1-month_10 day_1-day_5 EMPVARRATE INDPRICE INDCONF 
             EURIBOR NEMPLOYED);
data modelo1; set t_output; modelo='Modelo 1'; run;             
/* Modelo 2: 
   con funcion de activacion tangente hiperbolica,
   metodo de particion validacion cruzada, con 6 nodos y 5 semillas. 
*/
%cruzaneural(banco_sample, contratado, 4, 6, 12345, 12349, tanh, 
             age job_1-job_11 marital_1-marital_3 education_1-education_8
             housing_1-housing_3 loan_1-loan_3 contact_1-contact_2
             month_1-month_10 day_1-day_5 EMPVARRATE INDPRICE INDCONF 
             EURIBOR NEMPLOYED);

data modelo2; set t_output; modelo='Modelo 2'; run;

/* Modelo 3: función de activación lineal, con 4 nodos y 5 semillas */  
%cruzaneural(banco_sample, contratado, 4, 4, 12345, 12349, lin, 
             age job_1-job_11 marital_1-marital_3 education_1-education_8
             housing_1-housing_3 loan_1-loan_3 contact_1-contact_2
             month_1-month_10 day_1-day_5 EMPVARRATE INDPRICE INDCONF 
             EURIBOR NEMPLOYED);

data modelo3; set t_output; modelo='Modelo 3'; run;

/*union de las tablas*/ 
data t_output; set modelo1 modelo2 modelo3; run;

/* Analisis de sumas de los errores */
proc means data=t_output; class modelo; var suma; run;

/* Grafico box plot */
proc boxplot data=t_output; plot suma*modelo; run;

/* ejecucion del modelo, primero carga el catalogo*/
proc dmdb data=banco_sample dmdbcat=archivocat;
target contratado;
var  contratado age job_1-job_11 marital_1-marital_3 education_1-education_8
             housing_1-housing_3 loan_1-loan_3 contact_1-contact_2
             month_1-month_10 day_1-day_5 EMPVARRATE INDPRICE INDCONF 
             EURIBOR NEMPLOYED;
run;

proc neural data=banco_sample dmdbcat=archivocat random=789;
input  age job_1-job_11 marital_1-marital_3 education_1-education_8
             housing_1-housing_3 loan_1-loan_3 contact_1-contact_2
             month_1-month_10 day_1-day_5 EMPVARRATE INDPRICE INDCONF 
             EURIBOR NEMPLOYED;
target contratado;
hidden 4 / act=lin;
prelim 30;
train maxiter=1000 outest=mlpest technique=dbldog;
score data=banco_sample role=valid out=sal_prediccion ;
run;


