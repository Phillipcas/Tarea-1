*==============================================================================
* PROBLEMA 6 — POBREZA POR INGRESOS Y MULTIDIMENSIONAL
* ENIGH 2016, 2018, 2020, 2022 y 2024 (metodología CONEVAL/INEGI).
* Construye tres bases de agregados:
*   pobreza_nacional.dta  — evolución nacional
*   pobreza_entidad.dta   — por entidad federativa, con el cambio 2016-2024
*   pobreza_65mas.dta     — hogares con y sin integrantes de 65 años o más
*
* Toda la población, sin restricción de edad: la pobreza se mide sobre el
* total, no sobre el rango 20-65 del Problema 4.
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS 
*------------------------------------------------------------------
global datos "C:/Users/lcastillo/Downloads/ENIGH"
global out   "C:/Users/lcastillo/Downloads/RESULTADOS/POBREZA"

cap mkdir "$out"

*------------------------------------------------------------------
* 1. CARGA Y FILTRO
*------------------------------------------------------------------
use "$datos/pobreza_panel_2016_2024.dta", clear

di as result _n "--- Observaciones por año, antes de filtrar ---"
tab anio

* Se excluye a quien no tiene condición de pobreza calculada (huéspedes,
* trabajadoras domésticas, casos sin dato de ingreso suficiente).
gen byte _sindato = missing(pobreza)

di as result _n "--- % de casos sin condición de pobreza, por año ---"
tabstat _sindato, by(anio) stat(mean n) format(%9.4f)

drop if _sindato == 1
drop _sindato

*------------------------------------------------------------------
* 2. EVOLUCIÓN NACIONAL
*------------------------------------------------------------------
preserve
    collapse (mean) pobreza pobreza_e pobreza_m                          ///
                    vul_car vul_ing no_pobv                              ///
                    plp plp_e                                            ///
                    ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc ///
                    carencias carencias3                                 ///
             (mean) i_privacion                                          ///
             (mean) fuente_oficial                                       ///
             [aw = factor], by(anio)

    foreach v in pobreza pobreza_e pobreza_m vul_car vul_ing no_pobv     ///
                 plp plp_e ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv    ///
                 ic_ali_nc carencias carencias3 {
        replace `v' = 100 * `v'
    }

    label var pobreza     "% en situación de pobreza"
    label var pobreza_e   "% en pobreza extrema"
    label var pobreza_m   "% en pobreza moderada"
    label var vul_car     "% vulnerable por carencias"
    label var vul_ing     "% vulnerable por ingresos"
    label var no_pobv     "% no pobre y no vulnerable"
    label var plp         "% con ingreso bajo la línea de pobreza"
    label var plp_e       "% con ingreso bajo la línea de pobreza extrema"
    label var i_privacion "Promedio de carencias por persona"

    sort anio
    format %9.2f pobreza pobreza_e pobreza_m vul_car vul_ing no_pobv     ///
                 plp plp_e ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv    ///
                 ic_ali_nc carencias carencias3
    format %9.3f i_privacion

    save "$out/pobreza_nacional.dta", replace
restore

*------------------------------------------------------------------
* 3. POR ENTIDAD FEDERATIVA
*------------------------------------------------------------------
preserve
    collapse (mean) pobreza pobreza_e carencias3 [aw = factor], by(anio ent)

    foreach v in pobreza pobreza_e carencias3 {
        replace `v' = 100 * `v'
    }

    * versión larga, por si se quiere graficar la trayectoria completa
    save "$out/pobreza_entidad_larga.dta", replace

    * versión ancha: un renglón por entidad, una columna por año
    keep anio ent pobreza
    reshape wide pobreza, i(ent) j(anio)

    gen double cambio = pobreza2024 - pobreza2016
    label var cambio "Cambio 2016-2024 (puntos porcentuales)"

    decode ent, gen(entidad)
    replace entidad = strtrim(entidad)

    gsort -cambio
    order entidad ent
    format %9.2f pobreza* cambio

    save "$out/pobreza_entidad.dta", replace
restore

*------------------------------------------------------------------
* 4. HOGARES CON INTEGRANTES DE 65 AÑOS O MÁS
*------------------------------------------------------------------
preserve
    collapse (mean) pobreza pobreza_e pobreza_m                          ///
                    ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc ///
                    carencias3                                           ///
             [aw = factor], by(anio hogar_65mas)

    foreach v in pobreza pobreza_e pobreza_m ic_rezedu ic_asalud         ///
                 ic_segsoc ic_cv ic_sbv ic_ali_nc carencias3 {
        replace `v' = 100 * `v'
    }

    sort anio hogar_65mas
    format %9.2f pobreza pobreza_e pobreza_m ic_rezedu ic_asalud         ///
                 ic_segsoc ic_cv ic_sbv ic_ali_nc carencias3

    save "$out/pobreza_65mas.dta", replace
restore

*==============================================================================
* 5. VALIDACIONES
*==============================================================================
use "$out/pobreza_nacional.dta", clear

di as result _n "=== VALIDACIÓN 1: pobreza = extrema + moderada ==="
gen double _v1 = pobreza - (pobreza_e + pobreza_m)
list anio pobreza pobreza_e pobreza_m _v1, noobs
qui su _v1
if abs(r(max)) > 0.01 di as error "  NO CUADRA: diferencia máxima de `r(max)'"
else                  di as text  "  Correcto."

di as result _n "=== VALIDACIÓN 2: las cuatro categorías suman 100% ==="
gen double _v2 = pobreza + vul_car + vul_ing + no_pobv
list anio pobreza vul_car vul_ing no_pobv _v2, noobs
qui su _v2
if abs(r(max) - 100) > 0.05 di as error "  NO CUADRA: suma máxima de `r(max)'"
else                        di as text  "  Correcto."

di as result _n "=== VALIDACIÓN 3: contraste con las cifras oficiales ==="
di as text "  Referencia oficial de INEGI para 2024: pobreza 29.6%, extrema 5.3%."
di as text "  El equipo advierte que su cálculo de 2024 queda ~0.8 pp por debajo"
di as text "  en pobreza y ~0.4 pp en extrema, por la aproximación de deflactores."
list anio pobreza pobreza_e fuente_oficial, noobs

di as result _n "=== Serie nacional completa ==="
list anio pobreza pobreza_e pobreza_m carencias carencias3 i_privacion, noobs

di as result _n "=== Carencias sociales ==="
list anio ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc, noobs

use "$out/pobreza_entidad.dta", clear
di as result _n "=== Entidades con mayor aumento de pobreza, 2016-2024 ==="
list entidad pobreza2016 pobreza2024 cambio in 1/5, noobs
di as result _n "=== Entidades con mayor reducción ==="
list entidad pobreza2016 pobreza2024 cambio in -5/l, noobs

use "$out/pobreza_65mas.dta", clear
di as result _n "=== Pobreza según presencia de adultos mayores en el hogar ==="
list anio hogar_65mas pobreza pobreza_e carencias3, noobs

di as result _n "Listo: agregados en $out"
