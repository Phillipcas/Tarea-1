*==============================================================================
* PROBLEMA 4.1 — ENOE: exportación de los Cuadros 5 y 6  (NIVEL ANUAL)
*   Cuadro 5: Indicadores de ocupación
*   Cuadro 6: Indicadores educativos
* Word (putdocx) + Excel (putexcel). Lee enoe_p4_agregados.dta
*
* REQUIERE que enoe_p4_agregados.dta traiga ya las variables de distribución
* educativa (ed_sin, ed_pri, ed_sec, ed_ms, ed_nor, ed_sup, ed_pos).
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO
*------------------------------------------------------------------
global out "C:/Users/lcastillo/Downloads/RESULTADOS/ENOE"

local doc      "$out/ENOE_P4_1.docx"
local xls      "$out/ENOE_P4_1.xlsx"
local tipo     "Times New Roman"
local tam      9
local tamnota  8
local grueso   1.5
local delgado  0.75

local fuente "la ENOE (INEGI), 2005-2026"

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
* Los porcentajes se promedian ponderando por la población de cada trimestre;
* los conteos de hogares y personas son promedio simple del año (son stocks).
use "$out/enoe_p4_agregados.dta", clear

tempfile conteos
preserve
    collapse (mean) N_hog N_ind, by(anio)
    save `conteos', replace
restore

collapse (mean) ocup noocup univ urbano rural                      ///
                ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos    ///
         [aw = N_ind], by(anio)

merge 1:1 anio using `conteos', nogenerate
sort anio

order anio N_hog N_ind ocup noocup univ urbano rural ///
      ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos

*==============================================================================
* 3. CUADROS
*==============================================================================
putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 4. Estadística descriptiva de la ENOE, 2005-2026"), ///
    bold font("`tipo'", 13)
putdocx paragraph, spacing(after, 8) halign(left)
putdocx text ("Población de 20 a 65 años de edad. Cada año es el promedio de sus trimestres, ponderando los porcentajes por la población de cada trimestre. Se excluyen entrevistas incompletas y residentes ausentes definitivos. 2020 promedia tres trimestres porque el INEGI no levantó la ENOE regular en el segundo; 2026 corresponde únicamente al primer trimestre. El rediseño de la ENOEN, vigente de 2020 T3 a 2022 T4, introduce un corte en la comparabilidad de la serie."), ///
    font("`tipo'", 10)

*--- CUADRO 5: Indicadores de ocupación --------------------------------------
local t5_num "Cuadro 5"
local t5_tit "Indicadores de ocupación en la ENOE, 2005-2026"
local t5_enc "Año | Ocupado (%) | No ocupado (%)"
local t5_fmt "%4.0f %9.2f %9.2f"

tabladocx anio ocup noocup, numero("`t5_num'") titulo("`t5_tit'")            ///
    encabezados("`t5_enc'") formatos("`t5_fmt'")                             ///
    fuente("`fuente'") nombre(t5)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio ocup noocup, numero("`t5_num'") titulo("`t5_tit'")            ///
    encabezados("`t5_enc'") formatos("`t5_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 5") replace

*--- CUADRO 6: Indicadores educativos ----------------------------------------
local t6_num "Cuadro 6"
local t6_tit "Indicadores educativos en la ENOE, 2005-2026"
local t6_enc "Año | Sin instrucción (%) | Primaria (%) | Secundaria (%) | Media superior (%) | Normal (%) | Superior (%) | Posgrado (%) | Universitaria (%)"
local t6_fmt "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos univ,         ///
    numero("`t6_num'") titulo("`t6_tit'")                                    ///
    encabezados("`t6_enc'") formatos("`t6_fmt'")                             ///
    fuente("`fuente'") nombre(t6)                                            ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio ed_sin ed_pri ed_sec ed_ms ed_nor ed_sup ed_pos univ,         ///
    numero("`t6_num'") titulo("`t6_tit'")                                    ///
    encabezados("`t6_enc'") formatos("`t6_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 6")

*--- CUADRO 7: Comparativo entre zonas rurales y urbanas ---------------------
local t7_num "Cuadro 7"
local t7_tit "Comparativo entre zonas rurales y urbanas en la ENOE, 2005-2026"
local t7_enc "Año | Urbano (%) | Rural (%)"
local t7_fmt "%4.0f %9.2f %9.2f"

tabladocx anio urbano rural, numero("`t7_num'") titulo("`t7_tit'")           ///
    encabezados("`t7_enc'") formatos("`t7_fmt'")                             ///
    fuente("`fuente'") nombre(t7)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio urbano rural, numero("`t7_num'") titulo("`t7_tit'")           ///
    encabezados("`t7_enc'") formatos("`t7_fmt'")                             ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 7")
	
*==============================================================================
* 4. GUARDADO
*==============================================================================
capture putdocx save "`doc'", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$out/ENOE_P4_1_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Word:  `doc'"
di as result    "Excel: `xls'"
