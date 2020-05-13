# 2020-04-17
## Updating input data to new manager-db
Fixed input dependencies on `ceo-panel` and `balance-small`.

`spell` variable is always zero

```
. tab spell

      spell |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    458,802      100.00      100.00
          1 |          1        0.00      100.00
------------+-----------------------------------
      Total |    458,803      100.00
```

This is likely because we are already using CEOs. Is panel balanced?

## Balancing panel
Panel is likely already balanced, there are very few gaps in spells.
```
. by company_manager: generate gap = year - year[_n-1] - 1
(73,668 missing values generated)

. replace gap = 0 if missing(gap)
(73,668 real changes made)

. tabulate gap

        gap |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    454,943       99.16       99.16
          1 |      1,527        0.33       99.49
          2 |        669        0.15       99.64
          3 |        442        0.10       99.73
          4 |        322        0.07       99.80
          5 |        264        0.06       99.86
          6 |        153        0.03       99.89
          7 |        110        0.02       99.92
          8 |         84        0.02       99.94
          9 |         77        0.02       99.95
         10 |         46        0.01       99.96
         11 |         40        0.01       99.97
         12 |         29        0.01       99.98
         13 |         27        0.01       99.98
         14 |         20        0.00       99.99
         15 |         16        0.00       99.99
         16 |         11        0.00       99.99
         17 |         11        0.00      100.00
         18 |          3        0.00      100.00
         19 |          5        0.00      100.00
         20 |          1        0.00      100.00
         21 |          1        0.00      100.00
         23 |          1        0.00      100.00
         24 |          1        0.00      100.00
------------+-----------------------------------
      Total |    458,803      100.00

```

Most gaps are only 1 year long, this suggests they should be filled.

Very few CEOs come back for second spell.
```
. count
  460,330

. count if year>first_exit_year 
  12,291
```

## Check expat vs foreign
```
. count if first_year_expat_original < first_year_foreign_original & ever_foreign 
  13,974

. count if first_year_expat_original >= first_year_foreign_original & ever_foreign 
  101,014
```

Indeed very few domestic firms are expat-run (only 2%).
```
. egen fy_tag = tag(frame_id_numeric year )

. tabulate max_expat foreign if fy_tag 

           |  Foreign owned dummy
           | with ultimate owners
           |     from Complex
 max_expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   247,039     25,879 |   272,918 
         1 |     5,306     29,724 |    35,030 
-----------+----------------------+----------
     Total |   252,345     55,603 |   307,948 
```

Most of them are early?

```
. tabulate max_expat ever_foreign , col

+-------------------+
| Key               |
|-------------------|
|     frequency     |
| column percentage |
+-------------------+

           |     ever_foreign
 max_expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   307,702     57,772 |   365,474 
           |     98.65      50.24 |     85.61 
-----------+----------------------+----------
         1 |     4,219     57,216 |    61,435 
           |      1.35      49.76 |     14.39 
-----------+----------------------+----------
     Total |   311,921    114,988 |   426,909 
           |    100.00     100.00 |    100.00 
```

```
. generate expat_delay = first_year_expat_original - first_year_foreign_original 
. table max_expat foreign, c(mean expat_delay )

--------------------------------
          | Foreign owned dummy 
          | with ultimate owners
          |     from Complex    
max_expat |         0          1
----------+---------------------
        0 |  .7110159   3.343341
        1 | -2.230545    .588455
--------------------------------
```

Typically, there is a 1-2-year lag explaining why domestic firms have expats.
```
. table max_expat foreign if tenure==0, c(mean expat_delay median expat_delay )

--------------------------------
          | Foreign owned dummy 
          | with ultimate owners
          |     from Complex    
max_expat |         0          1
----------+---------------------
        0 |  .7490318   2.730574
          |         0          0
          | 
        1 | -1.597111   .9510848
          |        -1          0
--------------------------------
```

I have not yet added before and after years.

# 2020-04-23
## Go back to original data structure
```
. tabulate foreign  expat if year >= job_begin & year <= job_end 

   Foreign |
     owned |
dummy with |
  ultimate |
    owners |
      from |    (firstnm) expat
   Complex |         0          1 |     Total
-----------+----------------------+----------
         0 |   332,464      5,488 |   337,952 
         1 |    44,202     44,308 |    88,510 
-----------+----------------------+----------
     Total |   376,666     49,796 |   426,462 

. tabulate ever_foreign ever_expat  if year >= job_begin & year <= job_end 

ever_forei |      ever_expat
        gn |         0          1 |     Total
-----------+----------------------+----------
         0 |   303,417      8,504 |   311,921 
         1 |    30,667     83,874 |   114,541 
-----------+----------------------+----------
     Total |   334,084     92,378 |   426,462 
```

Changing Expat dates moves some entry dates by more than 2 years, investigate why.

This was a bug, now only change start year of manager if start *exactly* 2 years before becoming foreign.

First regression on new data:
```
. areg lnQL during foreign expat_during i.year  if during|before & abs(tenure)<=5, a(i) vce(cluster frame_
> id_numeric )

Linear regression, absorbing indicators         Number of obs     =    576,657
Absorbed variable: i                            No. of categories =     49,197
                                                F(  32,  17673)   =     337.86
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8426
                                                Adj R-squared     =     0.8279
                                                Root MSE          =     0.6081

                  (Std. Err. adjusted for 17,674 clusters in frame_id_numeric)
------------------------------------------------------------------------------
             |               Robust
        lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
      during |  -.0026833   .0066163    -0.41   0.685    -.0156519    .0102852
     foreign |   .0879362   .0248305     3.54   0.000      .039266    .1366064
expat_during |   .0867627   .0182126     4.76   0.000     .0510642    .1224612
```

## Refactor creation of regression sample
Most data cleaning is at the job spell level, not the firm-year level. Foreign dummy is an exception.

Our data has too many years around switching.
```
. summarize tenure, detail

                           tenure
-------------------------------------------------------------
      Percentiles      Smallest
 1%          -21            -29
 5%          -15            -29
10%          -10            -29       Obs           1,148,578
25%           -3            -29       Sum of Wgt.   1,148,578

50%            2                      Mean           2.656023
                        Largest       Std. Dev.      9.808664
75%            9             29
90%           16             29       Variance       96.20988
95%           19             29       Skewness      -.0853869
99%           25             29       Kurtosis       2.960682
```

# 2020-04-24
## Discussion with Almos
- deflate nominal variables

Firms before 1990 have missing fo3. Set this to zero.
```
. tabulate year fo3, miss

           |     Foreign owned dummy with
      Year |   ultimate owners from Complex
 1992-2017 |         0          1          . |     Total
-----------+---------------------------------+----------
      1980 |         0          0      4,405 |     4,405 
      1981 |         0          0      4,372 |     4,372 
      1982 |         0          0      4,290 |     4,290 
      1983 |         0          0      4,262 |     4,262 
      1984 |         0          0      4,155 |     4,155 
      1985 |         0          0      4,904 |     4,904 
      1986 |         0          0      5,382 |     5,382 
      1987 |         0          0      5,985 |     5,985 
      1988 |         0          0      6,636 |     6,636 
      1989 |         0          0     10,707 |    10,707 
      1990 |         0      1,968     18,510 |    20,478 
      1991 |         0      4,184     30,503 |    34,687 
      1992 |    91,551     10,360          0 |   101,911 
      1993 |   109,711     14,632          0 |   124,343 
      1994 |   135,398     18,840          0 |   154,238 
      1995 |   150,812     20,537          0 |   171,349 
```
- Use `tanass` instead?
- fill in gap years of final_netgep==0 | missing. if gap (positive, zero, zero, positive), allow for 2 years. at the beginning and end, only 1 year.
```
final_netgep
135621
109576
0
87343
78700
```
- Where does `final_netgep` come from before 1990?
- Need a window to harmonize arrival of foreign CEO and owner. [-2, +1] is the same time. time of acquisition = time of ceo = min(t1, t2). Drop entire firms for which gap < -2.

```
. tabulate expat_after_foreign if tag

expat_after |
   _foreign |      Freq.     Percent        Cum.
------------+-----------------------------------
..
         -5 |         23        0.62        2.92
         -4 |         42        1.14        4.06
         -3 |         49        1.33        5.39
         -2 |        137        3.71        9.10
         -1 |        359        9.72       18.81
          0 |      1,472       39.85       58.66
          1 |        762       20.63       79.29
          2 |        138        3.74       83.03
          3 |         94        2.54       85.57
          4 |         74        2.00       87.57
          5 |         70        1.89       89.47
          6 |         66        1.79       91.26
```

```
. tabulate ever_expat ever_foreign if tag

           |     ever_foreign
ever_expat |         0          1 |     Total
-----------+----------------------+----------
         0 |    20,231      2,283 |    22,514 
         1 |       504      3,694 |     4,198 
-----------+----------------------+----------
     Total |    20,735      5,977 |    26,712 

```

# 2020-04-29
## Check why regressions with during_foreign don't work
There are lot of expat-years which are not coded as "hired by foreign," even though there are no expats at purely foreign firms.
```
. tabulate ever_foreign expat

ever_forei |    (firstnm) expat
        gn |         0          1 |     Total
-----------+----------------------+----------
         0 |   447,256          0 |   447,256 
         1 |   141,549    104,940 |   246,489 
-----------+----------------------+----------
     Total |   588,805    104,940 |   693,745 

. gen byte foreign_hire = (first_year_foreign <= job_begin & foreign)
. gen during = (year >= job_begin & year <= job_end)
. gen during_foreign = during*foreign_hire

. tabulate during_foreign expat

during_for |    (firstnm) expat
      eign |         0          1 |     Total
-----------+----------------------+----------
         0 |   555,782     66,464 |   622,246 
         1 |    33,023     38,476 |    71,499 
-----------+----------------------+----------
     Total |   588,805    104,940 |   693,745 

. tabulate during_foreign expat if during

during_for |    (firstnm) expat
      eign |         0          1 |     Total
-----------+----------------------+----------
         0 |   267,192      4,043 |   271,235 
         1 |    33,023     38,476 |    71,499 
-----------+----------------------+----------
     Total |   300,215     42,519 |   342,734 

```

Check regression, but omit "after" years
```
. areg lnQL during foreign during_foreign i.year if before|during, a(i)

Linear regression, absorbing indicators         Number of obs     =    486,674
Absorbed variable: i                            No. of categories =     66,833
                                                F(  32, 419809)   =    3879.13
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8759
                                                Adj R-squared     =     0.8562
                                                Root MSE          =     0.5516

--------------------------------------------------------------------------------
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |   .0744211     .00316    23.55   0.000     .0682276    .0806146
       foreign |   .0452695   .0066425     6.82   0.000     .0322504    .0582885
during_foreign |   .0652788   .0046173    14.14   0.000      .056229    .0743285

. gen during_expat = during_foreign*expat

. areg lnQL during foreign during_foreign during_expat i.year if before|during, a(i)

Linear regression, absorbing indicators         Number of obs     =    486,674
Absorbed variable: i                            No. of categories =     66,833
                                                F(  33, 419808)   =    3762.54
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8760
                                                Adj R-squared     =     0.8562
                                                Root MSE          =     0.5516

--------------------------------------------------------------------------------
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |   .0744091   .0031599    23.55   0.000     .0682158    .0806025
       foreign |   .0469737   .0066511     7.06   0.000     .0339378    .0600095
during_foreign |   .0459274   .0060306     7.62   0.000     .0341076    .0577472
  during_expat |   .0377981   .0075775     4.99   0.000     .0229464    .0526498
```

This seems to work, but not if after is left in. The `during_expat` becomes zero and if expats have a permanent effect, our estimate will be biased towards zero.

```
. areg lnQL during foreign during_foreign during_expat i.year, a(i)

Linear regression, absorbing indicators         Number of obs     =    654,289
Absorbed variable: i                            No. of categories =     69,210
                                                F(  33, 585046)   =    5687.57
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8519
                                                Adj R-squared     =     0.8343
                                                Root MSE          =     0.5953

--------------------------------------------------------------------------------
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |   .0286431   .0022967    12.47   0.000     .0241416    .0331445
       foreign |   .0940728   .0053383    17.62   0.000     .0836099    .1045357
during_foreign |  -.0033495   .0055806    -0.60   0.548    -.0142872    .0075883
  during_expat |  -.0013864   .0069797    -0.20   0.843    -.0150663    .0122936
```

## Some expats come to not-yet foreign firms
```
. table tenure_foreign expat if abs(tenure_foreign )<=5 & !greenfield & during

------------------------
          |  (firstnm)  
tenure_fo |    expat    
reign     |     0      1
----------+-------------
       -5 |   824      1
       -4 |   977      1
       -3 | 1,150      1
       -2 | 1,334      5
       -1 | 1,641      6
        0 | 1,901    512
        1 | 1,650    594
        2 | 1,439    593
        3 | 1,309    548
        4 | 1,165    496
        5 | 1,060    479
------------------------
```
Before recoding foreign entry, this is the distrubtion.
```
. tab manager_after_owner  event_time if abs(event_time )<=3 & abs( manager_after_owner )<=4 & foreign 

manager_af |                                  event_time
 ter_owner |        -3         -2         -1          0          1          2          3 |     Total
-----------+-----------------------------------------------------------------------------+----------
        -3 |         0          0          0          0          0          0        213 |       213 
        -2 |         0          0          0          0          0        422        378 |       800 
        -1 |         0          0          0          0        911        789        755 |     2,455 
         0 |         0          0          0      7,384      6,675      6,252      6,102 |    26,413 
         1 |         0          0      6,152      5,936      5,549      5,252      5,057 |    27,946 
         2 |         0        860        814        784        766        741        684 |     4,649 
         3 |       610        576        562        596        568        530        524 |     3,966 
         4 |       459        429        454        449        429        410        400 |     3,030 
-----------+-----------------------------------------------------------------------------+----------
     Total |     1,069      1,865      7,982     15,149     14,898     14,396     14,113 |    69,472 

```
We don't seem to deal with foreign/manager gaps if outside [-2, 1] event window.
```
. replace first_year_foreign = first_year_expat if inlist(manager_after_owner, -2, -1, 1)
(120,374 real changes made)

. 
. replace foreign = 1 if (manager_after_owner == -2) & inlist(event_time, 0, 1)
(352 real changes made)

. replace foreign = 1 if (manager_after_owner == -1) & inlist(event_time, 0)
(387 real changes made)

. replace foreign = 0 if (manager_after_owner == +1) & inlist(event_time, -1)
(6,152 real changes made)

. 
. tab manager_after_owner  event_time if abs(event_time )<=3 & abs( manager_after_owner )<=4 & foreign 

manager_af |                                  event_time
 ter_owner |        -3         -2         -1          0          1          2          3 |     Total
-----------+-----------------------------------------------------------------------------+----------
        -3 |         0          0          0          0          0          0        213 |       213 
        -2 |         0          0          0        182        170        422        378 |     1,152 
        -1 |         0          0          0        387        911        789        755 |     2,842 
         0 |         0          0          0      7,384      6,675      6,252      6,102 |    26,413 
         1 |         0          0          0      5,936      5,549      5,252      5,057 |    21,794 
         2 |         0        860        814        784        766        741        684 |     4,649 
         3 |       610        576        562        596        568        530        524 |     3,966 
         4 |       459        429        454        449        429        410        400 |     3,030 
-----------+-----------------------------------------------------------------------------+----------
     Total |     1,069      1,865      1,830     15,718     15,068     14,396     14,113 |    64,059 

```
Commit `be282` solves this.
```
. table tenure_foreign expat if abs(tenure_foreign )<=5 & !greenfield & during

------------------------
          |  (firstnm)  
tenure_fo |    expat    
reign     |     0      1
----------+-------------
       -5 |   756       
       -4 |   954       
       -3 | 1,129       
       -2 | 1,388       
       -1 | 1,769       
        0 | 2,286    473
        1 | 2,211    485
        2 | 2,084    545
        3 | 2,015    564
        4 | 1,950    579
        5 | 1,845    584
------------------------
```

## First year of firms often missing manager data
```
. egen first_manager = min(job_begin ), by(frame_id_numeric )

. gen manager_tenure = first_manager - min_year 

. tab manager_tenure 

manager_ten |
        ure |      Freq.     Percent        Cum.
------------+-----------------------------------
        -29 |         19        0.00        0.00
        -28 |         80        0.01        0.01
        -27 |         69        0.01        0.01
        -26 |         21        0.00        0.02
        -25 |        213        0.02        0.03
        -24 |         34        0.00        0.04
        -23 |         70        0.01        0.04
        -22 |        233        0.02        0.06
        -21 |        516        0.04        0.10
        -20 |        461        0.04        0.14
        -19 |        432        0.04        0.18
        -18 |      1,055        0.09        0.27
        -17 |        544        0.05        0.31
        -16 |        670        0.06        0.37
        -15 |      1,565        0.13        0.50
        -14 |        965        0.08        0.58
        -13 |      1,716        0.14        0.72
        -12 |      1,727        0.14        0.87
        -11 |      2,799        0.23        1.10
        -10 |      1,749        0.15        1.25
         -9 |      3,027        0.25        1.50
         -8 |      3,453        0.29        1.79
         -7 |      4,006        0.34        2.13
         -6 |      4,659        0.39        2.52
         -5 |      8,494        0.71        3.23
         -4 |     21,123        1.77        4.99
         -3 |     12,847        1.07        6.07
         -2 |     25,525        2.13        8.20
         -1 |     47,668        3.99       12.19
          0 |    579,261       48.44       60.63
          1 |    338,835       28.34       88.97
          2 |     33,648        2.81       91.78
```

# 2020-04-30
## Extrapolate to first year
```
. replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)
(15,389 real changes made)
```

Labor productivity regression is pretty, but there is no change in exporting after takeover.
```
. areg lnQL during foreign during_foreign during_expat i.year if (before|during) & !divest & !greenfiel
> d , a(i) cluster(frame_id_numeric )

Linear regression, absorbing indicators         Number of obs     =    341,104
Absorbed variable: i                            No. of categories =     35,344
                                                F(  33,  14795)   =     317.55
                                                Prob > F          =     0.0000
                                                R-squared         =     0.8455
                                                Adj R-squared     =     0.8276
                                                Root MSE          =     0.6006

                    (Std. Err. adjusted for 14,796 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |  -.0051482   .0069593    -0.74   0.459    -.0187892    .0084928
       foreign |   .1593086   .0364367     4.37   0.000     .0878882    .2307289
during_foreign |   .0763527   .0321713     2.37   0.018     .0132929    .1394125
  during_expat |    .101419   .0383304     2.65   0.008     .0262866    .1765513

. areg exporter during foreign during_foreign during_expat i.year if (before|during) & !divest & !green
> field , a(i) cluster(frame_id_numeric )

Linear regression, absorbing indicators         Number of obs     =    366,502
Absorbed variable: i                            No. of categories =     38,002
                                                F(  33,  16827)   =      17.12
                                                Prob > F          =     0.0000
                                                R-squared         =     0.6826
                                                Adj R-squared     =     0.6459
                                                Root MSE          =     0.2784

                    (Std. Err. adjusted for 16,828 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
      exporter |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |  -.0095485   .0028796    -3.32   0.001    -.0151927   -.0039042
       foreign |   .0720802   .0127646     5.65   0.000     .0470602    .0971002
during_foreign |   .0107195   .0123657     0.87   0.386    -.0135186    .0349576
  during_expat |   .0081797   .0156377     0.52   0.601    -.0224718    .0388313

```

## Fix reghdfe
```
. reghdfe lnQL during foreign, a(teaor08_2d##year i)
(dropped 1469 singleton observations)
(MWFE estimator converged in 52 iterations)
class FixedEffects undefined
r(3000);

. reghdfe, compile
(existing lftools.mlib compiled with Stata ???; need to recompile for Stata 15.1)
(compiling lftools.mlib for Stata 15.1)
(library saved in /Users/koren/Library/Application Support/Stata/ado/plus/l/lftools.mlib)
(compiling lreghdfe.mlib for Stata 15.1)
(library saved in /Users/koren/Library/Application Support/Stata/ado/plus/l/lreghdfe.mlib)
```
This was fast.

```
. reghdfe lnQL during foreign during_foreign during_expat if (before|during) & !divest & !greenfield , 
> a(i teaor08_2d##year age_cat) cluster(frame_id_numeric )
(dropped 649 singleton observations)
(MWFE estimator converged in 61 iterations)

HDFE Linear regression                            Number of obs   =    340,454
Absorbing 3 HDFE groups                           F(   4,  14445) =      17.46
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.8554
                                                  Adj R-squared   =     0.8378
                                                  Within R-sq.    =     0.0022
Number of clusters (frame_id_numeric) =     14,446Root MSE        =     0.5813

                    (Std. Err. adjusted for 14,446 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |  -.0065158    .006195    -1.05   0.293    -.0186588    .0056273
       foreign |    .120886   .0325512     3.71   0.000     .0570815    .1846905
during_foreign |    .091859   .0289238     3.18   0.001     .0351647    .1485532
  during_expat |   .0951104   .0342803     2.77   0.006     .0279166    .1623041
         _cons |     8.7912   .0052253  1682.41   0.000     8.780958    8.801442
--------------------------------------------------------------------------------
```
We still have expats in non-foreign years, not sure where they come from.
```
. tab expat foreign if during

           |  Foreign owned dummy
           | with ultimate owners
 (firstnm) |     from Complex
     expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   237,968     62,196 |   300,164 
         1 |     3,356     62,939 |    66,295 
-----------+----------------------+----------
     Total |   241,324    125,135 |   366,459 
```
Oh, I haven't yet dropped divesting firm-years.
```
. tab expat foreign if during & !divest

           |  Foreign owned dummy
           | with ultimate owners
 (firstnm) |     from Complex
     expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   224,954     60,109 |   285,063 
         1 |         0     60,561 |    60,561 
-----------+----------------------+----------
     Total |   224,954    120,670 |   345,624 

```

## There are too few CEOs in early 1990s
In 1992
```
. egen has_ceo = max(position==1), by(frame_id)

. tabulate manager_type position if N==2 & !has_ceo

manager_ty |             position
        pe |         0          2          3 |     Total
-----------+---------------------------------+----------
      FO-F |         3          0          0 |         3 
      FO-O |        12          0          0 |        12 
      FO-P |       420         10          2 |       432 
      HU-F |        80          4          0 |        84 
      HU-O |        28          0          0 |        28 
      HU-P |    19,511        108         53 |    19,672 
     HU-SO |         1          0          0 |         1 
-----------+---------------------------------+----------
     Total |    20,055        122         55 |    20,232 

```

We will set CEO=1 if N<=6, will drop entire firm otherwise.

Merge manager_category 3 and 4.

# 2020-05-01
## Impute more CEOs

```
. tab year imputed 

           |        imputed
      year |         0          1 |     Total
-----------+----------------------+----------
      1988 |    22,731      9,291 |    32,022 
      1989 |    29,463     13,585 |    43,048 
      1990 |    54,668     31,410 |    86,078 
      1991 |    96,578     44,158 |   140,736 
      1992 |   154,451     51,255 |   205,706 
      1993 |   203,763     52,594 |   256,357 
      1994 |   246,890     53,950 |   300,840 
      1995 |   280,286     55,800 |   336,086 
      1996 |   318,209     56,185 |   374,394 
      1997 |   355,972     57,552 |   413,524 
      1998 |   398,387     57,085 |   455,472 
      1999 |   422,751     53,451 |   476,202 
      2000 |   453,655     49,682 |   503,337 
      2001 |   482,874     46,757 |   529,631 
      2002 |   503,105     43,989 |   547,094 
      2003 |   521,845     41,666 |   563,511 
      2004 |   547,855     39,146 |   587,001 
      2005 |   566,983     38,189 |   605,172 
      2006 |   584,976     37,105 |   622,081 
      2007 |   583,781     37,501 |   621,282 
      2008 |   622,711     35,413 |   658,124 
      2009 |   649,719     32,200 |   681,919 
      2010 |   665,034     27,761 |   692,795 
      2011 |   673,527     24,278 |   697,805 
      2012 |   672,816     25,899 |   698,715 
      2013 |   680,090     26,965 |   707,055 
      2014 |   686,508     25,637 |   712,145 
      2015 |   682,665     23,371 |   706,036 
      2016 |   661,291     22,269 |   683,560 
      2017 |   640,450     19,892 |   660,342 
      2018 |   616,885     15,517 |   632,402 
-----------+----------------------+----------
     Total |14,080,919  1,149,553 |15,230,472 
```

Compare regressions on new data:

```
. reghdfe lnQL during foreign during_foreign during_expat if (before|during) & !divest & !greenfield , a(i teaor08_2d##year age_cat) cluster(frame_id_numeric )

(dropped 1061 singleton observations)
(MWFE estimator converged in 67 iterations)

HDFE Linear regression                            Number of obs   =    466,539
Absorbing 3 HDFE groups                           F(   4,  15372) =      12.53
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.8522
                                                  Adj R-squared   =     0.8341
                                                  Within R-sq.    =     0.0015
Number of clusters (frame_id_numeric) =     15,373Root MSE        =     0.6042

                    (Std. Err. adjusted for 15,373 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
        during |  -.0281904   .0069696    -4.04   0.000    -.0418516   -.0145291
       foreign |   .1314524   .0323883     4.06   0.000     .0679674    .1949374
during_foreign |   .1100595   .0317685     3.46   0.001     .0477895    .1723295
  during_expat |   .0876463    .054918     1.60   0.111    -.0199994     .195292
         _cons |   8.668307   .0050092  1730.47   0.000     8.658488    8.678125
--------------------------------------------------------------------------------

```
There are 120,000 more observations, but during expat is no longer significant.

# 2020-05-08
## Check disappearing expats
```
. count if ever_expat_old & !greenfield_old 
  658

. keep if ever_expat_old & !greenfield_old 
(2,373 observations deleted)

. keep frame_id 

. save expat_old
file expat_old.dta saved

. use temp/analysis_sample
. generate frame_id = "ft"+string(frame_id_numeric, "%8.0f")
. codebook frame_id  if ever_expat & !greenfield 

-------------------------------------------------------------------------------------------------------
frame_id                                                                                    (unlabeled)
-------------------------------------------------------------------------------------------------------

                  type:  string (str10)

         unique values:  191                      missing "":  0/10,270

              examples:  "ft10300703"
                         "ft10550180"
                         "ft11060084"
                         "ft12113006"

. keep  if ever_expat & !greenfield 
(651,122 observations deleted)

. keep frame_id 

. duplicates drop

Duplicates in terms of all variables

(10,079 observations deleted)

. merge 1:1 frame_id using "~/Downloads/expat_old.dta"

    Result                           # of obs.
    -----------------------------------------
    not matched                           683
        from master                       108  (_merge==1)
        from using                        575  (_merge==2)

    matched                                83  (_merge==3)
    -----------------------------------------

. export delimited frame_id using "dropped-expat.csv" if _merge==2, novarnames replace
(note: file dropped-expat.csv not found)
file dropped-expat.csv saved

. export delimited frame_id using "new-expat.csv" if _merge==1, novarnames replace
(note: file new-expat.csv not found)
file new-expat.csv saved
```

# 2020-05-12
## Check FB board members

Those coming from `rovat_15` always get a zero on all position dummies? Make sure to drop them all.
```
. generate rovat = substr(source , 1, 2)

. tab board rovat 

           |         rovat
     board |        13         15 |     Total
-----------+----------------------+----------
         0 |   199,402     22,756 |   222,158 
         1 |     4,835          0 |     4,835 
         2 |       837          0 |       837 
-----------+----------------------+----------
     Total |   205,074     22,756 |   227,830 


. tab position rovat 

           |         rovat
  position |        13         15 |     Total
-----------+----------------------+----------
         0 |    82,713     22,756 |   105,469 
         1 |   107,708          0 |   107,708 
         2 |     8,376          0 |     8,376 
         3 |     6,277          0 |     6,277 
-----------+----------------------+----------
     Total |   205,074     22,756 |   227,830 
```

Number of managers depends heavily on type of corporation.

```
. egen ft = tag(frame_id position)

. egen N = count(board ), by(frame_id position )

. table cf position if ft, c(mean N)

---------------------------------------------------------------------------------
                                         |                position               
                                      cf |        0         1         2         3
-----------------------------------------+---------------------------------------
                                Vállalat | 6.428407                              
                             Szövetkezet |  1.71868  1.038702  1.572306  1.169296
                    Közkereseti társaság | 1.722034  1.657699  1.166667         1
                 Gazdasági munkaközösség | 1.526674                              
      Jogi személy felelősségvállalásáva |  1.52802                              
                         Betéti társaság | 1.179467  1.194393  1.116438  1.142857
                               Egyesülés | 1.542986                              
                          Közös vállalat | 2.481013                              
          Korlátolt felelősségű társaság |  1.38562  1.390881  2.089261  1.903042
                        Részvénytársaság | 4.723701     1.044  5.310726  11.63636
                              Egyéni cég |  1.04213                              
    Külföldiek magyarországi közvetlen k | 1.112036                              
                   Oktatói munkaközösség | 2.123288                              
                      Közhasznú társaság | 1.117647                              
               Erdőbirtokossági társulat | 1.466667                              
                Vízgazdálkodási társulat |      1.6                              
     Külföldi vállalkozás magyarországi  |        1                              
                       Végrehajtói iroda |        1                              
                Európai részvénytársaság |        1                              
                     Európai szövetkezet |        1                              
---------------------------------------------------------------------------------
```

There are still a lot of imputed CEOs.
```
. tabulate year imputed if ceo

           |        imputed
      year |         0          1 |     Total
-----------+----------------------+----------
      1988 |     9,770      6,628 |    16,398 
      1989 |    12,683     10,308 |    22,991 
      1990 |    25,857     26,252 |    52,109 
      1991 |    54,936     37,613 |    92,549 
      1992 |   103,775     43,236 |   147,011 
      1993 |   144,854     42,572 |   187,426 
      1994 |   184,015     41,396 |   225,411 
      1995 |   215,296     39,996 |   255,292 
      1996 |   250,045     38,369 |   288,414 
      1997 |   283,349     36,982 |   320,331 
      1998 |   321,275     36,021 |   357,296 
      1999 |   345,831     33,084 |   378,915 
      2000 |   375,108     27,793 |   402,901 
      2001 |   404,458     22,470 |   426,928 
      2002 |   425,276     20,766 |   446,042 
      2003 |   444,270     19,541 |   463,811 
      2004 |   470,618     17,682 |   488,300 
      2005 |   489,829     16,396 |   506,225 
      2006 |   508,335     15,493 |   523,828 
      2007 |   515,213     14,852 |   530,065 
      2008 |   553,316     13,433 |   566,749 
      2009 |   580,298     12,229 |   592,527 
      2010 |   597,325     10,774 |   608,099 
      2011 |   607,627      8,145 |   615,772 
      2012 |   608,679      7,891 |   616,570 
      2013 |   616,782      8,259 |   625,041 
      2014 |   622,130      8,198 |   630,328 
      2015 |   617,930      7,416 |   625,346 
      2016 |   596,898      7,148 |   604,046 
      2017 |   576,017      6,740 |   582,757 
      2018 |   553,620      6,357 |   559,977 
-----------+----------------------+----------
     Total |12,115,415    644,040 |12,759,455 
```

## Explore missing expats
From Almos:
```
Régi adat:
greenfield: 3259
expat: 3027
expat and greenfield: 2372

Új adat:
greenfield: 3815
expat: 1152
expat and greenfield: 934
```

```
. use "/Users/koren/Documents/workspace/manager-db/output/manager-panel.dta", clear

. egen ever_expat = max(expat), by(frame_id_numeric )

. tabulate ever_expat 

 ever_expat |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 | 11,467,639       83.16       83.16
          1 |  2,322,742       16.84      100.00
------------+-----------------------------------
      Total | 13,790,381      100.00

. codebook frame_id_numeric if ever_expat 

-------------------------------------------------------------------------------------------------------
frame_id_numeric                                                                            (unlabeled)
-------------------------------------------------------------------------------------------------------

                  type:  numeric (long)

                 range:  [10000599,92457242]          units:  1
         unique values:  144,760                  missing .:  0/2,322,742

                  mean:   1.5e+07
              std. dev:   5.6e+06

           percentiles:        10%       25%       50%       75%       90%
                           1.0e+07   1.1e+07   1.2e+07   2.0e+07   2.4e+07

```

# 2020-05-13
## Check expat
```
. tab pos5  person_foreign 

           |       (firstnm)
           |    person_foreign
      pos5 |         0          1 |     Total
-----------+----------------------+----------
         0 | 2,350,347    214,955 | 2,565,302 
         1 | 9,674,525  1,073,766 |10,748,291 
         2 |   444,557     23,218 |   467,775 
         3 |   344,755     97,976 |   442,731 
-----------+----------------------+----------
     Total |12,814,184  1,409,915 |14,224,099 
```
In ceo-panel, this wasy way fewer. 

```
. tab year expat 

           |         expat
      year |         0          1 |     Total
-----------+----------------------+----------
      1988 |    15,503          0 |    15,503 
      1989 |    21,958          9 |    21,967 
      1990 |    50,416         43 |    50,459 
      1991 |    89,139        161 |    89,300 
      1992 |   138,146        541 |   138,687 
      1993 |   172,145        566 |   172,711 
      1994 |   203,705        697 |   204,402 
      1995 |   228,355        685 |   229,040 
      1996 |   256,740        720 |   257,460 
      1997 |   283,804        823 |   284,627 
      1998 |   315,379        986 |   316,365 
      1999 |   334,024      1,013 |   335,037 
      2000 |   355,054      1,227 |   356,281 
      2001 |   376,892      1,154 |   378,046 
      2002 |   396,556        988 |   397,544 
      2003 |   414,356        989 |   415,345 
      2004 |   437,318      1,128 |   438,446 
      2005 |   453,512      1,166 |   454,678 
      2006 |   470,458      1,245 |   471,703 
      2007 |   478,236      1,081 |   479,317 
      2008 |   514,169      1,464 |   515,633 
      2009 |   541,152      1,493 |   542,645 
      2010 |   559,785      1,629 |   561,414 
      2011 |   569,351      1,988 |   571,339 
      2012 |   571,721      1,328 |   573,049 
      2013 |   580,206      1,110 |   581,316 
      2014 |   584,229        988 |   585,217 
      2015 |   578,705      1,392 |   580,097 
      2016 |   560,967      1,430 |   562,397 
      2017 |   542,504      1,956 |   544,460 
      2018 |   522,636      6,652 |   529,288 
-----------+----------------------+----------
     Total |11,617,121     36,652 |11,653,773 
```
Found a deduplication bug, fixed it, now:
```
. tab year expat 

           |         expat
      year |         0          1 |     Total
-----------+----------------------+----------
      1988 |    15,503        895 |    16,398 
      1989 |    21,958      1,033 |    22,991 
      1990 |    50,416      1,693 |    52,109 
      1991 |    89,139      3,410 |    92,549 
      1992 |   138,146      8,865 |   147,011 
      1993 |   172,145     15,281 |   187,426 
      1994 |   203,705     21,706 |   225,411 
      1995 |   228,355     26,937 |   255,292 
      1996 |   256,740     31,674 |   288,414 
      1997 |   283,804     36,527 |   320,331 
      1998 |   315,379     41,917 |   357,296 
      1999 |   334,024     44,891 |   378,915 
      2000 |   355,054     47,847 |   402,901 
      2001 |   376,892     50,036 |   426,928 
      2002 |   396,556     49,486 |   446,042 
      2003 |   414,356     49,455 |   463,811 
      2004 |   437,318     50,982 |   488,300 
      2005 |   453,512     52,713 |   506,225 
      2006 |   470,458     53,370 |   523,828 
      2007 |   478,236     51,829 |   530,065 
      2008 |   514,169     52,580 |   566,749 
      2009 |   541,152     51,375 |   592,527 
      2010 |   559,785     48,314 |   608,099 
      2011 |   569,351     46,421 |   615,772 
      2012 |   571,721     44,848 |   616,569 
      2013 |   580,206     44,834 |   625,040 
      2014 |   584,229     46,098 |   630,327 
      2015 |   578,705     46,640 |   625,345 
      2016 |   560,967     43,078 |   604,045 
      2017 |   542,504     40,253 |   582,757 
      2018 |   522,636     37,341 |   559,977 
-----------+----------------------+----------
     Total |11,617,121  1,142,329 |12,759,450 
```
