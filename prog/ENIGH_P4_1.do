*==============================================================================
* PROBLEMA 4.1 — ENIGH (1992-2024)
* Población: personas de 20 a 65 años.
* Cuadro 1: número de hogares e individuos
* Cuadro 2: nivel educativo (incluye % con educación universitaria)
* Cuadro 3: población ocupada
* Cuadro 4: sector urbano / rural
* Todo se exporta con putexcel. Máximo 2 decimales.
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS  
*------------------------------------------------------------------
global datos "C:\Users\lcastillo\Downloads\ENIGH"
global out   "C:\Users\lcastillo\Downloads\RESULTADOS\ENIGH"

cap mkdir "$out"
local archivo "$out/ENIGH_P4_1.xlsx"

*------------------------------------------------------------------
* 1. CARGA Y RESTRICCIÓN DE POBLACIÓN
*------------------------------------------------------------------
use "$datos/enigh_completa.dta", clear

keep if inrange(edad_h, 20, 65)

* Chequeo: el factor debe ser constante dentro del hogar (si no, contar
* hogares con el factor de un solo renglón estaría mal)
bysort anio id_viv_h id_hog_h: egen double _sd = sd(factor_h)
qui count if _sd > 0 & !missing(_sd)
if r(N) > 0 di as error "ATENCIÓN: factor_h varía dentro del hogar en `r(N)' renglones."
drop _sd

gen byte uno = 1

*------------------------------------------------------------------
* 2. DEFINICIONES (comparables en el tiempo)
*------------------------------------------------------------------
* --- Nivel educativo: las 6 categorías + el agregado "universitaria"
*     Quien no tiene dato queda en missing => se excluye del numerador
*     Y del denominador (regla de la nota del equipo).
forvalues k = 1/6 {
    gen byte educ`k' = (nivel_educ_agrupado_h == `k') if !missing(nivel_educ_agrupado_h)
}
label var educ1 "Sin instrucción"
label var educ2 "Primaria"
label var educ3 "Secundaria"
label var educ4 "Media Superior"
label var educ5 "Superior"
label var educ6 "Posgrado"

gen byte univ = inlist(nivel_educ_agrupado_h, 5, 6) if !missing(nivel_educ_agrupado_h)
label var univ "Superior o Posgrado"

* --- Ocupación
gen byte ocup = trabaja_h if !missing(trabaja_h)

* --- Rural: localidad de menos de 2,500 habitantes (definición INEGI)
gen byte rural = (tam_loc_h == 4) if !missing(tam_loc_h)

* --- Casos sin dato (para documentar cobertura por año)
gen byte m_educ = missing(nivel_educ_agrupado_h)
gen byte m_trab = missing(trabaja_h)
gen byte m_loc  = missing(tam_loc_h)

*------------------------------------------------------------------
* 3. AGREGACIÓN POR AÑO
*------------------------------------------------------------------
tempfile per hog

* --- 3a. Nivel persona
preserve
    collapse (rawsum) n_ind = uno  N_ind = factor_h                        ///
             (mean)   educ1 educ2 educ3 educ4 educ5 educ6 univ            ///
                      ocup rural m_educ m_trab m_loc                       ///
             [aw = factor_h], by(anio)

    foreach v in educ1 educ2 educ3 educ4 educ5 educ6 univ ocup rural ///
                 m_educ m_trab m_loc {
        replace `v' = 100 * `v'
    }
    save `per', replace
restore

* --- 3b. Nivel hogar: hogares cuyo jefe(a) tiene entre 20 y 65 años
preserve
    keep if categoria_parentesco_h == 1
    bysort anio id_viv_h id_hog_h: keep if _n == 1
    collapse (rawsum) n_hog = uno  N_hog = factor_h, by(anio)
    save `hog', replace
restore

* --- 3c. Unión y complementos
use `per', clear
merge 1:1 anio using `hog', nogenerate
sort anio

gen double noocup = 100 - ocup
gen double urbano = 100 - rural

*------------------------------------------------------------------
* 4. CUADRO 1 — Número de personas y hogares
*------------------------------------------------------------------
putexcel set "`archivo'", sheet("Cuadro 1") replace

putexcel A1 = "Cuadro 1: Número de Personas y Hogares en la ENIGH, 1992-2024", bold
putexcel A2 = "Población de 20 a 65 años. Cifras expandidas con factor_h."

putexcel A4 = "Año"                  , bold border(bottom)
putexcel B4 = "Hogares (exp.)"       , bold border(bottom)
putexcel C4 = "Personas (exp.)"      , bold border(bottom)
putexcel D4 = "Hogares (muestra)"    , bold border(bottom)
putexcel E4 = "Personas (muestra)"   , bold border(bottom)

mkmat anio, matrix(M1a)
putexcel A5 = matrix(M1a), nformat("0")
mkmat N_hog N_ind n_hog n_ind, matrix(M1b)
putexcel B5 = matrix(M1b), nformat("#,##0")

local f = _N + 6
putexcel A`f' = "Hogares = hogares con al menos un integrante de 20 a 65 años, identificados con id_viv_h e id_hog_h."

*------------------------------------------------------------------
* 5. CUADRO 2 — Nivel educativo
*------------------------------------------------------------------
putexcel set "`archivo'", sheet("Cuadro 2") modify

putexcel A1 = "Cuadro 2: Nivel de Educación en la ENIGH, 1992-2024", bold
putexcel A2 = "Distribución porcentual de la población de 20 a 65 años, ponderada con factor_h."

putexcel A4 = "Año"                   , bold border(bottom)
putexcel B4 = "Sin instrucción (%)"   , bold border(bottom)
putexcel C4 = "Primaria (%)"          , bold border(bottom)
putexcel D4 = "Secundaria (%)"        , bold border(bottom)
putexcel E4 = "Media Superior (%)"    , bold border(bottom)
putexcel F4 = "Superior (%)"          , bold border(bottom)
putexcel G4 = "Posgrado (%)"          , bold border(bottom)
putexcel H4 = "Universitaria (%)"     , bold border(bottom)
putexcel I4 = "Sin dato (%)"          , bold border(bottom)

putexcel A5 = matrix(M1a), nformat("0")
mkmat educ1 educ2 educ3 educ4 educ5 educ6 univ m_educ, matrix(M2)
putexcel B5 = matrix(M2), nformat("0.00")

local f = _N + 6
putexcel A`f' = "Universitaria = Superior + Posgrado. Los casos sin dato de nivel educativo se excluyen del cálculo; su peso aparece en la última columna."

*------------------------------------------------------------------
* 6. CUADRO 3 — Población ocupada
*------------------------------------------------------------------
putexcel set "`archivo'", sheet("Cuadro 3") modify

putexcel A1 = "Cuadro 3: Población Ocupada en la ENIGH, 1992-2024", bold
putexcel A2 = "Población de 20 a 65 años, ponderada con factor_h."

putexcel A4 = "Año"             , bold border(bottom)
putexcel B4 = "No ocupado (%)"  , bold border(bottom)
putexcel C4 = "Ocupado (%)"     , bold border(bottom)
putexcel D4 = "Sin dato (%)"    , bold border(bottom)

putexcel A5 = matrix(M1a), nformat("0")
mkmat noocup ocup m_trab, matrix(M3)
putexcel B5 = matrix(M3), nformat("0.00")

local f = _N + 6
putexcel A`f' = "Ocupado = trabaja_h igual a 1."

*------------------------------------------------------------------
* 7. CUADRO 4 — Sector urbano y rural
*------------------------------------------------------------------
putexcel set "`archivo'", sheet("Cuadro 4") modify

putexcel A1 = "Cuadro 4: Sector Rural y Urbano en la ENIGH, 1992-2024", bold
putexcel A2 = "Población de 20 a 65 años, ponderada con factor_h."

putexcel A4 = "Año"           , bold border(bottom)
putexcel B4 = "Urbano (%)"    , bold border(bottom)
putexcel C4 = "Rural (%)"     , bold border(bottom)
putexcel D4 = "Sin dato (%)"  , bold border(bottom)

putexcel A5 = matrix(M1a), nformat("0")
mkmat urbano rural m_loc, matrix(M4)
putexcel B5 = matrix(M4), nformat("0.00")

local f = _N + 6
putexcel A`f' = "Rural = localidad de menos de 2,500 habitantes (tam_loc_h=4); urbano = tam_loc_h de 1 a 3. Definición oficial INEGI, estable en toda la serie."

*------------------------------------------------------------------
* 8. RESPALDO EN .DTA (por si se necesita para las figuras del 4.3)
*------------------------------------------------------------------
save "$out/enigh_p4_agregados.dta", replace

di as result _n "Listo: `archivo'"
