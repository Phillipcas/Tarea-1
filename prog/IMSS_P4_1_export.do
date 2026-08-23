*==============================================================================
* PROBLEMA 4.1 — IMSS: exportación de los Cuadros 8 y 9  (NIVEL ANUAL)
*   Cuadro 8: Distribución de individuos asegurados
*   Cuadro 9: Comparativo entre zonas rurales y urbanas
* Word (putdocx) + Excel (putexcel). Lee imss_p4_agregados.dta
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO  (AJUSTAR)
*------------------------------------------------------------------
global out "C:/Users/lcastillo/Downloads/RESULTADOS/IMSS"

local doc      "$out/IMSS_P4_1.docx"
local xls      "$out/IMSS_P4_1.xlsx"
local tipo     "Times New Roman"
local tam      9
local tamnota  8
local grueso   1.5
local delgado  0.75

local fuente "el IMSS (asegurados), 2000-2026"

*==============================================================================
* 1. PROGRAMAS
*==============================================================================
capture program drop tabladocx
program define tabladocx
    syntax varlist(numeric), NUMero(string) TITulo(string)        ///
        ENCabezados(string) FORmatos(string)                      ///
        FUente(string) NOMbre(string)                             ///
        [TIPo(string) TAM(real 9) TAMNota(real 8)                 ///
         GRUeso(real 1.5) DELgado(real 0.75)]

    if "`tipo'" == "" local tipo "Times New Roman"
    local K : word count `varlist'
    local N = _N
    local ultima = `N' + 1
    local pie    = `ultima' + 1

    forvalues k = 1/`K' {
        local v : word `k' of `varlist'
        local f : word `k' of `formatos'
        format `v' `f'
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
        local f : word `k' of `formatos'
        capture putdocx table `nombre'(2/`ultima', `k'), nformat(`f')
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
    syntax varlist(numeric), NUMero(string) TITulo(string)        ///
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

        if strpos("`f'", "c")  local xf "#,##0"
        else if strpos("`f'", ".2") local xf "0.00"
        else local xf "0"

        mkmat `v', matrix(M`k')
        putexcel `col'4 = matrix(M`k'), nformat("`xf'") hcenter
    }

    local fila = `N' + 5
    putexcel A`fila' = "Fuente: elaboración propia con datos de `fuente'.", italic
end

*==============================================================================
* 2. AGREGACIÓN ANUAL
*==============================================================================
use "$out/imss_p4_agregados.dta", clear

tempfile conteos
preserve
    collapse (mean) ta permanentes eventuales, by(anio)
    save `conteos', replace
restore

collapse (mean) urbano campo [aw = ta], by(anio)
merge 1:1 anio using `conteos', nogenerate
sort anio

order anio ta permanentes eventuales urbano campo

*==============================================================================
* 3. CUADROS
*==============================================================================
putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 4. Estadística descriptiva del IMSS, 2000-2026"), ///
    bold font("`tipo'", 13)

putdocx paragraph, spacing(after, 8) halign(left), ///
   

*--- CUADRO 8: Distribución de individuos asegurados -------------------------
local t8_num "Cuadro 8"
local t8_tit "Distribución de individuos asegurados en el IMSS, 2000-2026"
local t8_enc "Año | Asegurados | Permanentes | Eventuales"
local t8_fmt "%4.0f %20.0fc %20.0fc %20.0fc"

tabladocx anio ta permanentes eventuales,                                    ///
    numero("`t8_num'") titulo("`t8_tit'")                                    ///
    encabezados("`t8_enc'") formatos("`t8_fmt'")                             ///
    fuente("`fuente'") nombre(t8)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio ta permanentes eventuales,                                    ///
    numero("`t8_num'") titulo("`t8_tit'")                                    ///
    encabezados("`t8_enc'") formatos("`t8_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 8") replace

*--- CUADRO 9: Comparativo entre zonas rurales y urbanas ---------------------
local t9_num "Cuadro 9"
local t9_tit "Comparativo entre zonas rurales y urbanas en el IMSS, 2000-2026"
local t9_enc "Año | Urbano (%) | Campo (%)"
local t9_fmt "%4.0f %9.2f %9.2f"

tabladocx anio urbano campo,                                                 ///
    numero("`t9_num'") titulo("`t9_tit'")                                    ///
    encabezados("`t9_enc'") formatos("`t9_fmt'")                             ///
    fuente("`fuente'") nombre(t9)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

putdocx paragraph, spacing(before, 2) spacing(after, 8) halign(left), ///
   

tablaxlsx anio urbano campo,                                                 ///
    numero("`t9_num'") titulo("`t9_tit'")                                    ///
    encabezados("`t9_enc'") formatos("`t9_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 9")

*==============================================================================
* 4. GUARDADO
*==============================================================================
capture putdocx save "`doc'", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$out/IMSS_P4_1_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Word:  `doc'"
di as result    "Excel: `xls'"
