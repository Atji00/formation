	 
*ATJI Cheick
*MASTER ECONOMIE APPLIQUEE
*UNIVERSITE PARIS CITE
*2021/2022


*Subject:	* EFFETS DES CONDITIONS CLIMATIQUES SUR L'ETAT DE SANTE DES ENFANTS*
			* DE MOINS DE 5 ANS DANS LES PAYS A FAIBLES REVENUS: CAS DU MALI                      *
						***************************


********************************************************************************
	               *SECTION 1* CHARGEMENT DES DONNEES
			
			
 *Nettoyage de la base de données et optimisation de la memoire de traitement
   
 		qui {
		clear *						
		set mem 512m
		set maxvar 8000
		set mat 800					
		set more off, perma			
		}
        estimates clear
		cap drop _all

*Macros de chemins d'accès aux différentes sources de données 

glo path /Users/pc/Downloads/Mémoire Master 2/Données // chemin d'accès aux bases de données finales

glo path1 /Users/pc/Downloads/Mémoire Master 2/Données/Aidata Geoquery // chemin d'accès aux données climats 
																	  //provenant de AidData 
																	  
glo path2 /Users/pc/Downloads/Mémoire Master 2/Données/Geospacial covariates 1996-2018 // chemin d'accès aux 
																				//données climats provenant du DHS
																				
glo path3 /Users/pc/Downloads/Mémoire Master 2/Données/DHS 1996-2018 // chemin d'accès aux modules_enfants DHS de 1996 à 2018

glo path4 /Users/pc/Downloads/Mémoire Master 2/Données/module household // chemin d'accès aux modules_ménages DHS de 1996 à 2018

glo path5 /Users/pc/Downloads/Mémoire Master 2/Données/Prix agriculture // chemin d'accès prix céréales à la consommation 

glo time 2001 2006 2012 2018 // macro pour les vagues


                                 *************
                                 *Section 1.1*                          
                                 *************					
*       Importation des données de Pluviométries et Températures de 1981 à 2017 
*			                provenant de AidData            
															  	
 Source: AidData GeoQuery                                                             
         http://geo.aiddata.org/query/#!/status/627d0769449c1b035c274e02              
		 
 Authors: Goodman, S., BenYishay, A., Lv, Z., & Runfola, D. (2019).
          GeoQuery: Integrating HPC systems and public web-based geospatial data tools.
		  Computers & Geosciences, 122, 103-112.
 
 cd "${path1}"
 glo climat climat_cercles climat_regions
 
 foreach v in $climat {
 
 insheet using `v'.csv
 
 sort shapeid
 
 glo vars udel_precip_v501_sum@min udel_precip_v501_sum@mean udel_precip_v501_sum@max ///
		  udel_air_temp_v501_mean@min udel_air_temp_v501_mean@mean udel_air_temp_v501_mean@max
 
 reshape long $vars, i(shapeid) j(time)
 
 glo oldvars udel_precip_v501_summin udel_precip_v501_summean udel_precip_v501_summax ///
	        udel_air_temp_v501_meanmin udel_air_temp_v501_meanmean udel_air_temp_v501_meanmax
			
 glo newvars precipitation_min precipitation_mean precipitation_max /// 
			 air_temp_min air_temp_mean air_temp_max

 rename ($oldvars) ($newvars)
 gen dhsyear = time
 order shapeid shapename time
 sort  shapename time
 encode shapename, gen(zones)
 recode zones (1=8 "Bamako") (2=7 "Gao") (3=1 "Kayes") (4=9 "Kidal") (5=2 "Koulikoro") ///
        (6=5 "Mopti") (7=4 "Segou") (8=3 "Sikasso") (9=6 "Tombouctou"), gen(v024)
 save `v'.dta, replace
 clear
 }

*Création de valeurs retardées dans le temps (t-1) et (t-2) pour les variables climats
*   utlisés dans les régresions en vue de prédire les outcomes en (t)

use climat_regions.dta

foreach v in precipitation_mean air_temp_mean {
		forvalues i = 1/2 {  
bysort zones: gen L`i'_`v'= `v'[_n-`i']
lab var L`i'_`v' "`v' en (t-`i')"
  }
}
sort zones dhsyear
save, replace
clear

                                   *************
                                   *Section 1.2*
								   *************
* Importation de données "covariables géospaciales" sur les températures et les 
*   épisodes de sécheresse au niveau des clusters des DHS de 1996 à 2018

Source: The DHS program: Spatial Data Repository
	
	  https://spatialdata.dhsprogram.com/covariates/

Authors: Mayala, Benjamin, Thomas D. Fish, David Eitelberg, and Trinadh Dontamsetti. 2018. The DHS
Program Geospatial Covariate Datasets Manual (Second Edition). Rockville, Maryland, USA: 
ICF.

cd "${path2}"
cap program drop prog1

program define prog1

	args i j k l m
	
	foreach t in `i' `j' `k' `l' `m' {
	
	insheet using `t'.csv 
	
    keep gps_dataset dhsyear dhsclust drought_episodes irrigation temperature_*
	
	sort dhsclust
	
	gen temp_mean= (temperature_april + temperature_august + temperature_december + ///
	                temperature_february + temperature_january + temperature_july + ///
					temperature_june + temperature_march + temperature_may + ///
				    temperature_november + temperature_october + temperature_september)/ 12
	
	lab var temp_mean "temperatures moyennes mensuelles au niveau des clusters"
	
	drop temperature_*
	
	save `t'.dta, replace 
	clear
	}
end

prog1 1996 $time

use 1996.dta

foreach i in $time {
	append using `i'.dta
	}

save temperature_cluster.dta, replace

*Création de valeurs retardées dans le temps (t-1) et (t-2) pour les variables
* climats utlisés dans les régresions en vue de prédire les outcomes en (t)
sort dhsclust dhsyear
foreach v in drought_episodes irrigation temp_mean {
		forvalues i = 1/2 {  
bysort dhsclust: gen L`i'_`v'= `v'[_n-`i']
lab var L`i'_`v' "`v' en (t-`i')"
  }
}
sort dhsclust dhsyear
save, replace
clear
	
								*************
								*Section 1.3*
								*************
*           Importation et fusion des données DHS de 1996 à 2018

Source: The DHS program
Authors: USAID

	https://dhsprogram.com/data/dataset_admin/index.cfm 
			login: atjicheick@gmail.com
			mdp: Oumaratji2004.

cd "${path3}"

foreach t in 1996 2001 2006 2012 2018{

  use `t'.dta
  svyset [pweight=v005]
  keep caseid v001 v002 v003 v005 v010 v012 v013 v024 v025 v106 ///
	  v115 v123 v124 v125 v130 v131 v137 v136 v212 v445 b1 b4 b5 ///
	  v149 v113 b6 b8 m18 m19 h3 h2 h4 h5 h6 h7 h8 h9 h0 hw1 hw3 hw2 ///
	  v411 v414f v414g v414h
	  foreach var in v411 v414f v414g v414h {
					replace `var'=. if `var'==8
   }
   gen dhsyear = `t'
   gen dhsclust = v001
   
  sort dhsclust dhsyear  
  save dhs_`t'.dta, replace
  clear
 }
 
 use dhs_1996
 
 foreach t in $time {
 
	append using dhs_`t'.dta
 }
 
 tab dhsyear
 
* Traitements des valeurs manquantes/aberrantes et extremes "missings/NA

*Type de source d'eau pour consommation
recode v113 (11 12 51 61=1 "eau courante domicile/public") ///
			(21 22 23 31=2 "puits domicile/public") ///
			(32 33 34 41=3 "rivière/lac/pluie") ///
			(13 42 43 44 62 71 96 97=4 "Autres sources"), gen(Source_eau)
			
*Temps pour se rendre à une source d'eau
replace v115=0 if v115==996
recode v115 (0=1 "sur place") (1/5=2 "5h")(6/10=3 "6 à 10h") ///
			(11/24=4 "1 jour")(25/48=5 "2 jours")(49/1000=6 "plusieurs jours"), ///
			 gen(temps_source)

*Niveau d'education des mères
recode v149 (0=1 "No education") (1 2=2 "primary") (3 4=3 "secondaire") (5=.), gen(Education)
lab var Education "Niveau d'education des mères"

*Moyens de transports
foreach v in v123 v124 v125 {
	replace `v'=. if `v'==7
}

* Nombre d'enfants de 5 ans et moins
replace v137=. if v137==0

*Indice de Masse corporelle pour les répondants
replace v445=. if v445==9998

*Taille des enfants "size"
replace m18=. if m18==8

*Poids des enfants à la naissance
replace m19=. if m19>=6100

*Recodage des valeurs non disponibles 'NA'
recode h* (8=.)

*Mortalité infantile

recode b5(0=1 "décédé") (1=0 "vivant"), gen(mortalite)

*groupe d'âges

recode hw1 (0/12 = 1 "0-1ans") (13/24= 2 "1-2ans") (25/60=3 "2-5ans"), gen(Groupe)

*CALCUL DES INDICATEURS ANTHROPOMETRIQUES

*--------Section Poids------------*
* Poids "hw2 kg" 
gen Poids= hw2/10
lab var Poids "Poids réel en kg"
sum Poids, detail
return list
replace Poids=. if Poids>=r(p99)

* calcul z-score du rapport Poids/âge par groupe d'âges
gen Poids_âges = Poids/hw1 // avec "hw1" âges en mois		
sum Poids_âges, detail 
return list
gen PAZ = (Poids_âges - r(p50))/r(sd)
lab var PAZ "Poids/âges Z-score"

*-------Section Taille------------*
*Taille "hw3 cm"
gen Tailles= hw3/10
lab var Tailles "taille réelle en cm"
sum Tailles, detail
replace Tailles=. if Tailles>127

* calcul z-score du rapport Poids/âge
gen Tailles_âges = Tailles/hw1
		
sum Tailles_âges, detail 
return list
gen TAZ = (Tailles_âges - r(p50))/r(sd)
lab var TAZ " Tailles/Ages Z-scores"

*-----------Section IMC------------*
*Rapport "Poids/Taille" kg/cm
gen IMC= Poids/Tailles
lab var IMC "Indice masse Corporelle en kg/cm"
sum IMC, detail 
return list
gen PTZ = (IMC - r(p50))/r(sd)
lab var PTZ "Poids/Tailles Z-scores"

*Remplacement des Z-scores <-5 ou >5
foreach var in PAZ TAZ PTZ {
replace `var'=. if `var'<-5 | `var'>5
}
save DHS.dta, replace
clear
			
							 *************
							 *Section 1.4*
							 *************
 
 *Fusion des données DHS avec les données climatiques issues des covariables géospaciales
  cd "${path3}"
  use DHS.dta
  sort dhsclust dhsyear
  merge m:1 dhsclust dhsyear using "${path2}/temperature_cluster.dta", ///
			keepusing(drought_episodes irrigation temp_mean L1_drought_episodes ///
					  L2_drought_episodes L1_irrigation L2_irrigation L1_temp_mean ///
					  L2_temp_mean)
	
  cd "${path}"
  save DHS_covariables.dta, replace
  clear
 
 *Fusion des données DHS avec les données climatiques issues de Aiddata Geoquery
 cd "${path3}"
 use DHS.dta
 sort v024 dhsyear
 merge m:1 v024 dhsyear using "${path1}/climat_regions.dta", ///
			keepusing(precipitation_min precipitation_min precipitation_mean ///
					  precipitation_min-precipitation_max air_temp_min air_temp_mean ///
					  air_temp_max L1_precipitation_mean L2_precipitation_mean ///
					  L1_air_temp_mean L2_air_temp_mean) keep(match)

 cd "${path}"
 save DHS_Aiddata.dta, replace
 clear
********************************************************************************
			    *SECTION 2* ANALYSES STATISTIQUES ET ECONOMETRIQUES

/*Statistiques et graphs sur l'évolution de la pluviométrie et la température
           auprès des différentes régions du Mali  
*/
cd "${path1}"
use climat_regions.dta

**Evolution de la pluviométrie
twoway (spike precipitation_mean time) (line precipitation_mean time), ///
	   ytitle(Précipitations moyennes en millimètres de pluies par an) ///
	   ylabel(, angle(forty_five)) xtitle(Année) xlabel(, angle(forty_five)) ///
	   by(, title(Evolution des précipitations de 1980 à 2017) subtitle(Régions du Mali) ///
	   note(Source: AidData Geoquery (Calcul de l'auteur))) by(zones)

graph export Pluviométrie_regions.png, as(png) replace


**Evolution des températures
twoway (spike air_temp_mean time) (line air_temp_mean time), ///
	   ytitle(Températures moyennes en °C par an) ylabel(, angle(zero)) ///
	   xtitle(Année) xlabel(, angle(forty_five)) by(, title(Evolution des températures de 1980 à 2017) ///
	   subtitle(Régions du Mali) note(Source: AidData Geoquery (Calcul de l'auteur))) by(zones)

graph export Temperatures_regions.png, as(png) replace
clear
						      *************
						      *Section 2.1*
						      *************
*		Analyses statistiques et économétriques avec DHS_covariables
cd "${path}"
use DHS_covariables.dta

*recodage des valeurs NA dans les variables climatiques
glo climats drought_episodes irrigation temp_mean L1_drought_episodes ///
    L2_drought_episodes L1_irrigation L2_irrigation L1_temp_mean L2_temp_mean
	
foreach v in $climats {
		replace `v'=. if `v'==-9999
}
 
*Graphique sur la répartition des enfants par vague de DHS
graph hbar (count), over(b4, label(labcolor("navy"))) over(dhsyear, label(labcolor("dknavy"))) ///
					blabel(total, size(medium) color(white) position(center)) ///
				    ytitle(Nombres d'enfants en milliers) title(Taille des échantillons par vague de DHS) ///
					subtitle(Enfants de moins de 5 ans) note(Source: DHS/program (calcul de l'auteur)) ///
					legend(off)
graph export Echantillon.png, as(png) replace

 
*Graphique sur l'évolution des épisodes de sécheresses
 graph pie, over(drought_episodes) plabel(_all percent, color(white)) /// 
						by(, title(Episodes de sécheresse et proportion d'enfants exposés) ///
			subtitle(Pourcentage d'enfants de moins de 5 ans affectés, color(navy)) /// 
			note(Source: DHS/Covariables géospaciales (calcul de l'auteur))) by(, legend(on)) ///
			legend(order(1 "Faible" 2 "Moyenne" 4 "Elevée" 5 "Très élevée" 7 "Extrême") ///
			title(Intensité des épisodes de sécheresse)) by(dhsyear)
graph export Secheresse.png, as(png) replace


*Graphique sur la variation de températures entre différents clusters
twoway (line temp_mean dhsclust), ytitle(Moyennes mensuelles par DHS) xtitle(Nombre de Clusters) ///
								  by(, title(Variation des températures moyennes entre clusters) ///
								  subtitle(Degré °C) note("Source: DHS/covariables géospaciales (calcul de l'auteur)" ///
								  "Données non disponibles pour l'année 2018")) by(dhsyear)
graph export Temperatures.png, as(png) replace


clear
							*************
							*Section 2.2*
							*************
*		Analyses statistiques et économétriques avec DHS_AidData
clear
cd "${path}"
use DHS_Aiddata.dta

*distribution des incateurs anthropométriques de l'échantillon
graph box PAZ TAZ PTZ [pweight = v005], medtype(marker) ytitle(Z-scores) ///
	  title(Distribution des Z-scores de l'échantillon d'enquête) ///
	  note(Source: DHS (Calcul de l'auteur))
graph export Z_scores_échantillon.png, as(png) replace

*distribution par groupe d'âges
graph box PAZ TAZ PTZ [pweight = v005], over(Groupe) medtype(marker) ///
	  ytitle(Z-scores) title(Distribution des Z-scores par Groupe  d'âges) ///
	  note(Source: DHS (Calcul de l'auteur))

graph export Z-scores_groupes.png, as(png) replace


foreach v in PAZ TAZ PTZ { 

twoway (kdensity `v' if Groupe==1, lcolor(dknavy)) (kdensity `v' if Groupe==2, ///
		lcolor(red)) (kdensity `v' if Groupe==3, lcolor(green)), ytitle(Kernel Density) ///
		xtitle(Z-scores par groupe d'enfants) xline(-2) xline(2) /// 
		title(Distribution des Indicateurs Anthropométriques) subtitle(`v') ///
		note(Source: Enquêtes DHS 1996/2018 (Calcul de l'auteur)) ///
		legend(on order(1 "0-1 ans" 2 "1-2 ans" 3 "2-5 ans"))
graph export Kernels_`v'.png, as(png) replace
}

*création de variables relatives à chaque groupe d'enfants 
tab Groupe, gen(Gr)
glo Gr Gr1 Gr2 Gr3
recode $Gr (0=.)

*Effets de la pluviometrie sur les indicateurs anthropométriques
 
foreach t in $Gr {
		
		reg Poids_âges L1_precipitation_mean L2_precipitation_mean i.v024 ///
			i.dhsyear i.b4 i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg11_Poids_`t'

		reg Tailles_âges L1_precipitation_mean L2_precipitation_mean i.v024 ///
			i.dhsyear i.b4 i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg21_Tailles_`t'

	    reg IMC L1_precipitation_mean L2_precipitation_mean i.v024 i.dhsyear ///
				i.b4 i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg31_IMC_`t'

}

esttab reg11_Poids_Gr1 reg11_Poids_Gr2 reg11_Poids_Gr3 ///
		reg21_Tailles_Gr1 reg21_Tailles_Gr2 reg21_Tailles_Gr3 ///
		reg31_IMC_Gr1 reg31_IMC_Gr2 reg31_IMC_Gr3 using table1.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 


**Effets des températures sur les indicateurs antropométriques

foreach t in $Gr {
		
		reg Poids_âges L1_air_temp_mean L2_air_temp_mean i.v024 i.dhsyear ///
						i.b4 i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg12_Poids_`t'

		reg Tailles_âges L1_air_temp_mean L2_air_temp_mean i.v024 i.dhsyear ///
						i.b4 i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg22_Tailles_`t'

	    reg IMC L1_air_temp_mean L2_air_temp_mean i.v024 i.dhsyear i.b4 ///
				i.Source_eau i.Education [pweight=v005] if `t'==1
						eststo clear
						estimates store reg32_IMC_`t'
}


esttab reg12_Poids_Gr1 reg12_Poids_Gr2 reg12_Poids_Gr3 ///
		reg22_Tailles_Gr1 reg22_Tailles_Gr2 reg22_Tailles_Gr3 ///
		reg32_IMC_Gr1 reg32_IMC_Gr2 reg32_IMC_Gr3 using table2.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 

*Effets des variables climatiques sur la mortalité infantile

*-Effets de la pluviométrie
probit mortalite L1_precipitation_mean L2_precipitation_mean i.v024 ///
			i.dhsyear i.b4 i.Source_eau i.Education [pweight=v005]
						eststo clear
						estimates store reg11
logit mortalite L1_precipitation_mean L2_precipitation_mean i.v024 ///
			i.dhsyear i.b4 i.Source_eau i.Education [pweight=v005]
						eststo clear
						estimates store reg12

*-Effets des températures
probit mortalite L1_air_temp_mean L2_air_temp_mean i.v024 i.dhsyear i.b4 ///
				i.Source_eau i.Education [pweight=v005]
						eststo clear
						estimates store reg21
logit mortalite L1_air_temp_mean L2_air_temp_mean i.v024 i.dhsyear i.b4 ///
				i.Source_eau i.Education [pweight=v005]
						eststo clear
						estimates store reg22

 esttab reg11 reg12 reg21 reg22 using table3.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 
	

*********************************************************************************
*Nouvelle section:

*Importation des données DHS modules des ménages "Household recode"
clear
cd "${path4}"

foreach t in 2006 2012 2018 {
		use `t'.dta
		gen dhsyear = `t'
		rename (hv001 hv002) (v001 v002)
		keep hhid hv000 v001 v002 hv003 hv004 hv005 hv006 hv007 dhsyear ///
			 hv244 hv245 hv246 hv270
		save hh_`t'.dta, replace
		clear
}

use hh_2006.dta
foreach t in 2012 2018 {
	append using hh_`t'.dta
	}
sort dhsyear v001 v002
save household.dta, replace
clear

*Importation des données sur Countrystats Mali "Prix à la consommation des céréales" 
cd "${path5}"
import excel prix_cereales_consommation, firstrow
destring ANNÉE, gen (dhsyear)
encode PRODUIT_LABEL, gen(Cereales)
gen Prix = VALEUR/1000
label var Prix "Prix au Kg"
keep dhsyear Cereales Prix
sort Cereales dhsyear
gen variation_prix = ((Prix[_n] - Prix[_n-1])/ Prix[_n-1])*100
lab var variation_prix "variation des prix céréaliers en %" 
save conso_prix.dta, replace
clear

*Fusion des données ménages et prix avec nos données initiales
cd "${path}"
use DHS_Aiddata.dta
drop _merge
merge m:1 dhsyear v001 v002 using "${path4}/household.dta", ///
			keepusing(hv244 hv245 hv246 hv270)
drop _merge			
merge m:m dhsyear using "${path5}/conso_prix.dta"

*création de deux groupes d'enfants
recode Groupe (1=1 "0-1 ans") (2 3=2 "1-5 ans"), gen(groupe_2)
tab groupe_2, gen(gr)
glo groupe gr1 gr2

*création de la variable Zone_3 pour classer les 9 régions du Mali par pluviometrie
 
recode v024 (1 8 3=1 "pluviométrie élevée") (7 5 6=2 "pluviométrie moyenne") ///
			(2 4 9=3 "pluviométrie faible"), gen(Zones_3)

*Recodage de la variable Wealth index
recode hv270 (1 2=1 "pauvres") (3=2 "moyens") (4 5=3 "riches"), gen(Wealth_index)
 
*création de variables chocs pluviométriques et températures
glo chocs L1_precipitation_mean L2_precipitation_mean ///
		  L1_air_temp_mean L2_air_temp_mean

tab Zones_3, gen(Dummy)
glo dum Dummy1 Dummy2 Dummy3

foreach var in $chocs {
		gen chocP_`var'=0
		gen chocN_`var'=0	
		lab var chocP_`var' "choc positif (+)"
		lab var chocN_`var' "choc négatif (-)"
}		
	
	foreach v in $dum {
		
		foreach var in $chocs {
		sum `var' if `v'==1 
		return list
		replace chocP_`var'= 1 if `var'> r(mean)+2*r(sd)
		replace chocN_`var'= 1 if `var'< r(mean)-2*r(sd)
	}
}


*Changement d'échelle pour la pluviométrie (millimètre en mètre)

foreach var in L1_precipitation_mean L2_precipitation_mean {
			replace `var'=`var'/1000
} 

 
							*REGRESSIONS ECONOMETRIQUES
********************************************************************************
							*Hypothèse 1
 *Effets directs des conditions climatiques
 
 *Effets pluviométries
 
 foreach t in $groupe {
		
		reg Poids_âges L1_precipitation_mean L2_precipitation_mean ///
					   i.Zones i.dhsyear i.b4##i.chocP_L1_precipitation_mean ///
					   i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg11_Poids_`t'

		reg Tailles_âges L1_precipitation_mean L2_precipitation_mean ///
					   i.Zones i.dhsyear i.b4##i.chocP_L1_precipitation_mean ///
					   i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg21_Tailles_`t'

	    reg IMC L1_precipitation_mean L2_precipitation_mean ///
					i.Zones i.dhsyear i.b4##i.chocP_L1_precipitation_mean ///
					i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg31_IMC_`t'
}

esttab Reg11_Poids_cat1 Reg11_Poids_cat2 ///
		Reg21_Tailles_cat1 Reg21_Tailles_cat2 ///
		Reg31_IMC_cat1 Reg31_IMC_cat2 using text1.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 
 
 
**Effets des températures
 
 foreach t in $groupe {
		
		reg Poids_âges L1_air_temp_mean L2_air_temp_mean ///
					   i.Zones i.dhsyear i.b4##i.chocP_L1_air_temp_mean ///
					   i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg12_Poids_`t'

		reg Tailles_âges L1_air_temp_mean L2_air_temp_mean ///
					   i.Zones i.dhsyear i.b4##i.chocP_L1_air_temp_mean ///
					   i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg22_Tailles_`t'

	    reg IMC L1_air_temp_mean L2_air_temp_mean ///
					i.Zones i.dhsyear i.b4##i.chocP_L1_air_temp_mean ///
					i.Source_eau i.Education##i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Reg32_IMC_`t'
}


esttab Reg12_Poids_cat1 Reg12_Poids_cat2 ///
		Reg22_Tailles_cat1 Reg22_Tailles_cat2 ///
		Reg32_IMC_cat1 Reg32_IMC_cat2 using text2.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 

*Effets des variables climatiques sur la mortalité infantile

*-Effets de la pluviométrie
probit mortalite L1_precipitation_mean L2_precipitation_mean i.Zones ///
			i.dhsyear i.b4##i.chocP_L1_precipitation_mean i.Source_eau ///
			i.Education##i.Wealth_index [pweight=v005]
			margins,dydx(*) atmeans
						eststo clear
						estimates store Reg11
logit mortalite L1_precipitation_mean L2_precipitation_mean i.Zones ///
			i.dhsyear i.b4##i.chocP_L1_precipitation_mean i.Source_eau ///
			i.Education##i.Wealth_index [pweight=v005], or
						eststo clear
						estimates store Reg12

*-Effets des températures
probit mortalite L1_air_temp_mean L2_air_temp_mean i.Zones i.dhsyear ///
				 i.b4##i.chocP_L1_air_temp_mean i.Source_eau ///
				 i.Education##i.Wealth_index [pweight=v005]
				 margins,dydx(*) atmeans
						eststo clear
						estimates store Reg21
logit mortalite L1_air_temp_mean L2_air_temp_mean i.Zones i.dhsyear ///
				i.b4##i.chocP_L1_air_temp_mean i.Source_eau ///
				i.Education##i.Wealth_index [pweight=v005], or
						eststo clear
						estimates store Reg22

 esttab Reg11 Reg12 Reg21 Reg22 using text3.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001) 

********************************************************************************
                               *Hypothèse 2*
 *Effets de la variation des prix à la consommation sur l'alimentation des enfants
 
 *Stats sur les allocations des parents pour les produits alimenttaires des enfants
 

 *Stats sur les allocations des parents pour produits laitiers
graph bar [pweight = v005], over(v411, label(labcolor("magenta"))) ///
		  bar(1, fcolor(magenta))ytitle(% Pourcentage d'enfants) ///
		  subtitle(Consommation de produits laitiers) ///
		  note(Source: DHS/calcul de l'auteur)
		  graph save graph1, replace
		  
*Stats sur les allocations des parents pour aliments à base de tubercules
graph bar [pweight = v005], over(v414f, label(labcolor("dknavy"))) ///
		  bar(1, fcolor(dknavy))ytitle(% Pourcentage d'enfants) ///
		  subtitle(Consommation d'aliments à base de tubercules) ///
		  note(Source: DHS/calcul de l'auteur)
		  graph save graph2, replace
		  
*Stats sur les allocations des parents pour oeufs et poissons
graph bar [pweight = v005], over(v414g, label(labcolor("green"))) ///
		  bar(1, fcolor(green))ytitle(% Pourcentage d'enfants) ///
		  subtitle(Consommation d'oeufs et poissons) ///
		  note(Source: DHS/calcul de l'auteur)
		  graph save graph3, replace
		  
*Stats sur les allocations des parents pour viandes
graph bar [pweight = v005], over(v414h, label(labcolor("orange"))) ///
		  bar(1, fcolor(orange))ytitle(% Pourcentage d'enfants) ///
		  subtitle(Consommation de viandes) ///
		  note(Source: DHS/calcul de l'auteur)
		  graph save graph4, replace

gr combine "graph1" "graph2" "graph3" "graph4", saving(mygraph, replace)
		  
 
*évolution des prix à la consommation des céréales entre 2000 et 2015
 clear
 cd "${path5}"
 use conso_prix.dta
 
twoway (line Prix dhsyear if Cereales==1) ///
	   (line Prix dhsyear if Cereales==2) ///
	   (line Prix dhsyear if Cereales==3) ///
	   (line Prix dhsyear if Cereales==4), ///
       ytitle(Prix à la consommation du kg) ylabel(, labels valuelabel) xtitle(Années) /// 
	   xlabel(, labels angle(forty_five) valuelabel) title(Evolution des prix(CFA) à la consommation) ///
	   subtitle(Principales cultures céréalières) ///
	   note("Source: countrystats/Calcul de l'auteur sur les données") /// 
	   legend(on order(1 "Maïs" 2 "Mil" 3 "Riz" 4 "Sorgho"))
graph export prix.png, as(png) replace

 
 *Effets conjoints pluiviometrie et variation de prix
  foreach t in $groupe {
		
		reg Poids_âges variation_prix L1_precipitation_mean L2_precipitation_mean /// 
						i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
					    i.b4 i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regpri_Poids_`t'

		reg Tailles_âges variation_prix L1_precipitation_mean L2_precipitation_mean /// 
						i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
					    i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regpri_Tailles_`t'

	    reg IMC variation_prix L1_precipitation_mean L2_precipitation_mean /// 
				i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
				i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regpri_IMC_`t'
}

 esttab Regpri_Poids_gr1 Regpri_Poids_gr2 ///
	    Regpri_Tailles_gr1 Regpri_Tailles_gr2 ///
		Regpri_IMC_gr1 Regpri_IMC_gr2 using text4.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001)
 
 *Effets conjoints temperatures et variation prix
 
  foreach t in $groupe {
		
		reg Poids_âges variation_prix L1_air_temp_mean L2_air_temp_mean /// 
						i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
					    i.b4 i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regprix_Poids_`t'

		reg Tailles_âges variation_prix L1_air_temp_mean L2_air_temp_mean /// 
						i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
					    i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regprix_Tailles_`t'

	    reg IMC variation_prix L1_air_temp_mean L2_air_temp_mean /// 
				i.v411 i.v414f i.v414g i.v414h i.hv244 i.hv246 v136 v137 ///
				i.Wealth_index [pweight=v005] if `t'==1
						eststo clear
						estimates store Regprix_IMC_`t'
}

 esttab Regprix_Poids_gr1 Regprix_Poids_gr2 ///
	    Regprix_Tailles_gr1 Regprix_Tailles_gr2 ///
		Regprix_IMC_gr1 Regprix_IMC_gr2 using text5.txt, ///
		replace label margin cells(b(star fmt(%9.3f)) se(par)) ///
		stats(r2 N, fmt(3 0) labels( R2 N)) compress nolines nonumbers ///
		nodepvars noeqlines nomtitles nonotes starlevels(* 0.1 ** 0.05 *** 0.001)
 
 
 
 
 
 
 
 
 
 
 