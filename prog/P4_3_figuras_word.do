*==============================================================================
* PROBLEMA 4.3 — FIGURAS PARA INSERTAR EN WORD
* Regenera las ocho figuras SIN título, subtítulo ni nota dentro de la imagen,
* y arma un .docx donde esos elementos son texto del documento.
* Así el título es editable, seleccionable y usa la tipografía del documento.
*
* Las figuras originales (con título incrustado) no se tocan: éstas se guardan
* en la subcarpeta "word".
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS
*------------------------------------------------------------------
global enigh "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"
global fig   "C:/Users/lcastillo/Downloads/RESULTADOS/FIGURAS"

global w "$fig/word"
cap mkdir "$w"

local tipo "Times New Roman"

* ¿existen los insumos del 4.2?
local hay_p42 = 0
capture confirm file "$enigh/enigh_p4_2_agregados.dta"
if _rc == 0 local hay_p42 = 1

capture confirm file "$fig/panel_trimestral.dta"
if _rc {
    di as error "Falta $fig/panel_trimestral.dta: corre primero P4_3_figuras.do"
    exit 601
}

*==============================================================================
* 1. PARTE 1 — ESTILO THE ECONOMIST, SIN TÍTULO EN LA IMAGEN
*==============================================================================
grstyle clear
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox

colorpalette economist, nograph
local e1 "`r(p1)'"
local e2 "`r(p2)'"
local e3 "`r(p3)'"

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

*--- Figura 1
twoway (line univ_enoe fecha_q, lcolor("`e1'") lwidth(medthick))              ///
       (connected univ_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")           ///
            msymbol(O) msize(small) lwidth(medium)),                          ///
    `ecoopt' legend(order(2 "ENIGH" 1 "ENOE") rows(1))
graph export "$w/Figura1_universitaria.png", replace width(2400)

*--- Figura 2
twoway (line ocup_enoe fecha_q, lcolor("`e1'") lwidth(medthick))              ///
       (connected ocup_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")           ///
            msymbol(O) msize(small) lwidth(medium)),                          ///
    `ecoopt' legend(order(2 "ENIGH" 1 "ENOE") rows(1))
graph export "$w/Figura2_ocupacion.png", replace width(2400)

*--- Figura 3
capture confirm variable campo_imss
local hay_imss = cond(_rc == 0, 1, 0)

if `hay_imss' == 1 {
    twoway (line rural_enoe fecha_q, lcolor("`e1'") lwidth(medthick))         ///
           (connected rural_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")      ///
                msymbol(O) msize(small) lwidth(medium))                       ///
           (line campo_imss fecha_q, lcolor("`e3'") lwidth(medthick)          ///
                lpattern(dash) yaxis(2)),                                     ///
        `ecoopt'                                                              ///
        ytitle("", axis(2))                                                   ///
        ylabel(, axis(2) angle(0) labsize(small) notick)                      ///
        legend(order(2 "ENIGH: localidad rural" 1 "ENOE: localidad rural"     ///
                     3 "IMSS: sector campo (eje der.)") rows(2))
}
else {
    twoway (line rural_enoe fecha_q, lcolor("`e1'") lwidth(medthick))         ///
           (connected rural_enigh fecha_q, lcolor("`e2'") mcolor("`e2'")      ///
                msymbol(O) msize(small) lwidth(medium)),                      ///
        `ecoopt' legend(order(2 "ENIGH" 1 "ENOE") rows(1))
}
graph export "$w/Figura3_rural.png", replace width(2400)

*--- Figura 4
gen double nind_enigh_m = nind_enigh / 1000000
gen double nind_enoe_m  = nind_enoe  / 1000000
if `hay_imss' == 1 gen double ta_imss_m = ta_imss / 1000000

if `hay_imss' == 1 {
    twoway (line nind_enoe_m fecha_q, lcolor("`e1'") lwidth(medthick))        ///
           (connected nind_enigh_m fecha_q, lcolor("`e2'") mcolor("`e2'")     ///
                msymbol(O) msize(small) lwidth(medium))                       ///
           (line ta_imss_m fecha_q, lcolor("`e3'") lwidth(medthick)),         ///
        `ecoopt' legend(order(2 "ENIGH" 1 "ENOE" 3 "IMSS: asegurados") rows(1))
}
else {
    twoway (line nind_enoe_m fecha_q, lcolor("`e1'") lwidth(medthick))        ///
           (connected nind_enigh_m fecha_q, lcolor("`e2'") mcolor("`e2'")     ///
                msymbol(O) msize(small) lwidth(medium)),                      ///
        `ecoopt' legend(order(2 "ENIGH" 1 "ENOE") rows(1))
}
graph export "$w/Figura4_poblacion.png", replace width(2400)

*==============================================================================
* 2. PARTE 2 — COLORES ESTÁNDAR DE STATA, SIN TÍTULO EN LA IMAGEN
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

    *--- Figura 5
    twoway (connected trab anio, msymbol(O) msize(small) lwidth(medthick)),   ///
        `stopt' ytitle("") legend(off)
    graph export "$w/Figura5_mujeres.png", replace width(2400)

    *--- Figura 6
    twoway (connected te1 anio, msymbol(O) msize(vsmall))                     ///
           (connected te2 anio, msymbol(S) msize(vsmall))                     ///
           (connected te3 anio, msymbol(T) msize(vsmall))                     ///
           (connected te4 anio, msymbol(D) msize(vsmall))                     ///
           (connected te5 anio, msymbol(X) msize(vsmall))                     ///
           (connected te6 anio, msymbol(+) msize(vsmall)),                    ///
        `stopt' ytitle("")                                                    ///
        legend(order(1 "Sin instrucción" 2 "Primaria" 3 "Secundaria"          ///
                     4 "Media superior" 5 "Superior" 6 "Posgrado") rows(2))
    graph export "$w/Figura6_educacion.png", replace width(2400)

    *--- Figura 7
    preserve
        drop if missing(tc2) & missing(tc6)
        twoway (connected tc1 anio, msymbol(O) msize(vsmall))                 ///
               (connected tc2 anio, msymbol(S) msize(vsmall))                 ///
               (connected tc3 anio, msymbol(T) msize(vsmall))                 ///
               (connected tc4 anio, msymbol(D) msize(vsmall))                 ///
               (connected tc5 anio, msymbol(X) msize(vsmall))                 ///
               (connected tc6 anio, msymbol(+) msize(vsmall)),                ///
            `stopt' ytitle("")                                                ///
            legend(order(1 "Unión libre" 2 "Casada" 3 "Separada"              ///
                         4 "Divorciada" 5 "Viuda" 6 "Soltera") rows(2))
        graph export "$w/Figura7_estadocivil.png", replace width(2400)
    restore

    *--- Figura 8
    twoway (connected th0 anio, msymbol(O) msize(small) lwidth(medthick))     ///
           (connected th1 anio, msymbol(S) msize(small) lwidth(medthick)),    ///
        `stopt' ytitle("")                                                    ///
        legend(order(1 "Sin hijos en el hogar" 2 "Con hijos en el hogar") rows(1))
    graph export "$w/Figura8_hijos.png", replace width(2400)
}

*==============================================================================
* 3. DOCUMENTO DE WORD
*==============================================================================
* Nombres de archivo sin comillas (no llevan espacios); títulos, unidades y
* fuentes en locales numerados, que sí las necesitan.
local archivos Figura1_universitaria Figura2_ocupacion Figura3_rural Figura4_poblacion Figura5_mujeres Figura6_educacion Figura7_estadocivil Figura8_hijos

local t1 "Población con educación universitaria"
local t2 "Población ocupada"
local t3 "Población en el ámbito rural"
local t4 "Tamaño de la población de referencia"
local t5 "Participación laboral femenina"
local t6 "Participación laboral femenina por nivel educativo"
local t7 "Participación laboral femenina por estado civil"
local t8 "Participación laboral femenina y presencia de hijos"

local u1 "Porcentaje de la población de 20 a 65 años"
local u2 "Porcentaje de la población de 20 a 65 años"
local u3 "Porcentaje de la población de 20 a 65 años"
local u4 "Millones de personas de 20 a 65 años"
local u5 "Porcentaje de mujeres de 20 a 65 años que trabaja"
local u6 "Porcentaje que trabaja dentro de cada nivel educativo"
local u7 "Porcentaje que trabaja dentro de cada categoría"
local u8 "Porcentaje que trabaja dentro de cada grupo"

local f1 "Elaboración propia con datos de la ENIGH y la ENOE (INEGI)."
local f2 "Elaboración propia con datos de la ENIGH y la ENOE (INEGI)."
local f3 "Elaboración propia con datos de la ENIGH, la ENOE (INEGI) y el IMSS. Rural es localidad de menos de 2,500 habitantes en ENIGH y ENOE; en el IMSS el campo es un sector de actividad y sólo cubre empleo formal, por eso va en eje aparte."
local f4 "Elaboración propia con datos de la ENIGH, la ENOE (INEGI) y el IMSS. El IMSS contabiliza puestos de trabajo asegurados de 20 a 64 años, no población total."
local f5 "Elaboración propia con datos de la ENIGH (INEGI), 1992-2024."
local f6 "Elaboración propia con datos de la ENIGH (INEGI), 1992-2024."
local f7 "Elaboración propia con datos de la ENIGH (INEGI), 1996-2024. El estado civil no se levanta en 1992 ni 1994."
local f8 "Elaboración propia con datos de la ENIGH (INEGI), 1992-2024. La presencia de hijos se aproxima por la existencia de al menos un integrante registrado como hijo o hija del jefe del hogar."

local nfig = cond(`hay_p42' == 1, 8, 4)

putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

forvalues i = 1/`nfig' {
    local a : word `i' of `archivos'

    * --- título: "Figura N." en negritas + texto normal
    putdocx paragraph, spacing(before, 12) spacing(after, 1) halign(left)
    putdocx text ("Figura `i'. "), bold font("`tipo'", 10)
    putdocx text ("`t`i''"), font("`tipo'", 10)

    * --- unidades
    putdocx paragraph, spacing(before, 0) spacing(after, 3) halign(left)
    putdocx text ("`u`i''"), font("`tipo'", 9)

    * --- figura
    putdocx paragraph, halign(center) spacing(after, 2)
    putdocx image "$w/`a'.png", width(6)

    * --- fuente
    putdocx paragraph, spacing(before, 0) spacing(after, 10) halign(left)
    putdocx text ("Fuente: "), italic font("`tipo'", 8)
    putdocx text ("`f`i''"), font("`tipo'", 8)
}

capture putdocx save "$w/Figuras_P4_3.docx", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    putdocx save "$w/Figuras_P4_3_`sello'.docx", replace
}

grstyle clear
set scheme s2color

di as result _n "Listo: $w/Figuras_P4_3.docx"
