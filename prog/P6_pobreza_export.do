*==============================================================================
* PROBLEMA 6 — EXPORTACIÓN
*   Cuadro 14: Evolución nacional de la pobreza
*   Cuadro 15: Carencias sociales
*   Cuadro 16: Pobreza por entidad federativa y cambio 2016-2024
*   Cuadro 17: Pobreza según presencia de adultos mayores en el hogar
*   Figuras 9 a 12
* Word (putdocx) + Excel (putexcel).
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO  (AJUSTAR)
*------------------------------------------------------------------
global pob "C:/Users/lcastillo/Downloads/RESULTADOS/POBREZA"
global fig "$pob/figuras"

cap mkdir "$fig"

local doc      "$pob/P6_pobreza.docx"
local xls      "$pob/P6_pobreza.xlsx"
local tipo     "Times New Roman"
local tam      9
local tamnota  8
local grueso   1.5
local delgado  0.75

local fuente "la ENIGH (INEGI) y la metodología de medición de pobreza de CONEVAL"

*==============================================================================
* 1. PROGRAMAS (admiten una primera columna de texto)
*==============================================================================
capture program drop tabladocx
program define tabladocx
    syntax varlist, NUMero(string) TITulo(string)                 ///
        ENCabezados(string) FORmatos(string)                      ///
        FUente(string) NOMbre(string)                             ///
        [TIPo(string) TAM(real 9) TAMNota(real 8)                 ///
         GRUeso(real 1.5) DELgado(real 0.75)]

    if "`tipo'" == "" local tipo "Times New Roman"
    local K : word count `varlist'
    local N = _N
    local ultima = `N' + 1
    local pie    = `ultima' + 1

    * el formato sólo aplica a variables numéricas
    forvalues k = 1/`K' {
        local v : word `k' of `varlist'
        local f : word `k' of `formatos'
        capture confirm numeric variable `v'
        if _rc == 0 format `v' `f'
    }

    putdocx paragraph, spacing(before, 10) spacing(after, 3) halign(left)
    putdocx text ("`numero'"), bold font("`tipo'", `tam')
    putdocx text ("  "), font("`tipo'", `tam')
    putdocx text ("`titulo'"), font("`tipo'", `tam')

    putdocx table `nombre' = data(`varlist'), varnames ///
        layout(autofitwindow) headerrow(1) halign(center)

    tokenize `"`encabezados'"', parse("|")
    forvalues k = 1/`K' {
        local pos = 2*`k' - 1
        local h = strtrim(`"``pos''"')
        putdocx table `nombre'(1,`k') = ("`h'")
    }

    forvalues k = 1/`K' {
        local v : word `k' of `varlist'
        local f : word `k' of `formatos'
        capture confirm numeric variable `v'
        if _rc == 0 capture putdocx table `nombre'(2/`ultima', `k'), nformat(`f')
    }

    putdocx table `nombre'(.,.), font("`tipo'", `tam') halign(center) valign(center)
    putdocx table `nombre'(1,.), bold

    foreach cm in "top 0.01" "bottom 0.01" "left 0.04" "right 0.04" {
        gettoken lado medida : cm
        capture putdocx table `nombre'(.,.), cellmargin(`lado', `medida')
    }

    putdocx table `nombre'(.,.), border(all, nil)
    putdocx table `nombre'(1,.), border(top, single, black, `grueso')
    putdocx table `nombre'(1,.), border(bottom, single, black, `delgado')
    putdocx table `nombre'(`ultima',.), border(bottom, single, black, `grueso')

    capture noisily {
        putdocx table `nombre'(`ultima',.), addrows(1)
        putdocx table `nombre'(`pie',1), colspan(`K')
        putdocx table `nombre'(`pie',1) = ("Fuente: elaboración propia con datos de `fuente'.")
        putdocx table `nombre'(`pie',1), halign(left) italic font("`tipo'", `tamnota')
        putdocx table `nombre'(`pie',1), border(all, nil)
    }
    if _rc {
        putdocx paragraph, spacing(before, 3) spacing(after, 10) halign(left)
        putdocx text ("Fuente: "), italic font("`tipo'", `tamnota')
        putdocx text ("elaboración propia con datos de `fuente'."), font("`tipo'", `tamnota')
    }
end

capture program drop tablaxlsx
program define tablaxlsx
    syntax varlist, NUMero(string) TITulo(string)                 ///
        ENCabezados(string) FORmatos(string)                      ///
        FUente(string) ARchivo(string) HOja(string) [REPlace]

    local K : word count `varlist'
    local N = _N

    if "`replace'" != "" putexcel set "`archivo'", sheet("`hoja'") replace
    else                 putexcel set "`archivo'", sheet("`hoja'") modify

    putexcel A1 = "`numero'. `titulo'", bold

    tokenize `"`encabezados'"', parse("|")
    forvalues k = 1/`K' {
        local pos = 2*`k' - 1
        local h = strtrim(`"``pos''"')
        local col : word `k' of A B C D E F G H I J K L M N O P
        putexcel `col'3 = "`h'", bold border(bottom) hcenter
    }

    forvalues k = 1/`K' {
        local v : word `k' of `varlist'
        local f : word `k' of `formatos'
        local col : word `k' of A B C D E F G H I J K L M N O P

        capture confirm numeric variable `v'
        if _rc {
            * columna de texto: se escribe renglón por renglón
            forvalues i = 1/`N' {
                local fila = `i' + 3
                putexcel `col'`fila' = ("`=`v'[`i']'")
            }
        }
        else {
            if strpos("`f'", "c")  local xf "#,##0"
            else if strpos("`f'", ".2") local xf "0.00"
            else local xf "0"

            mkmat `v', matrix(M`k')
            putexcel `col'4 = matrix(M`k'), nformat("`xf'") hcenter
        }
    }

    local fila = `N' + 5
    putexcel A`fila' = "Fuente: elaboración propia con datos de `fuente'.", italic
end

*==============================================================================
* 2. FIGURAS
*==============================================================================
set scheme s2color

local stopt ///
    graphregion(color(white) margin(medium))                      ///
    plotregion(color(white) lcolor(none) margin(medium))          ///
    ylabel(, angle(0) labsize(small) grid glcolor(gs14) glwidth(thin)) ///
    xlabel(, format(%ty) labsize(small) nogrid)                   ///
    xtitle("")                                                    ///
    legend(region(lcolor(none)) size(small) symxsize(6))

*--- Figura 9: evolución nacional --------------------------------------------
use "$pob/pobreza_nacional.dta", clear
sort anio
format anio %ty

twoway (connected pobreza   anio, msymbol(O) msize(small) lwidth(medthick))   ///
       (connected pobreza_m anio, msymbol(S) msize(small) lwidth(medthick))   ///
       (connected pobreza_e anio, msymbol(T) msize(small) lwidth(medthick)),  ///
    `stopt' ytitle("")                                                        ///
    legend(order(1 "Pobreza total" 2 "Pobreza moderada" 3 "Pobreza extrema") rows(1))
graph export "$fig/Figura9_pobreza_nacional.png", replace width(2400)

*--- Figura 10: carencias sociales -------------------------------------------
twoway (connected ic_segsoc  anio, msymbol(O) msize(vsmall))                  ///
       (connected ic_asalud  anio, msymbol(S) msize(vsmall))                  ///
       (connected ic_ali_nc  anio, msymbol(T) msize(vsmall))                  ///
       (connected ic_sbv     anio, msymbol(D) msize(vsmall))                  ///
       (connected ic_rezedu  anio, msymbol(X) msize(vsmall))                  ///
       (connected ic_cv      anio, msymbol(+) msize(vsmall)),                 ///
    `stopt' ytitle("")                                                        ///
    legend(order(1 "Seguridad social" 2 "Acceso a salud" 3 "Alimentación"     ///
                 4 "Servicios básicos" 5 "Rezago educativo"                   ///
                 6 "Calidad de la vivienda") rows(2))
graph export "$fig/Figura10_carencias.png", replace width(2400)

*--- Figura 11: cambio por entidad -------------------------------------------
use "$pob/pobreza_entidad.dta", clear

graph hbar (asis) cambio,                                                     ///
    over(entidad, sort(1) descending label(labsize(vsmall)))                  ///
    bar(1, color(navy))                                                       ///
    blabel(bar, format(%4.1f) size(vsmall))                                   ///
    ytitle("Cambio en puntos porcentuales, 2016-2024", size(small))           ///
    graphregion(color(white) margin(medium))                                  ///
    plotregion(color(white) lcolor(none))                                     ///
    ylabel(, labsize(small) grid glcolor(gs14))                               ///
    ysize(8) xsize(6)
graph export "$fig/Figura11_entidades.png", replace width(2400)

*--- Figura 12: hogares con adultos mayores ----------------------------------
use "$pob/pobreza_65mas.dta", clear
keep anio hogar_65mas pobreza pobreza_e
reshape wide pobreza pobreza_e, i(anio) j(hogar_65mas)
sort anio
format anio %ty

twoway (connected pobreza0 anio, msymbol(O) msize(small) lwidth(medthick))    ///
       (connected pobreza1 anio, msymbol(S) msize(small) lwidth(medthick)),   ///
    `stopt' ytitle("")                                                        ///
    legend(order(1 "Hogares sin integrantes de 65 años o más"                 ///
                 2 "Hogares con al menos un integrante de 65 años o más") rows(2))
graph export "$fig/Figura12_adultos_mayores.png", replace width(2400)

*==============================================================================
* 3. DOCUMENTO
*==============================================================================
putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 6. Pobreza por ingresos y multidimensional, 2016-2024"), ///
    bold font("`tipo'", 13)

putdocx paragraph, spacing(after, 8) halign(left)
putdocx text ("Población total, ponderada con el factor de expansión de la encuesta. Se excluye a las personas sin condición de pobreza calculada. Los años 2016 a 2022 provienen de la base oficial de CONEVAL; 2024 es una adaptación propia del programa oficial a los microdatos de ese año, que arroja una pobreza 0.8 puntos porcentuales por debajo de la cifra publicada por el INEGI y una pobreza extrema 0.4 puntos por debajo."), ///
    font("`tipo'", 10)

*--- CUADRO 14 ----------------------------------------------------------------
use "$pob/pobreza_nacional.dta", clear
sort anio

local n14 "Cuadro 14"
local t14 "Evolución nacional de la pobreza, 2016-2024"
local e14 "Año | Pobreza (%) | Pobreza moderada (%) | Pobreza extrema (%) | Vulnerable por carencias (%) | Vulnerable por ingresos (%) | No pobre ni vulnerable (%)"
local f14 "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv,          ///
    numero("`n14'") titulo("`t14'")                                          ///
    encabezados("`e14'") formatos("`f14'")                                   ///
    fuente("`fuente'") nombre(c14)                                           ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio pobreza pobreza_m pobreza_e vul_car vul_ing no_pobv,          ///
    numero("`n14'") titulo("`t14'")                                          ///
    encabezados("`e14'") formatos("`f14'")                                   ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 14") replace

*--- CUADRO 15 ----------------------------------------------------------------
local n15 "Cuadro 15"
local t15 "Carencias sociales, 2016-2024"
local e15 "Año | Rezago educativo (%) | Acceso a salud (%) | Seguridad social (%) | Calidad de la vivienda (%) | Servicios básicos (%) | Alimentación (%) | Al menos una (%) | Al menos tres (%)"
local f15 "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc          ///
          carencias carencias3,                                              ///
    numero("`n15'") titulo("`t15'")                                          ///
    encabezados("`e15'") formatos("`f15'")                                   ///
    fuente("`fuente'") nombre(c15)                                           ///
    tipo("`tipo'") tam(7) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali_nc          ///
          carencias carencias3,                                              ///
    numero("`n15'") titulo("`t15'")                                          ///
    encabezados("`e15'") formatos("`f15'")                                   ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 15")

*--- CUADRO 16 ----------------------------------------------------------------
use "$pob/pobreza_entidad.dta", clear
gsort cambio                       // de la mayor reducción a la menor

local n16 "Cuadro 16"
local t16 "Pobreza por entidad federativa y cambio entre 2016 y 2024"
local e16 "Entidad | 2016 (%) | 2018 (%) | 2020 (%) | 2022 (%) | 2024 (%) | Cambio (pp)"
local f16 "%s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx entidad pobreza2016 pobreza2018 pobreza2020 pobreza2022           ///
          pobreza2024 cambio,                                                ///
    numero("`n16'") titulo("`t16'")                                          ///
    encabezados("`e16'") formatos("`f16'")                                   ///
    fuente("`fuente'") nombre(c16)                                           ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

putdocx paragraph, spacing(before, 2) spacing(after, 8) halign(left)
putdocx text ("Ordenado de la mayor a la menor reducción. Las 32 entidades redujeron su incidencia de pobreza entre 2016 y 2024; ninguna la aumentó."), ///
    italic font("`tipo'", `tamnota')

tablaxlsx entidad pobreza2016 pobreza2018 pobreza2020 pobreza2022           ///
          pobreza2024 cambio,                                                ///
    numero("`n16'") titulo("`t16'")                                          ///
    encabezados("`e16'") formatos("`f16'")                                   ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 16")

*--- CUADRO 17 ----------------------------------------------------------------
use "$pob/pobreza_65mas.dta", clear
keep anio hogar_65mas pobreza pobreza_e carencias3
reshape wide pobreza pobreza_e carencias3, i(anio) j(hogar_65mas)
sort anio

local n17 "Cuadro 17"
local t17 "Pobreza según presencia de adultos mayores en el hogar, 2016-2024"
local e17 "Año | Pobreza sin 65+ (%) | Pobreza con 65+ (%) | Extrema sin 65+ (%) | Extrema con 65+ (%) | Tres carencias sin 65+ (%) | Tres carencias con 65+ (%)"
local f17 "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio pobreza0 pobreza1 pobreza_e0 pobreza_e1 carencias30 carencias31, ///
    numero("`n17'") titulo("`t17'")                                          ///
    encabezados("`e17'") formatos("`f17'")                                   ///
    fuente("`fuente'") nombre(c17)                                           ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio pobreza0 pobreza1 pobreza_e0 pobreza_e1 carencias30 carencias31, ///
    numero("`n17'") titulo("`t17'")                                          ///
    encabezados("`e17'") formatos("`f17'")                                   ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 17")

*==============================================================================
* 4. FIGURAS EN EL DOCUMENTO
*==============================================================================
local archivos Figura9_pobreza_nacional Figura10_carencias Figura11_entidades Figura12_adultos_mayores

local g1 "Evolución nacional de la pobreza"
local g2 "Carencias sociales"
local g3 "Cambio en la incidencia de pobreza por entidad federativa, 2016-2024"
local g4 "Pobreza según presencia de adultos mayores en el hogar"

local h1 "Porcentaje de la población"
local h2 "Porcentaje de la población con cada carencia"
local h3 "Puntos porcentuales de cambio"
local h4 "Porcentaje de la población en situación de pobreza"

local i1 "Elaboración propia con datos de la ENIGH (INEGI) y la metodología de CONEVAL."
local i2 "Elaboración propia con datos de la ENIGH (INEGI) y la metodología de CONEVAL. El salto en la carencia por acceso a servicios de salud a partir de 2020 coincide con la sustitución del Seguro Popular."
local i3 "Elaboración propia con datos de la ENIGH (INEGI) y la metodología de CONEVAL. Las 32 entidades redujeron su incidencia de pobreza en el periodo."
local i4 "Elaboración propia con datos de la ENIGH (INEGI) y la metodología de CONEVAL."

forvalues i = 1/4 {
    local a : word `i' of `archivos'
    local n = `i' + 8

    putdocx paragraph, spacing(before, 12) spacing(after, 1) halign(left)
    putdocx text ("Figura `n'. "), bold font("`tipo'", 10)
    putdocx text ("`g`i''"), font("`tipo'", 10)

    putdocx paragraph, spacing(before, 0) spacing(after, 3) halign(left)
    putdocx text ("`h`i''"), font("`tipo'", 9)

    putdocx paragraph, halign(center) spacing(after, 2)
    putdocx image "$fig/`a'.png", width(6)

    putdocx paragraph, spacing(before, 0) spacing(after, 10) halign(left)
    putdocx text ("Fuente: "), italic font("`tipo'", 8)
    putdocx text ("`i`i''"), font("`tipo'", 8)
}

*==============================================================================
* 5. GUARDADO
*==============================================================================
capture putdocx save "`doc'", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$pob/P6_pobreza_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Word:  `doc'"
di as result    "Excel: `xls'"
di as result    "Figuras: $fig"
