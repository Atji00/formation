***Informality in Colombia***
   ***********************
   
   ****NOTICE******
  
* This dofile is divided in 4 SECTIONS

        *SECTION 1
* In this section, we agregate wages, salaries and health&retirement contribution by firm
* in modulo personal_ocupado and define an informal worker.

        *SECTION 2
*We merge the following modulos in Micronegocios 2019 specially:
*          -Modulo identificacion
*          -Modulo caracteristicas del micronegocios
*          -Modulo Informacion proprietario
*          -Modulo costos_gastos_activos
*          -Modulo ventas o ingresos
*          -Modulo inclusion financiera
*          -Modulo emprendimiento
*          -Modulo personal_ocupado
*                +
* GEIH 2019 (Household survey)

        *SECTION 3
*We compute value added & revenues and make the different kernel density using VENTAS_MES_ANTERIOR. We also replicate
* the monthly earnings (ganancias mensualles: P3072) from EMICROM methodology document,  june 2020, P26-27.
* Finally, we calculate INTENSIVE & EXTENSIVE margins

       *SECTION 4
* Calculation of the 16 moments according to Ulyssea paper following RUT & Camara de comercio criterias
   
 *******************************************************************************  
                                   *SECTION 1*
								   **********
   *memory cleaning
clear
capture log close
set more off
*
*workspace localisation
cd "C:\Users\pc\Downloads\Données informalité colombie"
*
*log file
log using colombia.log, replace
*  
use persona_ocupado.dta

rename SECUENCIA_ENCUESTA New_identifier

rename SECUENCIA_P SECUENCIA_ENCUESTA

rename SECUENCIA_PH SECUENCIA_P

*Definition of a formal worker
 
gen Formality=(P3080==2)

recode Formality (1=0) (0=1)

lab var Formality " Workers'formality"

lab def Formality 1 "Formal workers" 0 "Infomal workers"

lab values Formality Formality

tab Formality TIPO
/*
Workers'formali |         Personal ocupado
             ty | Trabajado     Socios  Trabajado |     Total
----------------+---------------------------------+----------
Infomal workers |    16,086      4,435      8,961 |    29,482 
 Formal workers |     4,511        400        158 |     5,069 
----------------+---------------------------------+----------
          Total |    20,597      4,835      9,119 |    34,551  
*/

*generate an ID in order to compute agregate wages
egen Firm_ID= concat( DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA ), punct(" ")

order DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA New_identifier Firm_ID

sort DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA New_identifier Firm_ID

*Total wage by firm
egen wage= total( P3079), by( Firm_ID)

*Total health and retirement contributions by firm
egen salud_pension= total( P3081 ), by( Firm_ID)

*Total social security by firm
egen social_security= total( P3083 ), by( Firm_ID)

*Labour costs computing "according to EMICRON methodology/june 2020, p27"
 
gen Labour_costs= wage + salud_pension + social_security

br Firm_ID wage salud_pension social_security Labour_costs

save, replace
clear
********************************************************************************
                                           *SECTION 2*
										   ***********
										   
use modulo_identificacion.dta
sort DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA 

merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using Información_proprietario.dta
drop _merge
save newdata.dta, replace
clear

use newdata.dta
merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using carcateristicas_micronegocio.dta
drop _merge
save, replace

merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using costos_gastos_activos.dta
drop _merge
save, replace

merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using ventas_ingresos.dta
drop _merge
save, replace

merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using emprendimiento.dta
drop _merge
save, replace

merge 1:1 DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using inclusion_financiera.dta
drop _merge
sort DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA
save, replace

*merging with household survey (GEIH 2018-2019)
merge 1:1  DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using household_data.dta
gen EMICRON_workers=(_merge==1 | _merge==3)
drop _merge
tab EMICRON_workers
keep if EMICRON_workers==1
save, replace

merge 1:m DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA using persona_ocupado.dta
drop _merge
save, replace

*Compute the total of workers in the firm

bysort Firm_ID: gen total_workers= _N

replace total_workers = total_workers + 1 if total_workers != 67130

replace total_workers=1 if total_workers==67130
 
lab var total_worker "Total workers in firm last month"
*
br DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA Firm_ID Labour_costs total_workers

egen ID= concat( DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA ), punct(" ")

lab var ID "Firms who appear in modulo personal ocupado and those which not"

lab var Firm_ID " Firms who only appear in modulo personal ocupado"

tab total_workers if ID[_n]!= ID[_n+1]
/*
      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     67,130       77.19       77.19
          2 |     12,111       13.93       91.11
          3 |      4,262        4.90       96.01
          4 |      1,758        2.02       98.04
          5 |        811        0.93       98.97
          6 |        406        0.47       99.44
          7 |        242        0.28       99.71
          8 |        122        0.14       99.85
          9 |         81        0.09       99.95
         10 |         46        0.05      100.00
------------+-----------------------------------
      Total |     86,969      100.00
*/

*Total EMPLOYEES in the sample(EMICRON 2019): WORKERS + ENTREPRENEURS

total total_workers if ID[_n]!=ID[_n+1]
/*
Total estimation                  Number of obs   =     86,969

---------------------------------------------------------------
              |      Total   Std. Err.     [95% Conf. Interval]
--------------+------------------------------------------------
total_workers |     121520   279.2517      120972.7    122067.3
---------------------------------------------------------------
*/

sort ID 
duplicates report ID
duplicates drop ID, force							   					 
********************************************************************************
                                       *SECTION 3*
									   ***********

/* Here we replicate the value added & profit (P3072_j) computing according to EMICRON methodology
 document, june 2020, p26-p27*/

global list1 P3057  P3058  P3059  P3060  P3061  P3062  P4002  P3063  P3064 P3065  P3066  P3067  P3092  P3093

global list2 P3056_A P3056_B P3056_C P3056_D P3017_A P3017_B P3017_C P3017_D P3017_E P3017_F P3017_G P3017_H P3017_K P3017_I P3017_L
      
foreach var in $list1 $list2 {
                     replace `var'=0 if `var'==.
					 }

replace Labour_costs=0 if Labour_costs==.
					
					*ventas_mes_anterior
					
gen ventas_j= P3057 + P3058 + P3059 + P3060 + P3061 + P3062 + P4002 + P3063 + P3064 + ///
              P3065 + P3066 + P3067 + P3092 + P3093     
         
		            *consumo_intermedio
					
gen consumo_j= P3056_A + P3056_B + P3056_C + P3056_D + P3017_A + P3017_B + P3017_C + ///
               P3017_D + P3017_E + P3017_F + P3017_G + P3017_H + P3017_K + (P3017_I/12) + (P3017_L/12)
			   
			        *Value added per worker
					
gen VA_per_worker= (ventas_j - consumo_j)/total_workers

                    *Profit "p3072" per worker
					
gen profit_per_worker= (ventas_j - consumo_j - Labour_costs - (P3017_J/12))/total_workers

* Profit vs P3072

gen profit= ventas_j - consumo_j - Labour_costs - (P3017_J/12)

sum profit P3072
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      profit |     86,969      778274     3687065  -2.40e+08   1.94e+08
       P3072 |     86,969    781391.4     1916650          0   1.80e+08
*/
sum profit if profit<0
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      profit |      6,368    -1659688     6843755  -2.40e+08  -32.87413
*/

sum profit if profit<0

/*    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      profit |      6,368    -1659688     6843755  -2.40e+08  -32.87413
*/

replace profit=0 if profit<0

sum profit P3072

 /*   Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      profit |     86,969    899798.9     3124075          0   1.94e+08
       P3072 |     86,969    781391.4     1916650          0   1.80e+08
*/
**********************log_revenues

destring GRUPOS4, replace

gen log_reven = log(ventas_j)

reg log_reven i.GRUPOS4

predict logreven_purged, residuals

lab var logreven_purged "log of Firms revenues"

sum logreven_purged
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
logreven_p~d |     81,840    1.21e-11     1.32702  -6.325315   5.991469
*/

*Switch negative logventas_purged in positive values

replace logreven_purged =logreven_purged + 6.325315
*

*********************log_VA_per_worker

sum VA_per_worker
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
VA_per_wor~r |     86,969    663143.8     1927031  -8.13e+07   1.36e+08

*/

replace VA_per_worker=. if VA_per_worker <=0

gen log_va_per_worker= log(VA_per_worker)

reg log_va_per_worker i.GRUPOS4

predict log_purged, residuals

lab var log_purged "log(VA per worker)"

sum log_purged
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  log_purged |     79,006   -6.23e-11     1.28651  -8.464633   5.879013
*/

*Switch negative log_purged in positive values

replace log_purged = log_purged + 8.464633


***********************log_profit_perworker

sum profit_per_worker
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
profit_per~r |     86,969    599483.7     1913293  -8.13e+07   1.36e+08

*/

replace profit_per_worker=. if profit_per_worker <=0

gen log_profit= log(profit_per_worker)

reg log_profit i.GRUPOS4

predict logprofit_purged, residuals

lab var logprofit_purged "log(profit per worker)"

sum logprofit_purged
 /*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
logprofit_~d |     77,033   -2.97e-09    1.284744  -7.975104   5.915942

*/

*Switch negative logprofit_purged in positive values

replace logprofit_purged = logprofit_purged + 7.975104

********KERNEL DENSITY GRAPH (Ulyssea 2018)

*PANEL A. Productivity distribution
#delimit ;
twoway (kdensity log_purged if P1055==1, bwidth(0.2183) lcolor(green)) (kdensity log_purged if P1055==2, bwidth(0.2183)), 
                                           ytitle(K.Density) xtitle(log (VA per worker)) title(FIGURE 1E) subtitle(Panel A. Productivity log(VA/worker) _ monthly average) 
										   note("source: Graph made using Micronegocios dataset 2019" "For this time, we use monthly averages of value added" 
										   "We use P1633/Registro Unico Tributario (RUT) as informality criteria"
										   "(yes) for formal firms and (no) for informal firms") 
										   legend(on order(1 "Formal" 2 "Informal"));
										   
*PANEL B. Size distribution
#delimit ;
twoway (kdensity logreven_purged if P1055==1, bwidth(0.2308) lcolor(green)) (kdensity logreven_purged if P1055==2, bwidth(0.2308)), ytitle(K.Density) xtitle(log (revenues)) 
                                         title(FIGURE 1F) subtitle(Panel B. Size log(revenues) _ monthly average) 
										 note("source: Graph made using Micronegocios dataset 2019. we use ventas_mes_anterior for this graph" 
										 "We use P1633/Registro Unico Tributario (RUT) as informality criteria"
										   "(yes) for formal firms and (no) for informal firms") 
									     legend(on order(1 "Formal" 2 "Informal"));

*PANEL C. Profit distribution
#delimit ;
twoway (kdensity logprofit_purged if P1055==1, bwidth(0.2183) lcolor(green)) (kdensity logprofit_purged if P1055==2, bwidth(0.2183)), 
                                           ytitle(K.Density) xtitle(log (Profit per worker)) title(FIGURE 1G) subtitle(Panel C. Profit log(Profit/worker) _ monthly average) 
										   note("source: Graph made using Micronegocios dataset 2019" "For this time, we use monthly averages of profit: variable P3072 replicated" 
										   "We use P1633/Registro Unico Tributario (RUT) as informality criteria"
										   "(yes) for formal firms and (no) for informal firms") 
										   legend(on order(1 "Formal" 2 "Informal"));
			                              
										   
*STATISTICS ON EXTENSIVE & INTENSIVE MARGINS
sort ID Firm_ID 

*INTENSIVE MARGIN

****> Following RUT criteria

tab TIPO Formality if P1633==1
/*
                      |   Workers'formality
     Personal ocupado | Infomal w  Formal wo |     Total
----------------------+----------------------+----------
Trabajadores que reci |     9,303      4,340 |    13,643 
               Socios |     1,783        339 |     2,122 
Trabajadores o famili |     2,884        121 |     3,005 
----------------------+----------------------+----------
                Total |    13,970      4,800 |    18,770 
*/
gen dichoto1=1 if P1633==1 & Formality==0

gen var1 = Firm_ID if dichoto==1

bysort var1: gen intensive_margin_RUT= _N if dichoto==1

total intensive_margin_RUT if Firm_ID[_n]!=Firm_ID[_n+1]

/*Total estimation                  Number of obs   =      7,768

----------------------------------------------------------------------
                     |      Total   Std. Err.     [95% Conf. Interval]
---------------------+------------------------------------------------
intensive_margin_RUT |      13970    111.238      13751.94    14188.06
----------------------------------------------------------------------
*/
tab intensive_margin_RUT if Firm_ID[_n]!=Firm_ID[_n+1]
/*
intensive_m |
  argin_RUT |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      4,485       57.74       57.74
          2 |      1,792       23.07       80.81
          3 |        761        9.80       90.60
          4 |        355        4.57       95.17
          5 |        182        2.34       97.52
          6 |        113        1.45       98.97
          7 |         43        0.55       99.52
          8 |         24        0.31       99.83
          9 |         13        0.17      100.00
------------+-----------------------------------
      Total |      7,768      100.00
*/

******> following Camara de comercio criteria

tab TIPO Formality if P1055==1

/*
                      |   Workers'formality
     Personal ocupado | Infomal w  Formal wo |     Total
----------------------+----------------------+----------
Trabajadores que reci |     6,373      3,850 |    10,223 
               Socios |     1,283        284 |     1,567 
Trabajadores o famili |     2,240        117 |     2,357 
----------------------+----------------------+----------
                Total |     9,896      4,251 |    14,147 
*/
gen dichoto2=1 if P1055==1 & Formality==0

gen var2= Firm_ID if dichoto2==1

bysort var2: gen intensive_margin_CC= _N if dichoto2==1

total intensive_margin_CC if Firm_ID[_n]!=Firm_ID[_n+1]

/*Total estimation                  Number of obs   =      5,371

---------------------------------------------------------------------
                    |      Total   Std. Err.     [95% Conf. Interval]
--------------------+------------------------------------------------
intensive_margin_CC |       9896   94.99697      9709.767    10082.23
---------------------------------------------------------------------
*/

tab intensive_margin_CC if Firm_ID[_n]!=Firm_ID[_n+1]
/*
intensive_m |
   argin_CC |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      3,026       56.34       56.34
          2 |      1,236       23.01       79.35
          3 |        561       10.44       89.80
          4 |        266        4.95       94.75
          5 |        138        2.57       97.32
          6 |         81        1.51       98.83
          7 |         38        0.71       99.53
          8 |         16        0.30       99.83
          9 |          9        0.17      100.00
------------+-----------------------------------
      Total |      5,371      100.00
*/

br DIRECTORIO SECUENCIA_P SECUENCIA_ENCUESTA Firm_ID Labour_costs total_workers Formality ///
                   P1633 intensive_margin_RUT P1055 intensive_margin_CC


*EXTENSIVE MARGIN

*****> following RUT criteria

tab total_workers if P1633==2 & ID[_n]!=ID[_n+1]
/*

      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     52,773       83.30       83.30
          2 |      7,364       11.62       94.92
          3 |      2,051        3.24       98.16
          4 |        698        1.10       99.26
          5 |        270        0.43       99.69
          6 |        101        0.16       99.85
          7 |         57        0.09       99.94
          8 |         24        0.04       99.98
          9 |          9        0.01       99.99
         10 |          6        0.01      100.00
------------+-----------------------------------
      Total |     63,353      100.00
*/

*******> Following Camara de comercio criteria

tab total_workers if P1055==2 & ID[_n]!=ID[_n+1]
/*
      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     61,540       82.30       82.30
          2 |      8,952       11.97       94.27
          3 |      2,671        3.57       97.84
          4 |        928        1.24       99.08
          5 |        376        0.50       99.58
          6 |        156        0.21       99.79
          7 |         92        0.12       99.91
          8 |         33        0.04       99.96
          9 |         20        0.03       99.99
         10 |         11        0.01      100.00
------------+-----------------------------------
      Total |     74,779      100.00
*/


**Panel A. Extensive margin

graph bar if P1055==2, over(total_workers) bargap(5) ytitle(Share of informals firms) title(Figure 2D) subtitle(Panel A. Extensive margin) /// 
                       note("source: graph made using Micronegocios dataset 2019 and RUT as informality criteria" ///
		                    " We use a different definition of informal worker from that of Ulyssea 2018, that is to say a worker " ///
							"who does not receive healt/retirement contribution") ///
					   legend(on title(Firm Size) subtitle((number of employees))) 
					   clegend(on)

*Panel B. Intensive margin

*****> Following RUT criteria
replace intensive_margin_RUT= intensive_margin_RUT+1 if intensive_margin_RUT!=.								
graph bar if P1633==1, over(intensive_margin_RUT) ytitle(Share of informal workers) title(FIGURE 2C) subtitle(Panel B. Intensive margin) ///
                                           note("source: graph made using Micronegocios dataset 2019 and RUT as informality criteria" ///
										   " We use a different definition of informal worker from that of Ulyssea 2018, that is to say a worker" ///
										   "who does not receive healt/retirement contribution") ///
										   legend(on title(Firm size) subtitle((number of employees)))

******> Following Camara de comercio criteria
replace intensive_margin_CC= intensive_margin_CC+1 if intensive_margin_CC!=.								
graph bar if P1055==1, over(intensive_margin_CC) ytitle(Share of informal workers) title(FIGURE 2D) subtitle(Panel B. Intensive margin) ///
                                           note("source: graph made using Micronegocios dataset 2019 and CC as informality criteria" ///
										   " We use a different definition of informal worker from that of Ulyssea 2018, that is to say a worker" ///
										   "who does not receive healt/retirement contribution") ///
										   legend(on title(Firm size) subtitle((number of employees)))
										   

 ***********************************SECTION 4 (still working!!)***********************************
 
              *CALCULATION OF THE 16 MOMENTS
			  
*****> fOLLOWING RUT (P1633) criteria

* i) MOMENT1 GROUP (Informality share among)

      *calculation of variable "Skills"
	  
      tab p6210 if ID[_n]!=ID[_n+1], m
/*
�cu�l es el nivel educativo |
 m�s alto alcanzado por ... |
  Y el �ltimo a�o o grado a |      Freq.     Percent        Cum.
----------------------------+-----------------------------------
                    Ninguno |      4,240        4.88        4.88
                 Preescolar |          5        0.01        4.88
  B�sica primaria (1o - 5o) |     24,355       28.00       32.89
B�sica secundaria (6o - 9o) |     13,052       15.01       47.89
          Media (10o - 13o) |     26,164       30.08       77.98
   Superior o universitaria |     17,930       20.62       98.59
        No sabe, no informa |         10        0.01       98.61
                          . |      1,213        1.39      100.00
----------------------------+-----------------------------------
                      Total |     86,969      100.00
*/
      gen Skills= (p6210==5|p6210==6)
	  
      replace Skills=. if p6210==.
	  
      lab var Skills "Entrepreneurs skills"
	  
      lab def Skills 1 "High-skill" 0 "Low-skill"
	  
      lab values Skills Skills
	  
      tab Skills if ID[_n]!=ID[_n+1]
/*
    Entrepreneurs skills |      Freq.     Percent        Cum.
-------------------------+-----------------------------------
 Low-skill entrepreneurs |     41,662       48.58       48.58
High-skill entrepreneurs |     44,094       51.42      100.00
-------------------------+-----------------------------------
                   Total |     85,756      100.00
*/

graph bar if ID[_n]!=ID[_n+1], over(Skills) blabel(bar) ytitle(Percentage of Skills) by(, title(Entrepreneurs Skills) subtitle(RUT criteria) ///
                               note("Source: Graph made using RUT (P1633) as informality criteria." " Si (formal firms) No (Informal firms)")) by(P1633)

graph export Entrepreneus_skills_RUT.png, width(600) height(450) replace

graph bar if ID[_n]!=ID[_n+1], over(Skills) blabel(bar) ytitle(Percentage of Skills) by(, title(Entrepreneurs Skills) subtitle(Camara de comercio criteria)  ///
                              note("Source: Graph made using Camara de comercio (P1055) as informality criteria." " Si (formal firms) No (Informal firms)")) by(P1055)
							  
graph export Entrepreneus_skills_CC.png, width(600) height(450) replace


	  tab Skills P1633 if ID[_n]!=ID[_n+1], row 
/*
           |     �El negocio o
           |   actividad  tiene
           |    Registro �nico
Entreprene |   Tributario (RUT)?
urs skills |        S�         No |     Total
-----------+----------------------+----------
 Low-skill |     7,061     34,601 |    41,662 
           |     16.95      83.05 |    100.00 
-----------+----------------------+----------
High-skill |    16,085     28,009 |    44,094 
           |     36.48      63.52 |    100.00 
-----------+----------------------+----------
     Total |    23,146     62,610 |    85,756 
           |     26.99      73.01 |    100.00 
*/
	  
	  *Total employees ( workers + entrepreneurs) in EMICRON
	  
	  total total_workers if ID[_n]!=ID[_n+1]
	  
      /*Total estimation                  Number of obs   =     86,969

---------------------------------------------------------------
              |      Total   Std. Err.     [95% Conf. Interval]
--------------+------------------------------------------------
total_workers |     121520   279.2517      120972.7    122067.3
---------------------------------------------------------------
*/
	  total total_workers if ID[_n]!=ID[_n+1] & P1633==2
	  
	  /*Total estimation                  Number of obs   =     63,353

---------------------------------------------------------------
              |      Total   Std. Err.     [95% Conf. Interval]
--------------+------------------------------------------------
total_workers |      79134   170.4537      78799.91    79468.09
---------------------------------------------------------------
*/
      display (79134 + 13839)/121520
	 *percent= 0.76508394: 76% workers are present in informal sector (following RUT criteria)


	
* ii) MOMENT2 GROUP (Overall share of informal firms and by firm size)
     
	 bysort P1633: tab total_workers
	 
	 /*P1633 = No
      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     52,773       83.30       83.30
          2 |      7,364       11.62       94.92
          3 |      2,051        3.24       98.16
          4 |        698        1.10       99.26
          5 |        270        0.43       99.69
          6 |        101        0.16       99.85
          7 |         57        0.09       99.94
          8 |         24        0.04       99.98
          9 |          9        0.01       99.99
         10 |          6        0.01      100.00
------------+-----------------------------------
      Total |     63,353      100.00
*/
	 gen Moment2 = 1 if P1633==2 & total_workers==1
	 
	 replace Moment2 = 2 if P1633==2 & total_workers>1 & total_workers<=3
	 
	 replace Moment2 = 3 if P1633==2 & total_workers>=4 & total_workers<=10
	 
	 lab var Moment2 "Group of Moment2"
	 
	 lab def Moment2 1 "[1-2[" 2 "[2-10]" 3 "[4-10]"
	 
	 lab values Moment2 Moment2
	 
	 tab Moment2 if ID[_n]!=ID[_n+1]
	 
	 /*
    Moment2 |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     52,773       83.30       83.30
          2 |      9,415       14.86       98.16
          3 |      1,165        1.84      100.00
------------+-----------------------------------
      Total |     63,353      100.00
*/

* iii) MOMENT3 GROUP ( Average share of informal workers within formal firms with 1-5 employees)

tab intensive_margin_RUT total_workers if Firm_ID[_n]!=Firm_ID[_n+1]

/*
intensive_ |                                  Total workers in firm last month
margin_RUT |         2          3          4          5          6          7          8          9         10 |     Total
-----------+---------------------------------------------------------------------------------------------------+----------
         1 |     4,137        163         85         43         24         16          7          6          4 |     4,485 
         2 |         0      1,677         72         17          9          5          7          5          0 |     1,792 
         3 |         0          0        716         32          6          3          0          3          1 |       761 
         4 |         0          0          0        329         16          5          1          2          2 |       355 
         5 |         0          0          0          0        169          6          5          0          2 |       182 
         6 |         0          0          0          0          0        104          5          4          0 |       113 
         7 |         0          0          0          0          0          0         42          0          1 |        43 
         8 |         0          0          0          0          0          0          0         21          3 |        24 
         9 |         0          0          0          0          0          0          0          0         13 |        13 
-----------+---------------------------------------------------------------------------------------------------+----------
     Total |     4,137      1,840        873        421        224        139         67         41         26 |     7,768 
*/
gen size= (total_workers<6)

tab size if ID[_n]!= ID[_n+1]

/*
    Moment3 |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        897        1.03        1.03
          1 |     86,072       98.97      100.00
------------+-----------------------------------
      Total |     86,969      100.00
*/


		   
* iv) MOMENT4 GROUP (The share informal firms with less than 2 employees & less than 5 employees)
/*
	 P1633 = No
      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     52,773       83.30       83.30
          2 |      7,364       11.62       94.92     <= 2 employees: 94% firms less than 2 employees  
          3 |      2,051        3.24       98.16
          4 |        698        1.10       99.26
          5 |        270        0.43       99.69     <= 5 employees: 99% firms less than 5 employees
          6 |        101        0.16       99.85
          7 |         57        0.09       99.94
          8 |         24        0.04       99.98
          9 |          9        0.01       99.99
         10 |          6        0.01      100.00
------------+-----------------------------------
      Total |     63,353      100.00
*/

* v) MOMENT5 GROUP (The share of formal firms with 5, 5-10, 11-20, 21-50 & 50 to +inf)

      bysort P1633: tab total_workers
	  
	  /* P1633==Si
      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     14,357       60.79       60.79
          2 |      4,747       20.10       80.89
          3 |      2,211        9.36       90.26
          4 |      1,060        4.49       94.75
          5 |        541        2.29       97.04
          6 |        305        1.29       98.33
          7 |        185        0.78       99.11
          8 |         98        0.41       99.53
          9 |         72        0.30       99.83
         10 |         40        0.17      100.00
------------+-----------------------------------
      Total |     23,616      100.00
*/

        gen Moment5 = 1 if P1633==1 & total_workers<=5
		
		replace Moment5 = 2 if P1633==1 & total_workers>5 & total_workers<=10
		
		lab var Moment5 "Group of Moment5"
		
		lab def Moment5 1 "[1-5[" 2 "[6-10["
		
		lab values Moment5 Moment5
		
		tab Moment5 if ID[_n]!=ID[_n+1]

**********> Following Camara de commercio (P1055)

*Moment1 group 
   
   *Entrepreneurs skills

   
tab Skills P1633 if ID[_n]!=ID[_n+1] , row

/*
           |     �El negocio o
           |   actividad  tiene
           |    Registro �nico
Entreprene |   Tributario (RUT)?
urs skills |        S�         No |     Total
-----------+----------------------+----------
 Low-skill |     7,061     34,601 |    41,662 
           |     16.95      83.05 |    100.00 
-----------+----------------------+----------
High-skill |    16,085     28,009 |    44,094 
           |     36.48      63.52 |    100.00 
-----------+----------------------+----------
     Total |    23,146     62,610 |    85,756 
           |     26.99      73.01 |    100.00 
*/

tab Skills P1055 if ID[_n]!=ID[_n+1], row

/*
           |     �El negocio o
           |     actividad  se
           | encuentra registrado
           |  en alguna C�mara de
Entreprene |       Comercio?
urs skills |        S�         No |     Total
-----------+----------------------+----------
 Low-skill |     3,602     38,060 |    41,662 
           |      8.65      91.35 |    100.00 
-----------+----------------------+----------
High-skill |     8,295     35,799 |    44,094 
           |     18.81      81.19 |    100.00 
-----------+----------------------+----------
     Total |    11,897     73,859 |    85,756 
           |     13.87      86.13 |    100.00 
*/

 *Share of informals workers
 
total total_workers if ID[_n]!=ID[_n+1] & P1055==2

/*
Total estimation                  Number of obs   =     74,779

---------------------------------------------------------------
              |      Total   Std. Err.     [95% Conf. Interval]
--------------+------------------------------------------------
total_workers |      95183   198.5879      94793.77    95572.23
---------------------------------------------------------------
*/
 display (9896 + 95183)/121520

 *percent= 0.864705 86% workers are present in informal sector (following camara de comercio criteria)


*Moment2 group

bysort P1055: tab total_workers

/*P1055 = No

      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     61,540       82.30       82.30
          2 |      8,952       11.97       94.27 
          3 |      2,671        3.57       97.84
          4 |        928        1.24       99.08
          5 |        376        0.50       99.58 
          6 |        156        0.21       99.79
          7 |         92        0.12       99.91
          8 |         33        0.04       99.96
          9 |         20        0.03       99.99
         10 |         11        0.01      100.00
------------+-----------------------------------
      Total |     74,779      100.00
*/

     gen Moment2b = 1 if P1055==2 & total_workers==1
	 
	 replace Moment2b = 2 if P1055==2 & total_workers>1 & total_workers<=3
	 
	 replace Moment2b = 3 if P1055==2 & total_workers>=4 & total_workers<=10
	 
	 lab var Moment2b "Group of Moment2: Camara de comercio criteria"
	 
	 lab def Moment2b 1 "[1-2[" 2 "[2-3]" 3 "[4-10]"
	 
	 lab values Moment2b Moment2b
	 
	 tab Moment2b ID[_n]!=ID[_n+1]
	 /*
   Group of |
   Moment2: |
  Camara de |
   comercio |
   criteria |      Freq.     Percent        Cum.
------------+-----------------------------------
      [1-2[ |     61,540       82.30       82.30
      [2-3] |     11,623       15.54       97.84
     [4-10] |      1,616        2.16      100.00
------------+-----------------------------------
      Total |     74,779      100.00
*/

*Moment3

tab intensive_margin_CC total_workers if Firm_ID[_n]!=Firm_ID[_n+1]

/*
intensive_ |                                  Total workers in firm last month
 margin_CC |         2          3          4          5          6          7          8          9         10 |     Total
-----------+---------------------------------------------------------------------------------------------------+----------
         1 |     2,713        142         78         40         21         17          5          6          4 |     3,026 
         2 |         0      1,133         62         16          8          5          7          5          0 |     1,236 
         3 |         0          0        519         29          6          3          0          3          1 |       561 
         4 |         0          0          0        244         13          5          1          1          2 |       266 
         5 |         0          0          0          0        128          4          5          0          1 |       138 
         6 |         0          0          0          0          0         73          4          4          0 |        81 
         7 |         0          0          0          0          0          0         37          0          1 |        38 
         8 |         0          0          0          0          0          0          0         13          3 |        16 
         9 |         0          0          0          0          0          0          0          0          9 |         9 
-----------+---------------------------------------------------------------------------------------------------+----------
     Total |     2,713      1,275        659        329        176        107         59         32         21 |     5,371 
*/



*Moment 4

/*      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     61,540       82.30       82.30
          2 |      8,952       11.97       94.27 <= 2 employees: 94% firms less than 2 employees
          3 |      2,671        3.57       97.84
          4 |        928        1.24       99.08
          5 |        376        0.50       99.58 <= 5 employees: 99% firms less than 5 employees
          6 |        156        0.21       99.79
          7 |         92        0.12       99.91
          8 |         33        0.04       99.96
          9 |         20        0.03       99.99
         10 |         11        0.01      100.00
------------+-----------------------------------
      Total |     74,779      100.00
*/

*Moment 5

      bysort P1055: tab total_workers
/*-> P1055 = S�

      Total |
 workers in |
  firm last |
      month |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      5,590       45.86       45.86
          2 |      3,159       25.91       71.77
          3 |      1,591       13.05       84.82
          4 |        830        6.81       91.63
          5 |        435        3.57       95.20
          6 |        250        2.05       97.25
          7 |        150        1.23       98.48
          8 |         89        0.73       99.21
          9 |         61        0.50       99.71
         10 |         35        0.29      100.00
------------+-----------------------------------
      Total |     12,190      100.00
*/

        gen Moment5b = 1 if P1055==1 & total_workers==1
		
		replace Moment5b = 2 if P1055==1 & total_workers==2
		
		replace Moment5b = 3 if P1055==1 & total_workers>2 & total_workers<=10
		
		lab var Moment5b "Group of Moment5: camara de comercio criteria"
		
		lab def Moment5b 1 "[1-2[" 2 "[2-3[" 3 "[3-10]"
		
		lab values Moment5b Moment5b
		
		tab Moment5b if ID[_n]!=ID[_n+1]
		/*
   Group of |
   Moment5: |
  camara de |
   comercio |
   criteria |      Freq.     Percent        Cum.
------------+-----------------------------------
      [1-2[ |      5,590       45.86       45.86
      [2-3[ |      3,159       25.91       71.77
     [3-10] |      3,441       28.23      100.00
------------+-----------------------------------
      Total |     12,190      100.00
*/

* Figure 4 of Ulyssea

gen Firm_size=1 if total_workers==1

replace Firm_size=2 if total_workers==2

replace Firm_size=3 if total_workers>2 & total_workers<=10

lab var Firm_size "Group by firm's size"

lab def Firm_size 1 "[1-2[" 2 "[2-3[" 3 "[3-10]"

lab values Firm_size Firm_size

tab Firm_size if ID[_n]!=ID[_n+1]

*Graph
*RUT Criteria
graph bar if ID[_n]!=ID[_n+1] & P1633==1, over(Skills, label(angle(forty_five))) blabel(bar) ytitle(Share of entrepreneurs skills) ///
                                          by(, title(Share of High Skill Entrepreneurs per Firm Size) note(Source: Graph made using EMICRON 2019 & RUT as informality criteria)) ///
										  by(Firm_size)
										  
graph bar if ID[_n]!=ID[_n+1] & P1633==2, over(Skills, label(angle(forty_five))) blabel(bar) ytitle(Share of entrepreneurs skills) ///
                                          by(, title(Share of High Skill Entrepreneurs per Firm Size) note(Source: Graph made using EMICRON 2019 & RUT as informality criteria)) ///
										  by(Firm_size)


graph bar if ID[_n]!=ID[_n+1] & P1055==1, over(Skills, label(angle(forty_five))) blabel(bar) ytitle(Share of entrepreneurs skills) ///
                                          by(, title(Share of High Skill Entrepreneurs per Firm Size) note(Source: Graph made using EMICRON 2019 & CC as informality criteria)) ///
										  by(Firm_size)
										  
graph bar if ID[_n]!=ID[_n+1] & P1055==2, over(Skills, label(angle(forty_five))) blabel(bar) ytitle(Share of entrepreneurs skills) ///
                                          by(, title(Share of High Skill Entrepreneurs per Firm Size) note(Source: Graph made using EMICRON 2019 & CC as informality criteria)) ///
										  by(Firm_size)
										  

										  
*MEANS TESTS ON WAGES ACROSS EXTENSIVE AND INTENSIVE MARGINS

* Generate a new variable for worker's formality criteria (minimum wage= 828,116 pesos)

gen new_var= (P3079/828116) if P3079>0

gen minimum_wage=1 if new_var>1 & new_var!=.

replace minimum_wage=0 if new_var<1 & new_var!=.

lab var minimum_wage "worker's formality following minimum wage"
lab def minimum_wage 1 "formal workers" 0 "informal workers"
lab values minimum_wage minimum_wage
tab minimum_wage


global formality Formality minimum_wage


foreach var in $formality {

     *means tests on wages (Extensive margin)
ttest P3079 if P3079>0, by(P1055)

     *means tests on wages (Intensive margin)
ttest P3079 if P3079>0 & P1055==1, by(`var')
           }
		   
Resultats

-EXTENSIVE MARGIN

Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. Err.   Std. Dev.   [95% Conf. Interval]
---------+--------------------------------------------------------------------
      S� |  10,144    838834.1    5469.557    550879.7    828112.6    849555.5
      No |  10,111    599261.9    4394.567    441888.9    590647.6    607876.1
---------+--------------------------------------------------------------------
combined |  20,255    719243.1    3608.818    513607.2    712169.5    726316.7
---------+--------------------------------------------------------------------
    diff |            239572.2    7018.766                225814.9    253329.6
------------------------------------------------------------------------------
    diff = mean(S�) - mean(No)                                    t =  34.1331
Ho: diff = 0                                     degrees of freedom =    20253

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 1.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 0.0000

 -SOCIAL PROTECTION

 Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. Err.   Std. Dev.   [95% Conf. Interval]
---------+--------------------------------------------------------------------
 Infomal |   6,299    767921.8    7335.906    582223.3    753540.9    782302.7
Formal w |   3,845    955004.8    7626.174    472884.3      940053    969956.5
---------+--------------------------------------------------------------------
combined |  10,144    838834.1    5469.557    550879.7    828112.6    849555.5
---------+--------------------------------------------------------------------
    diff |             -187083    11120.44               -208881.3   -165284.7
------------------------------------------------------------------------------
    diff = mean(Infomal) - mean(Formal w)                         t = -16.8233
Ho: diff = 0                                     degrees of freedom =    10142

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 1.0000

 
 -MINIMUM WAGE CRITERIA
 
Two-sample t test with equal variances
------------------------------------------------------------------------------
   Group |     Obs        Mean    Std. Err.   Std. Dev.   [95% Conf. Interval]
---------+--------------------------------------------------------------------
informal |   4,797    587376.2    3056.753    211711.9    581383.6    593368.9
formal w |   3,881     1153690    12017.96    748690.7     1130128     1177252
---------+--------------------------------------------------------------------
combined |   8,678    840644.7    6393.394    595581.6    828112.1    853177.3
---------+--------------------------------------------------------------------
    diff |           -566313.7    11331.28               -588525.7   -544101.7
------------------------------------------------------------------------------
    diff = mean(informal) - mean(formal w)                        t = -49.9779
Ho: diff = 0                                     degrees of freedom =     8676

    Ha: diff < 0                 Ha: diff != 0                 Ha: diff > 0
 Pr(T < t) = 0.0000         Pr(|T| > |t|) = 0.0000          Pr(T > t) = 1.0000

. 
