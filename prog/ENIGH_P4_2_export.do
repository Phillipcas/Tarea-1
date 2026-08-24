*==============================================================================
* PROBLEMA 4.2 — ENIGH: exportación de los Cuadros 10 a 13
*   Cuadro 10: Participación laboral femenina
*   Cuadro 11: Participación laboral femenina por nivel educativo
*   Cuadro 12: Participación laboral femenina por estado civil
*   Cuadro 13: Participación laboral femenina según hijos en el hogar
* Word (putdocx) + Excel (putexcel). Lee enigh_p4_2_agregados.dta
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO
*------------------------------------------------------------------
global out "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"

local doc      "$out/ENIGH_P4_2.docx"
local xls      "$out/ENIGH_P4_2.xlsx"
local tipo     "Times New Roman"
local tam      9
local tamnota  8
local grueso   1.5
local delgado  0.75

local fuente "la ENIGH (INEGI), 1992-2024"

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
* 2. DOCUMENTO
*==============================================================================
use "$out/enigh_p4_2_agregados.dta", clear
sort anio

putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 4. Participación laboral femenina en la ENIGH, 1992-2024"), ///
    bold font("`tipo'", 13)

putdocx paragraph, spacing(after, 8) halign(left)
putdocx text ("Mujeres de 20 a 65 años de edad, ponderadas con el factor de expansión de la encuesta. Cada celda de los cuadros 11 a 13 es el porcentaje de mujeres que trabaja dentro del grupo correspondiente, no la proporción de mujeres que pertenece a ese grupo. Los casos sin dato de la variable de clasificación se excluyen del cálculo de esa columna."), ///
    font("`tipo'", 10)

*--- CUADRO 10: participación laboral femenina -------------------------------
local a_num "Cuadro 10"
local a_tit "Participación laboral femenina en la ENIGH, 1992-2024"
local a_enc "Año | Trabaja (%) | No trabaja (%)"
local a_fmt "%4.0f %9.2f %9.2f"

tabladocx anio trab notrab, numero("`a_num'") titulo("`a_tit'")              ///
    encabezados("`a_enc'") formatos("`a_fmt'")                               ///
    fuente("`fuente'") nombre(ta)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio trab notrab, numero("`a_num'") titulo("`a_tit'")              ///
    encabezados("`a_enc'") formatos("`a_fmt'")                               ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 10") replace

*--- CUADRO 11: por nivel educativo ------------------------------------------
local b_num "Cuadro 11"
local b_tit "Participación laboral femenina por nivel educativo en la ENIGH, 1992-2024"
local b_enc "Año | Sin instrucción (%) | Primaria (%) | Secundaria (%) | Media superior (%) | Superior (%) | Posgrado (%)"
local b_fmt "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

tabladocx anio te1 te2 te3 te4 te5 te6,                                      ///
    numero("`b_num'") titulo("`b_tit'")                                      ///
    encabezados("`b_enc'") formatos("`b_fmt'")                               ///
    fuente("`fuente'") nombre(tb)                                            ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                 ///
    grueso(`grueso') delgado(`delgado')

tablaxlsx anio te1 te2 te3 te4 te5 te6,                                      ///
    numero("`b_num'") titulo("`b_tit'")                                      ///
    encabezados("`b_enc'") formatos("`b_fmt'")                               ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 11")

*--- CUADRO 12: por estado civil ---------------------------------------------
* 1992 y 1994 no levantan estado civil: esos renglones se omiten.
preserve
    drop if missing(tc2) & missing(tc6)

    local c_num "Cuadro 12"
    local c_tit "Participación laboral femenina por estado civil en la ENIGH, 1996-2024"
    local c_enc "Año | Unión libre (%) | Casada (%) | Separada (%) | Divorciada (%) | Viuda (%) | Soltera (%)"
    local c_fmt "%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f"

    tabladocx anio tc1 tc2 tc3 tc4 tc5 tc6,                                  ///
        numero("`c_num'") titulo("`c_tit'")                                  ///
        encabezados("`c_enc'") formatos("`c_fmt'")                           ///
        fuente("`fuente'") nombre(tc)                                        ///
        tipo("`tipo'") tam(8) tamnota(`tamnota')                             ///
        grueso(`grueso') delgado(`delgado')

    tablaxlsx anio tc1 tc2 tc3 tc4 tc5 tc6,                                  ///
        numero("`c_num'") titulo("`c_tit'")                                  ///
        encabezados("`c_enc'") formatos("`c_fmt'")                           ///
        fuente("`fuente'") archivo("`xls'") hoja("Cuadro 12")
restore

*--- CUADRO 13: según hijos en el hogar --------------------------------------
local d_num "Cuadro 13"
local d_tit "Participación laboral femenina según presencia de hijos en el hogar, ENIGH 1992-2024"
local d_enc "Año | Sin hijos en el hogar (%) | Con hijos en el hogar (%)"
local d_fmt "%4.0f %9.2f %9.2f"

tabladocx anio th0 th1, numero("`d_num'") titulo("`d_tit'")                  ///
    encabezados("`d_enc'") formatos("`d_fmt'")                               ///
    fuente("`fuente'") nombre(td)                                            ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                             ///
    grueso(`grueso') delgado(`delgado')

putdocx paragraph, spacing(before, 2) spacing(after, 8) halign(left), ///
   

tablaxlsx anio th0 th1, numero("`d_num'") titulo("`d_tit'")                  ///
    encabezados("`d_enc'") formatos("`d_fmt'")                               ///
    fuente("`fuente'") archivo("`xls'") hoja("Cuadro 13")

*==============================================================================
* 3. GUARDADO
*==============================================================================
capture putdocx save "`doc'", replace
if _rc {
    di as error "Word bloqueado; se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$out/ENIGH_P4_2_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Word:  `doc'"
di as result    "Excel: `xls'"
