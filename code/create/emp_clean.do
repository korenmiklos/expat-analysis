cap drop emp_cl
clonevar emp_cl=emp

xtset frame_id_numeric year

replace emp_cl=l.emp_cl if 8*emp_cl<l.emp_cl & 8*emp_cl<f.emp_cl & f.emp_cl!=. & l.emp_cl!=. & l.emp_cl>0 & emp_cl>0 & f.emp_cl>0 & 1.1*f.emp_cl>l.emp_cl & f.emp_cl>50 & l.emp_cl>50 /*29*/
replace emp_cl=l.emp_cl if emp_cl>8*l.emp_cl & emp_cl>8*f.emp_cl & f.emp_cl!=. & l.emp_cl!=. & emp_cl!=. & l.emp_cl>0 & f.emp_cl>0 & 1.1*l.emp_cl>f.emp_cl & f.emp_cl>50 & l.emp_cl>50 /*20*/

replace emp_cl=. if 8*emp_cl<l.emp_cl & 8*emp_cl<f.emp_cl & f.emp_cl!=. & l.emp_cl!=. & l.emp_cl>0 & emp_cl>0 & f.emp_cl>0 /*& 1.1*f.emp_cl<l.emp_cl 73*/
replace emp_cl=. if emp_cl>8*l.emp_cl & emp_cl>8*f.emp_cl & f.emp_cl!=. & l.emp_cl!=. & emp_cl!=. & l.emp_cl>0 & f.emp_cl>0 /*& 1.1*l.emp_cl<f.emp_cl 114*/


* if emp<6
replace emp_cl=0 if emp_cl>6 & l.emp_cl==0 & f.emp_cl==0 & emp_cl!=. /*418*/
replace emp_cl=l.emp_cl if emp_cl==0 & f.emp_cl>6 & l.emp_cl>6 & l.emp_cl!=. & f.emp_cl!=. & l.emp_cl+5>f.emp_cl /*1630*/
replace emp_cl=l.emp_cl if emp_cl==0 & f.emp_cl>6 & l.emp_cl>6 & l.emp_cl!=. & f.emp_cl!=. & l.emp_cl<f.emp_cl+5 /*532*/

replace emp_cl=. if emp_cl==0 & f.emp_cl>6 & l.emp_cl>6 & l.emp_cl!=. & f.emp_cl!=. & l.emp_cl+5<f.emp_cl /*0*/
replace emp_cl=. if emp_cl==0 & f.emp_cl>6 & l.emp_cl>6 & l.emp_cl!=. & f.emp_cl!=. & l.emp_cl>f.emp_cl+5 /*0*/

***** Last year
bysort frame_id_numeric: egen lastyear=max(year)
foreach i of numlist 1980/2018 {

    local j=`i'+1

    gen j1=emp_cl if year == `i'
    gen j2=emp_cl if year == `j'
   
    bysort frame_id_numeric: egen v=mean(j1)
    bysort frame_id_numeric: egen w=mean(j2)
   
    sort frame_id_numeric year
   
    replace emp_cl=. if 8*v<w & v>0 & w!=. & lastyear==`j' & year==`j'
    replace emp_cl=. if 8*w<v & w>0 & v!=. & lastyear==`j' & year==`j'
   
    replace emp_cl=. if v>5 & w==0 & v!=. & lastyear==`j' & year==`j'
    replace emp_cl=. if w>5 & v==0 & w!=. & lastyear==`j' & year==`j'
   
    drop j1 j2 v w	
}

***** First year 
bysort frame_id_numeric: egen firstyear=min(year)
foreach i of numlist 1981/2019 {

    local j=`i'-1

    gen j1=emp if year == `i'
    gen j2=emp if year == `j'
   
    bysort frame_id_numeric: egen v=mean(j1)
    bysort frame_id_numeric: egen w=mean(j2)
   
    sort frame_id_numeric year
   
    replace emp_cl=. if 8*v<w & v>0 & w!=. & firstyear==`j' & year==`j'
    replace emp_cl=. if 8*w<v & w>0 & v!=. & firstyear==`j' & year==`j'
   
    replace emp_cl=. if v>5 & w==0 & v!=. & firstyear==`j' & year==`j'
    replace emp_cl=. if w>5 & v==0 & w!=. & firstyear==`j' & year==`j'
   
    drop j1 j2 v w
}

drop firstyear lastyear
