*==============================================================================
* PROBLEMA 4.1 — ENIGH: exportación de los Cuadros 1 a 4
* Genera el mismo contenido en dos formatos:
*   - Word  (putdocx): entregable
*   - Excel (putexcel): requisito literal del enunciado
* Lee enigh_p4_agregados.dta
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO 
*------------------------------------------------------------------
global out "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"

local doc      "$out/ENIGH_P4_1.docx"
local xls      "$out/ENIGH_P4_1.xlsx"
local tipo     "Times New Roman"
local tam      9
local tamnota  8
local grueso   1.5
local delgado  0.75

local fuente "la ENIGH (INEGI), 1992-2024"

*==============================================================================
* 1. PROGRAMA PARA WORD
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

*==============================================================================
* 2. PROGRAMA PARA EXCEL
*==============================================================================
* El formato de Excel se deduce del formato de Stata:
*   contiene "c"  -> #,##0   |   contiene ".2" -> 0.00   |   resto -> 0
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

    * --- encabezados en el renglón 3
    tokenize `"`encabezados'"', parse("|")
    forvalues k = 1/`K' {
        local pos = 2*`k' - 1
        local h = strtrim(`"``pos''"')
        local col : word `k' of A B C D E F G H I J K L M N O P
        putexcel `col'3 = "`h'", bold border(bottom) hcenter
    }

    * --- datos, columna por columna
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

    * --- fuente al pie
    local fila = `N' + 5
    putexcel A`fila' = "Fuente: elaboración propia con datos de `fuente'.", italic
end

*==============================================================================
* 3. CUADROS
*==============================================================================
use "$out/enigh_p4_agregados.dta", clear
sort anio

*--- Documento de Word
putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 4. Estadística descriptiva de la ENIGH, 1992-2024"), ///
    bold font("`tipo'", 13)
putdocx paragraph, spacing(after, 8) halign(left)
putdocx text ("Población de 20 a 65 años de edad. Todas las cifras están ponderadas con el factor de expansión de la encuesta."), ///
    font("`tipo'", 10)

*--- CUADRO 1: Distribución de individuos y hogares --------------------------
local t1_num "Cuadro 1"
local t1_tit "Distribución de individuos y hogares en la ENIGH, 1992-2024"
local t1_enc "Año | Hogares | Personas"
local t1_fmt "%4.0f %20.0fc %20.0fc"

tabladocx anio N_hog N_ind, numero("`t1_num'") titulo("`t1_tit'")            ///
    encabezados("`t1_enc'") formatos("`t1_fmt'")                             ///
    fuente("`fuente'") nombre(t1)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio N_hog N_ind, numero("`t1_num'") titulo("`t1_tit'")            ///
    encabezados("`t1_enc'") formatos("`t1_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 1") replace

*--- CUADRO 2: Indicadores educativos ----------------------------------------
local t2_num "Cuadro 2"
local t2_tit "Indicadores educativos en la ENIGH, 1992-2024"
local t2_enc "Año | Sin instrucción (%) | Primaria (%) | Secundaria (%) | Media superior (%) | Superior (%) | Posgrado (%) | Universitaria (%)"
local t2_fmt "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio educ1 educ2 educ3 educ4 educ5 educ6 univ,                     ///
    numero("`t2_num'") titulo("`t2_tit'")                                    ///
    encabezados("`t2_enc'") formatos("`t2_fmt'")                             ///
    fuente("`fuente'") nombre(t2)                                            ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio educ1 educ2 educ3 educ4 educ5 educ6 univ,                     ///
    numero("`t2_num'") titulo("`t2_tit'")                                    ///
    encabezados("`t2_enc'") formatos("`t2_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 2")

*--- CUADRO 3: Indicadores de ocupación --------------------------------------
local t3_num "Cuadro 3"
local t3_tit "Indicadores de ocupación en la ENIGH, 1992-2024"
local t3_enc "Año | Ocupado (%) | No ocupado (%)"
local t3_fmt "%4.0f %9.2f %9.2f"

tabladocx anio ocup noocup, numero("`t3_num'") titulo("`t3_tit'")            ///
    encabezados("`t3_enc'") formatos("`t3_fmt'")                             ///
    fuente("`fuente'") nombre(t3)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio ocup noocup, numero("`t3_num'") titulo("`t3_tit'")            ///
    encabezados("`t3_enc'") formatos("`t3_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 3")

*--- CUADRO 4: Comparativo entre zonas rurales y urbanas ---------------------
local t4_num "Cuadro 4"
local t4_tit "Comparativo entre zonas rurales y urbanas en la ENIGH, 1992-2024"
local t4_enc "Año | Urbano (%) | Rural (%)"
local t4_fmt "%4.0f %9.2f %9.2f"

tabladocx anio urbano rural, numero("`t4_num'") titulo("`t4_tit'")           ///
    encabezados("`t4_enc'") formatos("`t4_fmt'")                             ///
    fuente("`fuente'") nombre(t4)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio urbano rural, numero("`t4_num'") titulo("`t4_tit'")           ///
    encabezados("`t4_enc'") formatos("`t4_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 4")

*==============================================================================
* 4. GUARDADO
*==============================================================================
capture putdocx save "`doc'", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$out/ENIGH_P4_1_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Word:  `doc'"
di as result    "Excel: `xls'"
