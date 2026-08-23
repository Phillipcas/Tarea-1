*==============================================================================
* PROBLEMA 4.2 — ENIGH: participación laboral femenina
* % de mujeres de 20 a 65 años que trabaja, por año, y desagregado por
* nivel educativo, estado civil y presencia de hijos en el hogar.
* Produce enigh_p4_2_agregados.dta
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS  (AJUSTAR)
*------------------------------------------------------------------
global datos "C:/Users/lcastillo/Downloads/ENIGH"
global out   "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"

cap mkdir "$out"

*------------------------------------------------------------------
* 1. CARGA
*------------------------------------------------------------------
use "$datos/enigh_completa.dta", clear

* --- IMPORTANTE: la presencia de hijos se calcula sobre el hogar COMPLETO,
*     antes de cualquier filtro de edad. Si se filtrara primero a 20-65,
*     los hijos menores de 20 desaparecerían y el indicador saldría mal.
bysort anio id_viv_h id_hog_h: egen byte hay_hijos = max(categoria_parentesco_h == 3)

* --- Diagnóstico del catálogo de estado civil.
*     En los cuadros de referencia, 2024 se ve descuadrado (las casadas caen
*     de 34% a 12% y las divorciadas saltan a 17%), lo que sugiere un cambio
*     de códigos ese año. Esto lo muestra.
di as result _n "--- Estado civil por año (revisar si 2024 rompe el patrón) ---"
tab anio edo_conyug_h, row nofreq

*------------------------------------------------------------------
* 2. POBLACIÓN DE ANÁLISIS: MUJERES DE 20 A 65
*------------------------------------------------------------------
keep if inrange(edad_h, 20, 65)
keep if sexo_h == 2

*------------------------------------------------------------------
* 3. INDICADORES
*------------------------------------------------------------------
* --- global
gen byte trab = trabaja_h if !missing(trabaja_h)

* --- por nivel educativo: trab queda en missing fuera de la categoría,
*     así que el (mean) ponderado da directamente el % que trabaja
*     DENTRO de cada nivel
forvalues k = 1/6 {
    gen byte te`k' = trabaja_h if nivel_educ_agrupado_h == `k' & !missing(trabaja_h)
}

* --- por estado civil
*     1 Unión libre, 2 Casada, 3 Separada, 4 Divorciada, 5 Viuda, 6 Soltera
forvalues k = 1/6 {
    gen byte tc`k' = trabaja_h if edo_conyug_h == `k' & !missing(trabaja_h)
}

* --- por presencia de hijos en el hogar
gen byte th0 = trabaja_h if hay_hijos == 0 & !missing(trabaja_h)
gen byte th1 = trabaja_h if hay_hijos == 1 & !missing(trabaja_h)

* --- cobertura: qué proporción de mujeres se queda sin clasificar
gen byte m_educ = missing(nivel_educ_agrupado_h)
gen byte m_ec   = missing(edo_conyug_h)

*------------------------------------------------------------------
* 4. AGREGACIÓN POR AÑO
*------------------------------------------------------------------
collapse (rawsum) n_muj = trab                                        ///
         (mean)   trab te1 te2 te3 te4 te5 te6                        ///
                  tc1 tc2 tc3 tc4 tc5 tc6                             ///
                  th0 th1 m_educ m_ec                                 ///
         [aw = factor_h], by(anio)

foreach v in trab te1 te2 te3 te4 te5 te6 tc1 tc2 tc3 tc4 tc5 tc6 ///
             th0 th1 m_educ m_ec {
    replace `v' = 100 * `v'
}

gen double notrab = 100 - trab

sort anio

label var trab   "% de mujeres que trabaja"
label var notrab "% de mujeres que no trabaja"

order anio trab notrab te1 te2 te3 te4 te5 te6 ///
      tc1 tc2 tc3 tc4 tc5 tc6 th0 th1 m_educ m_ec

format %9.2f trab notrab te1 te2 te3 te4 te5 te6 ///
             tc1 tc2 tc3 tc4 tc5 tc6 th0 th1 m_educ m_ec

save "$out/enigh_p4_2_agregados.dta", replace

*------------------------------------------------------------------
* 5. REVISIONES
*------------------------------------------------------------------
di as result _n "Listo: $out/enigh_p4_2_agregados.dta"

di as result _n "--- % de mujeres que trabaja, serie completa ---"
list anio trab, noobs

di as result _n "--- Por nivel educativo (debe subir con la escolaridad) ---"
list anio te1 te3 te5 te6, noobs

di as result _n "--- Por estado civil (1992 y 1994 sin dato) ---"
list anio tc2 tc6, noobs

di as result _n "--- Por hijos en el hogar ---"
list anio th0 th1, noobs
