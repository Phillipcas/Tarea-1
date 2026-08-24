*==============================================================================
* PROBLEMA 4.1 — ENOE (2005 T1 - 2026 T1)   [sobre ENOE_todas.dta]
* Personas de 20 a 65 años, por trimestre.
*
* Equivalencias con ENIGH:
*   individuos    -> suma de fac
*   hogares       -> hogares cuyo jefe(a) tiene 20-65 años (par_c == 101)
*   universitaria -> cs_p13_1 en {7,8,9} = profesional, maestría, doctorado
*   trabaja       -> clase2 == 1 (población ocupada)
*   rural         -> t_loc == 4 (localidades < 2,500 hab.)
*
* Filtros estándar ENOE: r_def == 0 (entrevista completa) y
*                        c_res != 2 (se excluyen ausentes definitivos).
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. PARÁMETROS
*------------------------------------------------------------------
global base "C:/Users/lcastillo/Downloads/ENOE/ENOE_todas.dta"
global out  "C:/Users/lcastillo/Downloads/RESULTADOS/ENOE"

cap mkdir "$out"

local porpartes = 0     // 0 = una pasada; 1 = año por año (si sale r(909))
local saltar_ver = 0    // 1 = omitir la verificación de códigos (no recomendado)

local vars fac eda t_loc cs_p13_1 clase2 sex par_c r_def c_res anio_enoe trimestre_enoe

capture confirm file "$base"
if _rc {
    di as error "No encuentro la base en: $base"
    exit 601
}

*==============================================================================
* 1. VERIFICACIÓN DE CÓDIGOS
*==============================================================================
* El tab muestra etiquetas, no códigos. Aquí se comprueba que el código que
* usamos en el cálculo corresponde efectivamente a la categoría que queremos.
capture program drop enoe_verifica
program define enoe_verifica
    local ok = 1

    * --- escolaridad
    foreach par in "7 profesional" "8 maestr" "9 doctorado" {
        gettoken cod txt : par
        local txt = strtrim("`txt'")
        local l : label (cs_p13_1) `cod'
        if !strmatch(lower(`"`l'"'), "*`txt'*") {
            di as error `"  cs_p13_1 = `cod' NO es `txt' -- dice: `l'"'
            local ok = 0
        }
        else di as text `"  ok: cs_p13_1 = `cod' -> `l'"'
    }

    * --- ocupación
    local l : label (clase2) 1
    if !strmatch(lower(`"`l'"'), "*ocupada*") {
        di as error `"  clase2 = 1 NO es poblacion ocupada -- dice: `l'"'
        local ok = 0
    }
    else di as text `"  ok: clase2 = 1 -> `l'"'

    * --- entrevista
    local l : label (r_def) 0
    if !strmatch(lower(`"`l'"'), "*completa*") {
        di as error `"  r_def = 0 NO es entrevista completa -- dice: `l'"'
        local ok = 0
    }
    else di as text `"  ok: r_def = 0 -> `l'"'

    * --- residencia
    local l : label (c_res) 2
    if !strmatch(lower(`"`l'"'), "*ausente*") {
        di as error `"  c_res = 2 NO es ausente definitivo -- dice: `l'"'
        local ok = 0
    }
    else di as text `"  ok: c_res = 2 -> `l'"'

    if `ok' == 0 {
        di as error _n "Los codigos no coinciden con lo esperado."
        di as error "Revisa las definiciones, o pon saltar_ver = 1 si ya verificaste a mano."
        exit 459
    }
    di as result _n "Verificacion de codigos: correcta." _n
end

*==============================================================================
* 2. AGREGACIÓN
*==============================================================================
capture program drop enoe_agrega
program define enoe_agrega

    * filtros estándar de ENOE
    qui keep if r_def == 0 & c_res != 2
    qui keep if inrange(eda, 20, 65)
    qui compress

    * "No sabe" y cualquier código fuera de 0-9 se trata como dato faltante
    qui replace cs_p13_1 = . if cs_p13_1 > 9

    qui gen byte   univ    = inlist(cs_p13_1, 7, 8, 9) if !missing(cs_p13_1)
	qui gen byte ed_sin = inlist(cs_p13_1,0,1) if !missing(cs_p13_1)
    qui gen byte ed_pri = (cs_p13_1==2)        if !missing(cs_p13_1)
    qui gen byte ed_sec = (cs_p13_1==3)        if !missing(cs_p13_1)
    qui gen byte ed_ms  = inlist(cs_p13_1,4,6) if !missing(cs_p13_1)
    qui gen byte ed_nor = (cs_p13_1==5)        if !missing(cs_p13_1)
    qui gen byte ed_sup = (cs_p13_1==7)        if !missing(cs_p13_1)
    qui gen byte ed_pos = inlist(cs_p13_1,8,9) if !missing(cs_p13_1)
    qui gen byte   ocup    = (clase2 == 1)             if !missing(clase2)
    qui gen byte   rural   = (t_loc == 4)              if !missing(t_loc)
    qui gen byte   m_educ  = missing(cs_p13_1)
    qui gen byte   uno     = 1
    qui gen byte   jefe    = (par_c == 101)
    qui gen double fac_jef = fac * (par_c == 101)

        qui collapse (rawsum) n_ind = uno  N_ind = fac       ///
                          n_hog = jefe N_hog = fac_jef   ///
                 (mean)   univ ocup rural m_educ         ///
                          ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos ///
                 [aw = fac], by(anio_enoe trimestre_enoe)

        foreach v in univ ocup rural m_educ ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos {
        qui replace `v' = 100 * `v'
    }
end

if `porpartes' == 0 {
    di as text "Cargando la base (sólo las variables necesarias)..."
    use `vars' using "$base", clear
    di as text "Renglones cargados: " _N
    enoe_agrega
}
else {
    tempfile acum
    local primero = 1
    forvalues y = 2005/2026 {
        qui use `vars' using "$base" if anio_enoe == `y', clear
        if _N == 0 {
            di as error "  `y': sin observaciones."
            continue
        }
        enoe_agrega
        if `primero' == 1 {
            qui save `acum', replace
            local primero = 0
        }
        else {
            qui append using `acum'
            qui save `acum', replace
        }
        di as text "  `y' procesado"
    }
    use `acum', clear
}

*==============================================================================
* 3. SERIE FINAL
*==============================================================================
rename anio_enoe      anio
rename trimestre_enoe trim
sort anio trim

gen int fecha_q = yq(anio, trim)
format  fecha_q %tq

gen double noocup = 100 - ocup
gen double urbano = 100 - rural

label var N_ind "Personas de 20 a 65 años (expandidas)"
label var N_hog "Hogares con jefe(a) de 20 a 65 años (expandidos)"
label var univ  "% con educación universitaria"
label var ocup  "% ocupado"
label var rural "% en localidad rural"

order anio trim fecha_q N_hog N_ind n_hog n_ind univ ocup noocup urbano rural m_educ

format %20.0fc N_hog N_ind n_hog n_ind
format %9.2f   univ ocup noocup urbano rural m_educ

save "$out/enoe_p4_agregados.dta", replace

*------------------------------------------------------------------
* 4. REVISIONES
*------------------------------------------------------------------
di as result _n "Listo: $out/enoe_p4_agregados.dta  (`=_N' trimestres)"

di as result _n "--- Trimestres por año (2020 debe tener 3, no 4) ---"
tab anio

di as result _n "--- Casos sin dato de escolaridad: debe ser cercano a cero ---"
su m_educ

di as result _n "--- Extremos de la serie ---"
list anio trim N_hog N_ind univ ocup rural in 1/2
list anio trim N_hog N_ind univ ocup rural in -2/l

di as result _n "--- Alrededor del quiebre metodológico de 2020 ---"
list anio trim univ ocup rural if inrange(anio,2019,2021)
