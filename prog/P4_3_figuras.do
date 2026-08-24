*==============================================================================
* PROBLEMA 4.3 — FIGURAS
*   Parte 1 (indicadores del 4.1): estilo The Economist con grstyle y
*           colorpalette. Eje x trimestral (%tq), las tres fuentes juntas.
*   Parte 2 (participación femenina del 4.2): colores estándar de Stata,
*           fondo blanco, leyenda legible. Eje x anual (%ty).
*
* Lee los .dta de agregados ya construidos. No vuelve a tocar los microdatos.
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS  (AJUSTAR)
*------------------------------------------------------------------
global enigh "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"
global enoe  "C:/Users/lcastillo/Downloads/RESULTADOS/ENOE"
global imss  "C:/Users/lcastillo/Downloads/RESULTADOS/IMSS"
global fig   "C:/Users/lcastillo/Downloads/RESULTADOS/FIGURAS"

cap mkdir "$fig"

*------------------------------------------------------------------
* 0b. PAQUETES (sólo se instalan la primera vez)
*------------------------------------------------------------------
capture which grstyle
if _rc ssc install grstyle, replace
capture which colorpalette
if _rc ssc install palettes, replace
capture which colrspace_library_generators
if _rc ssc install colrspace, replace

*------------------------------------------------------------------
* 0c. VERIFICACIÓN DE INSUMOS
*------------------------------------------------------------------
* El do-file se adapta a lo que exista: si falta el IMSS o el 4.2,
* omite esas figuras en vez de detenerse.
local hay_enigh = 0
local hay_enoe  = 0
local hay_imss  = 0
local hay_p42   = 0

capture confirm file "$enigh/enigh_p4_agregados.dta"
if _rc == 0 local hay_enigh = 1
capture confirm file "$enoe/enoe_p4_agregados.dta"
if _rc == 0 local hay_enoe = 1
capture confirm file "$imss/imss_p4_agregados.dta"
if _rc == 0 local hay_imss = 1
capture confirm file "$enigh/enigh_p4_2_agregados.dta"
if _rc == 0 local hay_p42 = 1

di as result _n "--- Insumos disponibles ---"
di as text "  ENIGH 4.1: `hay_enigh'    ENOE 4.1: `hay_enoe'"
di as text "  IMSS  4.1: `hay_imss'    ENIGH 4.2: `hay_p42'"

if `hay_enigh' == 0 | `hay_enoe' == 0 {
    di as error "Faltan los agregados de ENIGH o ENOE; corre primero esos do-files."
    exit 601
}

*==============================================================================
* 1. PANEL TRIMESTRAL COMÚN
*==============================================================================
tempfile tenigh tenoe timss

* --- ENIGH: anual -> se ubica en el 3er trimestre (levantamiento ago-nov)
use "$enigh/enigh_p4_agregados.dta", clear
keep anio univ ocup rural N_ind
gen int fecha_q = yq(anio, 3)
rename (univ ocup rural N_ind) (univ_enigh ocup_enigh rural_enigh nind_enigh)
drop anio
save `tenigh', replace

* --- ENOE: ya trimestral
use "$enoe/enoe_p4_agregados.dta", clear
keep fecha_q univ ocup rural N_ind
rename (univ ocup rural N_ind) (univ_enoe ocup_enoe rural_enoe nind_enoe)
save `tenoe', replace

use `tenoe', clear
merge 1:1 fecha_q using `tenigh', nogenerate

if `hay_imss' == 1 {
    use "$imss/imss_p4_agregados.dta", clear
    keep fecha_q ta campo
    rename (ta campo) (ta_imss campo_imss)
    save `timss', replace

    use `tenoe', clear
    merge 1:1 fecha_q using `tenigh', nogenerate
    merge 1:1 fecha_q using `timss',  nogenerate
}

sort fecha_q
format fecha_q %tq
save "$fig/panel_trimestral.dta", replace

di as result _n "Panel trimestral: `=_N' periodos"

*==============================================================================
* 2. ESTILO THE ECONOMIST
*==============================================================================
* Rasgos distintivos: panel azul claro, sólo rejilla horizontal blanca,
* sin línea de eje vertical, etiquetas del eje y horizontales, título
* alineado a la izquierda.
grstyle clear
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox

colorpalette economist, nograph
local e1 "`r(p1)'"
local e2 "`r(p2)'"
local e3 "`r(p3)'"

* Los colores de región se fijan también en cada gráfica, para que el
* resultado no dependa de que grstyle acepte todos sus destinos.
local ecoopt ///
    graphregion(color(white) margin(medium))                        ///
    plotregion(color("213 228 235") lcolor(none) margin(medium))    ///
    ylabel(, angle(0) labsize(small) grid glcolor(white)            ///
              glwidth(medthin) notick)                              ///
    yscale(noline)                                                  ///
    xlabel(, format(%tqCY) labsize(small) nogrid)                   ///
    xtitle("") ytitle("")                                           ///
    legend(region(lcolor(none)) size(small) symxsize(6))

use "$fig/panel_trimestral.dta", clear

*--- Figura 1: educación universitaria ---------------------------------------
twoway (line univ_enoe fecha_q, lcolor("`e1'") lwidth(medthick))              ///
       (connected univ_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")           ///
            msymbol(O) msize(small) lwidth(medium)),                          ///
    `ecoopt'                                                                  ///
    title("Población con educación universitaria", size(medium) pos(11) span) ///
    subtitle("Porcentaje de la población de 20 a 65 años", size(small) pos(11) span) ///
    legend(order(2 "ENIGH" 1 "ENOE") rows(1))                                 ///
    note("Fuente: elaboración propia con datos de la ENIGH y la ENOE (INEGI).", size(vsmall))
graph export "$fig/Figura1_universitaria.png", replace width(2400)
graph export "$fig/Figura1_universitaria.emf", replace

*--- Figura 2: población ocupada ---------------------------------------------
twoway (line ocup_enoe fecha_q, lcolor("`e1'") lwidth(medthick))              ///
       (connected ocup_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")           ///
            msymbol(O) msize(small) lwidth(medium)),                          ///
    `ecoopt'                                                                  ///
    title("Población ocupada", size(medium) pos(11) span)                     ///
    subtitle("Porcentaje de la población de 20 a 65 años", size(small) pos(11) span) ///
    legend(order(2 "ENIGH" 1 "ENOE") rows(1))                                 ///
    note("Fuente: elaboración propia con datos de la ENIGH y la ENOE (INEGI).", size(vsmall))
graph export "$fig/Figura2_ocupacion.png", replace width(2400)
graph export "$fig/Figura2_ocupacion.emf", replace

*--- Figura 3: ámbito rural ---------------------------------------------------
if `hay_imss' == 1 {
    * El IMSS mide sector de actividad, no tamaño de localidad: eje secundario.
    twoway (line rural_enoe fecha_q, lcolor("`e1'") lwidth(medthick))         ///
           (connected rural_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")      ///
                msymbol(O) msize(small) lwidth(medium))                       ///
           (line campo_imss fecha_q, lcolor("`e3'") lwidth(medthick)          ///
                lpattern(dash) yaxis(2)),                                     ///
        `ecoopt'                                                              ///
        title("Población en el ámbito rural", size(medium) pos(11) span)      ///
        subtitle("Porcentaje de la población de 20 a 65 años", size(small) pos(11) span) ///
        ytitle("", axis(2))                                                   ///
        ylabel(, axis(2) angle(0) labsize(small) notick)                      ///
        legend(order(2 "ENIGH: localidad rural" 1 "ENOE: localidad rural"     ///
                     3 "IMSS: sector campo (eje der.)") rows(2))              ///
        note("Rural es localidad de menos de 2,500 habitantes en ENIGH y ENOE. En el IMSS el campo es un sector de actividad y sólo cubre empleo formal, por eso va en eje aparte." ///
             "Fuente: elaboración propia con datos de la ENIGH, la ENOE (INEGI) y el IMSS.", size(vsmall))
}
else {
    twoway (line rural_enoe fecha_q, lcolor("`e1'") lwidth(medthick))         ///
           (connected rural_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")      ///
                msymbol(O) msize(small) lwidth(medium)),                      ///
        `ecoopt'                                                              ///
        title("Población en el ámbito rural", size(medium) pos(11) span)      ///
        subtitle("Porcentaje de la población de 20 a 65 años", size(small) pos(11) span) ///
        legend(order(2 "ENIGH" 1 "ENOE") rows(1))                             ///
        note("Rural es localidad de menos de 2,500 habitantes (definición INEGI)." ///
             "Fuente: elaboración propia con datos de la ENIGH y la ENOE (INEGI).", size(vsmall))
}
graph export "$fig/Figura3_rural.png", replace width(2400)
graph export "$fig/Figura3_rural.emf", replace

*--- Figura 4: tamaño de la población ----------------------------------------
gen double nind_enigh_m = nind_enigh / 1000000
gen double nind_enoe_m  = nind_enoe  / 1000000
if `hay_imss' == 1 gen double ta_imss_m = ta_imss / 1000000

if `hay_imss' == 1 {
    twoway (line nind_enoe_m fecha_q, lcolor("`e1'") lwidth(medthick))        ///
           (connected nind_enigh_m fecha_q, lcolor("`e2'") mcolor("`e2'")     ///
                msymbol(O) msize(small) lwidth(medium))                       ///
           (line ta_imss_m fecha_q, lcolor("`e3'") lwidth(medthick)),         ///
        `ecoopt'                                                              ///
        title("Tamaño de la población de referencia", size(medium) pos(11) span) ///
        subtitle("Millones de personas de 20 a 65 años", size(small) pos(11) span) ///
        legend(order(2 "ENIGH" 1 "ENOE" 3 "IMSS: asegurados") rows(1))        ///
        note("El IMSS contabiliza puestos de trabajo asegurados de 20 a 64 años, no población total." ///
             "Fuente: elaboración propia con datos de la ENIGH, la ENOE (INEGI) y el IMSS.", size(vsmall))
}
else {
    twoway (line nind_enoe_m fecha_q, lcolor("`e1'") lwidth(medthick))        ///
           (connected nind_enigh_m fecha_q, lcolor("`e2'") mcolor("`e2'")     ///
                msymbol(O) msize(small) lwidth(medium)),                      ///
        `ecoopt'                                                              ///
        title("Tamaño de la población de referencia", size(medium) pos(11) span) ///
        subtitle("Millones de personas de 20 a 65 años", size(small) pos(11) span) ///
        legend(order(2 "ENIGH" 1 "ENOE") rows(1))                             ///
        note("Fuente: elaboración propia con datos de la ENIGH y la ENOE (INEGI).", size(vsmall))
}
graph export "$fig/Figura4_poblacion.png", replace width(2400)
graph export "$fig/Figura4_poblacion.emf", replace

*==============================================================================
* 3. PARTE 2: COLORES ESTÁNDAR DE STATA, FONDO BLANCO
*==============================================================================
if `hay_p42' == 1 {

    grstyle clear
    set scheme s2color

    local stopt ///
        graphregion(color(white) margin(medium))                      ///
        plotregion(color(white) lcolor(none) margin(medium))          ///
        ylabel(, angle(0) labsize(small) grid glcolor(gs14) glwidth(thin)) ///
        xlabel(, format(%ty) labsize(small) nogrid)                   ///
        xtitle("")                                                    ///
        legend(region(lcolor(none)) size(small) symxsize(6))

    use "$enigh/enigh_p4_2_agregados.dta", clear
    sort anio
    format anio %ty

    *--- Figura 5: participación laboral femenina ----------------------------
    twoway (connected trab anio, msymbol(O) msize(small) lwidth(medthick)),   ///
        `stopt'                                                               ///
        title("Participación laboral femenina", size(medium))                 ///
        ytitle("% de mujeres de 20 a 65 años que trabaja", size(small))       ///
        legend(off)                                                           ///
        note("Fuente: elaboración propia con datos de la ENIGH (INEGI), 1992-2024.", size(vsmall))
    graph export "$fig/Figura5_mujeres.png", replace width(2400)
    graph export "$fig/Figura5_mujeres.emf", replace

    *--- Figura 6: por nivel educativo ---------------------------------------
    twoway (connected te1 anio, msymbol(O) msize(vsmall))                     ///
           (connected te2 anio, msymbol(S) msize(vsmall))                     ///
           (connected te3 anio, msymbol(T) msize(vsmall))                     ///
           (connected te4 anio, msymbol(D) msize(vsmall))                     ///
           (connected te5 anio, msymbol(X) msize(vsmall))                     ///
           (connected te6 anio, msymbol(+) msize(vsmall)),                    ///
        `stopt'                                                               ///
        title("Participación laboral femenina por nivel educativo", size(medium)) ///
        ytitle("% que trabaja dentro de cada nivel", size(small))             ///
        legend(order(1 "Sin instrucción" 2 "Primaria" 3 "Secundaria"          ///
                     4 "Media superior" 5 "Superior" 6 "Posgrado") rows(2))   ///
        note("Fuente: elaboración propia con datos de la ENIGH (INEGI), 1992-2024.", size(vsmall))
    graph export "$fig/Figura6_educacion.png", replace width(2400)
    graph export "$fig/Figura6_educacion.emf", replace

    *--- Figura 7: por estado civil ------------------------------------------
    preserve
        drop if missing(tc2) & missing(tc6)
        twoway (connected tc1 anio, msymbol(O) msize(vsmall))                 ///
               (connected tc2 anio, msymbol(S) msize(vsmall))                 ///
               (connected tc3 anio, msymbol(T) msize(vsmall))                 ///
               (connected tc4 anio, msymbol(D) msize(vsmall))                 ///
               (connected tc5 anio, msymbol(X) msize(vsmall))                 ///
               (connected tc6 anio, msymbol(+) msize(vsmall)),                ///
            `stopt'                                                           ///
            title("Participación laboral femenina por estado civil", size(medium)) ///
            ytitle("% que trabaja dentro de cada categoría", size(small))     ///
            legend(order(1 "Unión libre" 2 "Casada" 3 "Separada"              ///
                         4 "Divorciada" 5 "Viuda" 6 "Soltera") rows(2))       ///
            note("El estado civil no se levanta en 1992 ni 1994." ///
                 "Fuente: elaboración propia con datos de la ENIGH (INEGI), 1996-2024.", size(vsmall))
        graph export "$fig/Figura7_estadocivil.png", replace width(2400)
        graph export "$fig/Figura7_estadocivil.emf", replace
    restore

    *--- Figura 8: según hijos en el hogar -----------------------------------
    twoway (connected th0 anio, msymbol(O) msize(small) lwidth(medthick))     ///
           (connected th1 anio, msymbol(S) msize(small) lwidth(medthick)),    ///
        `stopt'                                                               ///
        title("Participación laboral femenina y presencia de hijos", size(medium)) ///
        ytitle("% que trabaja dentro de cada grupo", size(small))             ///
        legend(order(1 "Sin hijos en el hogar" 2 "Con hijos en el hogar") rows(1)) ///
        note("Se aproxima por la existencia de al menos un integrante registrado como hijo o hija del jefe del hogar." ///
             "Fuente: elaboración propia con datos de la ENIGH (INEGI), 1992-2024.", size(vsmall))
    graph export "$fig/Figura8_hijos.png", replace width(2400)
    graph export "$fig/Figura8_hijos.emf", replace
}
else di as error _n "Sin enigh_p4_2_agregados.dta: se omiten las figuras 5 a 8."

*==============================================================================
* 4. DOCUMENTO DE WORD CON LAS FIGURAS
*==============================================================================
local tipo "Times New Roman"

putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 6) halign(left)
putdocx text ("Problema 4.3. Figuras"), bold font("`tipo'", 13)

local titulos ///
    "Población con educación universitaria"                 ///
    "Población ocupada"                                     ///
    "Población en el ámbito rural"                          ///
    "Tamaño de la población de referencia"                  ///
    "Participación laboral femenina"                        ///
    "Participación laboral femenina por nivel educativo"    ///
    "Participación laboral femenina por estado civil"       ///
    "Participación laboral femenina y presencia de hijos"

local archivos Figura1_universitaria Figura2_ocupacion Figura3_rural Figura4_poblacion Figura5_mujeres Figura6_educacion Figura7_estadocivil Figura8_hijos

local t1 "Población con educación universitaria"
local t2 "Población ocupada"
local t3 "Población en el ámbito rural"
local t4 "Tamaño de la población de referencia"
local t5 "Participación laboral femenina"
local t6 "Participación laboral femenina por nivel educativo"
local t7 "Participación laboral femenina por estado civil"
local t8 "Participación laboral femenina y presencia de hijos"

local nfig = cond(`hay_p42' == 1, 8, 4)

forvalues i = 1/`nfig' {
    local a : word `i' of `archivos'

    putdocx paragraph, spacing(before, 10) spacing(after, 3) halign(left)
    putdocx text ("Figura `i'"), bold font("`tipo'", 9)
    putdocx text ("  "), font("`tipo'", 9)
    putdocx text ("`t`i''"), font("`tipo'", 9)

    putdocx paragraph, halign(center)
    putdocx image "$fig/`a'.png", width(6)
}

capture putdocx save "$fig/Figuras_P4_3.docx", replace
if _rc {
    local sello = subinstr("`c(current_time)'", ":", "", .)
    putdocx save "$fig/Figuras_P4_3_`sello'.docx", replace
}

grstyle clear
set scheme s2color

di as result _n "Listo: figuras en $fig"
