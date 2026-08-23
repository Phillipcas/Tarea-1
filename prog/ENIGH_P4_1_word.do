*==============================================================================
* PROBLEMA 4.1 — ENIGH: cuadros en WORD con putdocx  (versión 4)
* Cambios respecto a v3:
*   - formato numérico aplicado a las variables ANTES de crear la tabla
*     (si no, putdocx usa el display format heredado y redondea a 3 cifras)
*   - la línea de Fuente es un renglón más de la propia tabla, para que Word
*     no pueda separarla del cuadro
*   - sin notas al pie y sin control manual de anchos
*==============================================================================

clear all
set more off
set varabbrev off

*------------------------------------------------------------------
* 0. RUTAS Y ESTILO  (AJUSTAR)
*------------------------------------------------------------------
global out "C:/Users/lcastillo/Downloads/RESULTADOS/ENIGH"

local doc      "$out/ENIGH_P4_1.docx"
local tipo     "Times New Roman"
local tam      9       // letra de las celdas
local tamnota  8       // letra de la línea de fuente
local grueso   1.5     // regla gruesa
local delgado  0.75    // regla delgada

*==============================================================================
* 1. PROGRAMA
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

    *--- CLAVE: el formato se fija en las variables antes de crear la tabla.
    *    putdocx toma el display format de cada variable; si se deja el que
    *    viene de collapse (%9.0g) los números salen redondeados.
    forvalues k = 1/`K' {
        local v : word `k' of `varlist'
        local f : word `k' of `formatos'
        format `v' `f'
    }

    *--- Encabezado del cuadro
    putdocx paragraph, spacing(before, 10) spacing(after, 3) halign(left)
    putdocx text ("`numero'"), bold font("`tipo'", `tam')
    putdocx text ("  "), font("`tipo'", `tam')
    putdocx text ("`titulo'"), font("`tipo'", `tam')

    *--- Tabla
    putdocx table `nombre' = data(`varlist'), varnames ///
        layout(autofitwindow) headerrow(1) halign(center)

    *--- Encabezados propios
    tokenize `"`encabezados'"', parse("|")
    forvalues k = 1/`K' {
        local pos = 2*`k' - 1
        local h = strtrim(`"``pos''"')
        putdocx table `nombre'(1,`k') = ("`h'")
    }

    *--- Refuerzo del formato numérico celda por celda
    forvalues k = 1/`K' {
        local f : word `k' of `formatos'
        capture putdocx table `nombre'(2/`ultima', `k'), nformat(`f')
    }

    *--- Tipografía y alineación
    putdocx table `nombre'(.,.), font("`tipo'", `tam') halign(center) valign(center)
    putdocx table `nombre'(1,.), bold

    *--- Márgenes de celda (no existe en todas las versiones; se intenta callado)
    foreach cm in "top 0.01" "bottom 0.01" "left 0.04" "right 0.04" {
        gettoken lado medida : cm
        capture putdocx table `nombre'(.,.), cellmargin(`lado', `medida')
    }

    *--- Reglas horizontales, sin bordes verticales
    putdocx table `nombre'(.,.), border(all, nil)
    putdocx table `nombre'(1,.), border(top, single, black, `grueso')
    putdocx table `nombre'(1,.), border(bottom, single, black, `delgado')
    putdocx table `nombre'(`ultima',.), border(bottom, single, black, `grueso')

    *--- La fuente como renglón de la tabla: así Word no la puede separar
    capture noisily {
        putdocx table `nombre'(`ultima',.), addrows(1)
        putdocx table `nombre'(`pie',1), colspan(`K')
        putdocx table `nombre'(`pie',1) = ("Fuente: elaboración propia con datos de `fuente'.")
        putdocx table `nombre'(`pie',1), halign(left) italic font("`tipo'", `tamnota')
        putdocx table `nombre'(`pie',1), border(all, nil)
    }
    if _rc {
        di as text "  (no se pudo anexar la fuente a la tabla; va como párrafo)"
        putdocx paragraph, spacing(before, 3) spacing(after, 10) halign(left)
        putdocx text ("Fuente: "), italic font("`tipo'", `tamnota')
        putdocx text ("elaboración propia con datos de `fuente'."), font("`tipo'", `tamnota')
    }

    di as text "  `numero' escrito"
end

*==============================================================================
* 2. DOCUMENTO
*==============================================================================
use "$out/enigh_p4_agregados.dta", clear
sort anio

local fuente "la ENIGH (INEGI), 1992-2024"

putdocx clear
putdocx begin, font("`tipo'", 11) pagesize(letter) ///
    margin(left, 1) margin(right, 1) margin(top, 1) margin(bottom, 1)

putdocx paragraph, spacing(after, 2) halign(left)
putdocx text ("Problema 4. Estadística descriptiva de la ENIGH, 1992-2024"), ///
    bold font("`tipo'", 13)

putdocx paragraph, spacing(after, 8) halign(left)
putdocx text ("Población de 20 a 65 años de edad. Todas las cifras están ponderadas con el factor de expansión de la encuesta."), ///
    font("`tipo'", 10)

*--- Cuadro 1 ---------------------------------------------------------------
tabladocx anio N_hog N_ind,                                                   ///
    numero("Cuadro 1")                                                        ///
    titulo("Número de personas y hogares en la ENIGH, 1992-2024")             ///
    encabezados("Año | Hogares | Personas")                                   ///
    formatos("%4.0f %20.0fc %20.0fc")                                         ///
    fuente("`fuente'") nombre(t1)                                             ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                              ///
    grueso(`grueso') delgado(`delgado')

*--- Cuadro 2 ---------------------------------------------------------------
tabladocx anio educ1 educ2 educ3 educ4 educ5 educ6 univ,                      ///
    numero("Cuadro 2")                                                        ///
    titulo("Nivel de educación en la ENIGH, 1992-2024")                       ///
    encabezados("Año | Sin instrucción (%) | Primaria (%) | Secundaria (%) | Media superior (%) | Superior (%) | Posgrado (%) | Universitaria (%)") ///
    formatos("%4.0f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f")               ///
    fuente("`fuente'") nombre(t2)                                             ///
    tipo("`tipo'") tam(8) tamnota(`tamnota')                                  ///
    grueso(`grueso') delgado(`delgado')

*--- Cuadro 3 ---------------------------------------------------------------
tabladocx anio ocup noocup,                                                   ///
    numero("Cuadro 3")                                                        ///
    titulo("Condición de ocupación en la ENIGH, 1992-2024")                   ///
    encabezados("Año | Ocupado (%) | No ocupado (%)")                         ///
    formatos("%4.0f %9.2f %9.2f")                                             ///
    fuente("`fuente'") nombre(t3)                                             ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                              ///
    grueso(`grueso') delgado(`delgado')

*--- Cuadro 4 ---------------------------------------------------------------
tabladocx anio urbano rural,                                                  ///
    numero("Cuadro 4")                                                        ///
    titulo("Distribución urbano-rural en la ENIGH, 1992-2024")                ///
    encabezados("Año | Urbano (%) | Rural (%)")                               ///
    formatos("%4.0f %9.2f %9.2f")                                             ///
    fuente("`fuente'") nombre(t4)                                             ///
    tipo("`tipo'") tam(`tam') tamnota(`tamnota')                              ///
    grueso(`grueso') delgado(`delgado')

*--- Guardado a prueba de archivo abierto en Word
capture putdocx save "`doc'", replace
if _rc {
    di as error "No se pudo guardar (¿el .docx está abierto en Word?). Se guarda con marca de tiempo."
    local sello = subinstr("`c(current_time)'", ":", "", .)
    local doc "$out/ENIGH_P4_1_`sello'.docx"
    putdocx save "`doc'", replace
}

di as result _n "Listo: `doc'"
