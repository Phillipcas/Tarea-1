*==============================================================================
* PROBLEMA 4.1 — IMSS (2000-2026): construcción de agregados
* Asegurados de 20 a 64 años, mes de en medio de cada trimestre.
* Produce imss_p4_agregados.dta con la serie trimestral.
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. PARÁMETROS
*------------------------------------------------------------------
global imss "C:/Users/lcastillo/Downloads/IMSS"
global out  "C:/Users/lcastillo/Downloads/RESULTADOS/IMSS"

cap mkdir "$out"

local y0 = 2000
local y1 = 2026

* Meses de en medio de cada trimestre
local meses "2,5,8,11"

* Rangos de edad. E1=<15, E2=15-19, E3=20-24, ..., E11=60-64, E12=65-69,
* E13=70-74, E14=75+.  El corte 20-64 es E3 a E11: es lo más cercano a
* 20-65 que permiten los quinquenios (los de 65 caen dentro de E12).
local edades `"inlist(rango_edad,"E3","E4","E5","E6") | inlist(rango_edad,"E7","E8","E9","E10","E11")"'

*==============================================================================
* 1. LECTURA AÑO POR AÑO
*==============================================================================
* El filtro va dentro del propio use: los archivos anuales tienen decenas de
* millones de renglones y no hace falta cargarlos completos.

tempfile acumulado
local primero = 1

forvalues y = `y0'/`y1' {

    * se prueban las dos rutas posibles
    local f1 "$imss/imss_`y'.dta"
    local f2 "$imss/data_stata/`y'/imss_`y'.dta"
    local f ""
    capture confirm file "`f1'"
    if _rc == 0 local f "`f1'"
    else {
        capture confirm file "`f2'"
        if _rc == 0 local f "`f2'"
    }

    if "`f'" == "" {
        di as error "  `y': archivo no encontrado, se omite."
        continue
    }

    qui use if inlist(month,`meses') & (`edades') using "`f'", clear

    if _N == 0 {
        di as error "  `y': sin observaciones tras el filtro."
        continue
    }

    qui collapse (sum) ta teu tec tpu tpc, by(year month sexo)

    if `primero' == 1 {
        qui save `acumulado', replace
        local primero = 0
    }
    else {
        qui append using `acumulado'
        qui save `acumulado', replace
    }

    di as text "  `y' procesado"
}

*==============================================================================
* 2. SERIE TRIMESTRAL
*==============================================================================
use `acumulado', clear

* Consistencia: ta debe ser la suma de los cuatro componentes
gen double _dif = ta - (teu + tec + tpu + tpc)
qui count if abs(_dif) > 1
if r(N) > 0 di as error "ATENCIÓN: en `r(N)' celdas ta no cuadra con teu+tec+tpu+tpc."
drop _dif

* Mujeres, para el 4.2
gen double ta_muj = ta if sexo == 2

collapse (sum) ta teu tec tpu tpc ta_muj, by(year month)

rename year anio
gen byte trim    = ceil(month/3)
gen int  fecha_m = ym(anio, month)
format   fecha_m %tm
gen int  fecha_q = yq(anio, trim)
format   fecha_q %tq

sort fecha_q

*==============================================================================
* 3. INDICADORES
*==============================================================================
gen double permanentes = tpu + tpc
gen double eventuales  = teu + tec

gen double campo   = 100 * (tec + tpc) / ta
gen double urbano  = 100 * (teu + tpu) / ta
gen double p_muj   = 100 * ta_muj / ta
gen double trabaja = 100      // por construcción

label var ta          "Asegurados de 20 a 64 años"
label var permanentes "Asegurados permanentes"
label var eventuales  "Asegurados eventuales"
label var campo       "% asegurados del campo"
label var urbano      "% asegurados urbanos"
label var p_muj       "% mujeres"

order anio trim month fecha_m fecha_q ta permanentes eventuales urbano campo p_muj trabaja
format %20.0fc ta permanentes eventuales
format %9.2f   urbano campo p_muj trabaja

save "$out/imss_p4_agregados.dta", replace

*==============================================================================
* 4. REVISIONES
*==============================================================================
di as result _n "Listo: $out/imss_p4_agregados.dta  (`=_N' trimestres)"

di as result _n "--- Trimestres por año (2026 debe estar incompleto) ---"
tab anio

di as result _n "--- Extremos de la serie ---"
list anio trim ta urbano campo in 1/2
list anio trim ta urbano campo in -2/l
