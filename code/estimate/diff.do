here
global here = r(here)
use "$here/temp/analysis_sample.dta", clear

global varlist_rhs "lnK lnL TFP lnQ lnEx lnQd"

****Average effect, foreign_hire sample, local and expat separately, xthdidreg


*Full sample
foreach Y in $varlist_rhs {

    display "`Y'"

    eststo clear
    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Full sample"
    esttab, b(3) se  style(tex)

}

*Industrial sample
foreach Y in $varlist_rhs {
    display "`Y'"

    eststo clear
    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Industry sample"
    esttab, b(3) se  style(tex)
}

*Service sample
foreach Y in $varlist_rhs {

    display "`Y'"

    eststo clear
    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Service sample"
    esttab, b(3) se style(tex)
}


