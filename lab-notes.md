# 2020-12-08
## Literatures to connect to
1. Property rights
  - More extreme form of control. Control will be at party who has more to lose from holdup.
    - market -> relational -> vertical -> manager control
  - This is mostly about selection. Who will get acquired? Does not typically discuss impact. 
  - Needs data on parent company.

2. Diff-in-diff effects of foreign ownership
  - Identify the mechanism.

Read:
- Gibbons, Robert. 2005. “Four Formal(izable) Theories of the Firm?” Journal of Economic Behavior & Organization 58 (2): 200–245.
- Aghion, Philippe, and Richard Holden. 2011. “Incomplete Contracts and the Theory of the Firm: What Have We Learned over the Past 25 Years?” The Journal of Economic Perspectives: A Journal of the American Economic Association 25 (2): 181–97.

(Property rights explains why not one huge firm.)

## Data to check
- Easy to steal ("lack of investment in owner-specific")
- Owner country code

## Regressions
1. Diff in diff
2. Selection into acquisition
3. Selection into new manager
4. Selection into expat

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

```
. codebook frame_id_numeric if expat & !greenfield 

-------------------------------------------------------------------------------------------------------
frame_id_numeric                                                                            (unlabeled)
-------------------------------------------------------------------------------------------------------

                  type:  numeric (long)

                 range:  [10000599,52130634]          units:  1
         unique values:  805                      missing .:  0/19,713

                  mean:   1.2e+07
              std. dev:   3.2e+06

           percentiles:        10%       25%       50%       75%       90%
                           1.0e+07   1.0e+07   1.1e+07   1.1e+07   1.3e+07

. reghdfe lnQL foreign during during_foreign during_expat if (before | during ) & !greenfield & !divest
>  , a(teaor08_2d##year frame_id_numeric##manager_id##job_spell age_cat) cluster(frame_id_numeric ) 
(dropped 772 singleton observations)
(MWFE estimator converged in 63 iterations)

HDFE Linear regression                            Number of obs   =    392,911
Absorbing 3 HDFE groups                           F(   4,  14985) =      16.98
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.8551
                                                  Adj R-squared   =     0.8376
                                                  Within R-sq.    =     0.0021
Number of clusters (frame_id_numeric) =     14,986Root MSE        =     0.5894

                    (Std. Err. adjusted for 14,986 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
          lnQL |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
       foreign |   .1300944   .0319562     4.07   0.000     .0674565    .1927324
        during |    -.00721   .0063024    -1.14   0.253    -.0195634    .0051435
during_foreign |   .0912732   .0301953     3.02   0.003     .0320866    .1504598
  during_expat |   .0726678   .0330444     2.20   0.028     .0078967    .1374388
         _cons |   8.737817   .0051292  1703.54   0.000     8.727763    8.747871
--------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------------------------------------+
                               Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------------------------------------+---------------------------------------|
                           teaor08_2d#year |      2137           0        2137     |
     frame_id_numeric#manager_id#job_spell |     40224       40224           0    *|
                                   age_cat |        23           1          22     |
-----------------------------------------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
. reghdfe exporter foreign during during_foreign during_expat if (before | during ) & !greenfield & !di
> vest , a(teaor08_2d##year frame_id_numeric##manager_id##job_spell age_cat) cluster(frame_id_numeric )
>  
(dropped 924 singleton observations)
(MWFE estimator converged in 62 iterations)

HDFE Linear regression                            Number of obs   =    421,218
Absorbing 3 HDFE groups                           F(   4,  16802) =       8.56
Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                  R-squared       =     0.7017
                                                  Adj R-squared   =     0.6659
                                                  Within R-sq.    =     0.0007
Number of clusters (frame_id_numeric) =     16,803Root MSE        =     0.2711

                    (Std. Err. adjusted for 16,803 clusters in frame_id_numeric)
--------------------------------------------------------------------------------
               |               Robust
      exporter |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
       foreign |   .0385324    .011251     3.42   0.001     .0164791    .0605856
        during |   -.010146   .0025776    -3.94   0.000    -.0151984   -.0050937
during_foreign |   .0225595   .0106527     2.12   0.034     .0016791    .0434399
  during_expat |    .012806   .0128447     1.00   0.319    -.0123709    .0379829
         _cons |   .3277783   .0020937   156.55   0.000     .3236744    .3318822
--------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------------------------------------+
                               Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------------------------------------+---------------------------------------|
                           teaor08_2d#year |      2152           0        2152     |
     frame_id_numeric#manager_id#job_spell |     42862       42862           0    *|
                                   age_cat |        23           1          22     |
-----------------------------------------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation
```

# 2020-05-25
## Create firm-year panel
There is no variation bacross years by `max_expat`?
```
. generate max_expat = (N11>0)|(N01>0)

. 
. egen ever_expat = max(max_expat ), by(frame_id_numeric )

. tab ever_expat max_expat 

           |       max_expat
ever_expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   313,259          0 |   313,259 
         1 |         0     56,178 |    56,178 
-----------+----------------------+----------
     Total |   313,259     56,178 |   369,437 

```
I left in all years, not just durings! Now it's good
```
. tab ever_expat max_expat 

           |       max_expat
ever_expat |         0          1 |     Total
-----------+----------------------+----------
         0 |   296,051          0 |   296,051 
         1 |    17,315     36,350 |    53,665 
-----------+----------------------+----------
     Total |   313,366     36,350 |   349,716 
```

Most owners hire 1-2 managers during their tenure. Foreign hire a bit more.
```
. bysort foreign: summarize num_managers_hired if otag, detail

-------------------------------------------------------------------------------------------------------
-> foreign = 0

                     num_managers_hired
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            1              0       Obs              33,362
25%            1              0       Sum of Wgt.      33,362

50%            1                      Mean            1.56987
                        Largest       Std. Dev.      1.225578
75%            2             11
90%            3             11       Variance       1.502042
95%            4             12       Skewness       1.939803
99%            6             12       Kurtosis       8.509304

-------------------------------------------------------------------------------------------------------
-> foreign = 1

                     num_managers_hired
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs               7,322
25%            1              0       Sum of Wgt.       7,322

50%            1                      Mean           2.058454
                        Largest       Std. Dev.      2.001126
75%            3             12
90%            5             12       Variance       4.004505
95%            6             13       Skewness       1.693461
99%            9             13       Kurtosis       6.123739

. table owner_spell foreign if otag, c(mean num_managers_hired )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | 1.620921  2.390058
        2 | .6643519  1.448843
        3 | .8782051  .8451443
        4 |           1.142857
------------------------------
. egen start_as_domestic = max((owner_spell==1) & !foreign), by(frame_id)

. 
. table owner_spell foreign if otag & start_as_domestic , c(mean num_managers_hired )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | 1.620921          
        2 |           1.448843
        3 | .8782051          
        4 |           1.142857
------------------------------
```
If managers in first year are not classified as new hired, than foreign owners are twice as likely to hire a new manager (hazard per year even 4 times as high).
```
. table owner_spell foreign if otag, c(mean num_managers_hired )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | .7196107  1.453197
        2 | .6643519  1.448843
        3 | .8782051  .8451443
        4 |           1.142857
------------------------------

. table owner_spell foreign if otag & start_as_domestic , c(mean num_managers_hired )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | .7196107          
        2 |           1.448843
        3 | .8782051          
        4 |           1.142857
------------------------------

. table owner_spell foreign if otag & start_as_domestic , c(mean num_years )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | 9.115323          
        2 |            7.17018
        3 | 6.533654          
        4 |           7.142857
------------------------------

. table owner_spell foreign if otag & start_as_domestic , c(mean managers_per_year )

------------------------------
owner_spe | (firstnm) foreign 
ll        |        0         1
----------+-------------------
        1 | .0638958          
        2 |           .2511546
        3 | .1896446          
        4 |            .085873
------------------------------

. 
```

```
. tabulate manager_spell foreign if start_as_domestic & owner_spell <= 2,

manager_sp |   (firstnm) foreign
       ell |         0          1 |     Total
-----------+----------------------+----------
         0 |   167,024      3,099 |   170,123 
         1 |    67,036      3,608 |    70,644 
         2 |    27,089      2,592 |    29,681 
         3 |    10,515      1,806 |    12,321 
         4 |     4,279      1,040 |     5,319 
         5 |     1,690        642 |     2,332 
         6 |       644        403 |     1,047 
         7 |       267        217 |       484 
         8 |        99        107 |       206 
         9 |        34         40 |        74 
        10 |        14         10 |        24 
        11 |         5          4 |         9 
-----------+----------------------+----------
     Total |   278,696     13,568 |   292,264 
``` 

Within each owner type: 60 percent of domestic owner-years before the takeover are with the founding CEO. 40 percent of firm-years are with second or more CEOs. After foreign takeovers, 30 percent of firm-years are with the manager inherited from previous owner, another 30 percent with the first hire of the foreign owner.

```
. tabulate within_owner_manager_spell  foreign if start_as_domestic & owner_spell <= 2, column

+-------------------+
| Key               |
|-------------------|
|     frequency     |
| column percentage |
+-------------------+

within_own |
er_manager |   (firstnm) foreign
    _spell |         0          1 |     Total
-----------+----------------------+----------
         0 |   167,024      4,131 |   171,155 
           |     59.93      30.45 |     58.56 
-----------+----------------------+----------
         1 |    67,036      4,137 |    71,173 
           |     24.05      30.49 |     24.35 
-----------+----------------------+----------
         2 |    27,089      2,296 |    29,385 
           |      9.72      16.92 |     10.05 
-----------+----------------------+----------
         3 |    10,515      1,309 |    11,824 
           |      3.77       9.65 |      4.05 
-----------+----------------------+----------
         4 |     4,279        715 |     4,994 
           |      1.54       5.27 |      1.71 
-----------+----------------------+----------
         5 |     1,690        471 |     2,161 
           |      0.61       3.47 |      0.74 
-----------+----------------------+----------
         6 |       644        285 |       929 
           |      0.23       2.10 |      0.32 
-----------+----------------------+----------
         7 |       267        126 |       393 
           |      0.10       0.93 |      0.13 
-----------+----------------------+----------
         8 |        99         61 |       160 
           |      0.04       0.45 |      0.05 
-----------+----------------------+----------
         9 |        34         25 |        59 
           |      0.01       0.18 |      0.02 
-----------+----------------------+----------
        10 |        14          8 |        22 
           |      0.01       0.06 |      0.01 
-----------+----------------------+----------
        11 |         5          4 |         9 
           |      0.00       0.03 |      0.00 
-----------+----------------------+----------
     Total |   278,696     13,568 |   292,264 
           |    100.00     100.00 |    100.00 
```
## How can domestic firms have any expat CEOs?
```
. table within_owner_manager_spell  foreign if start_as_domestic & owner_spell <= 2, c(mean max_expat )

------------------------------
within_ow |
ner_manag | (firstnm) foreign 
er_spell  |        0         1
----------+-------------------
        0 | .0000659   .006778
        1 | .0002834  .4350979
        2 | .0000369  .4751742
        3 | .0003804  .5492743
        4 |        0  .5398601
        5 |        0  .5753716
        6 |        0   .554386
        7 |        0  .5873016
        8 |        0   .557377
        9 |        0       .32
       10 |        0        .5
       11 |        0        .5
------------------------------

. tabulate max_expat foreign  if start_as_domestic & owner_spell <= 2

  Firm has |
 expat CEO |   (firstnm) foreign
   (dummy) |         0          1 |     Total
-----------+----------------------+----------
         0 |   278,661      8,993 |   287,654 
         1 |        35      4,575 |     4,610 
-----------+----------------------+----------
     Total |   278,696     13,568 |   292,264 

. codebook frame_id_numeric  if max_expat==1 & foreign==0 & start_as_domestic & owner_spell <= 2

-------------------------------------------------------------------------------------------------------
frame_id_numeric                                                                            (unlabeled)
-------------------------------------------------------------------------------------------------------

                  type:  numeric (long)

                 range:  [10108264,12394429]          units:  1
         unique values:  5                        missing .:  0/35

            tabulation:  Freq.  Value
                             5  10108264
                            12  10259669
                             8  11169468
                             9  11264783
                             1  12394429

```
These firms might have foreign owners before our sample starts. So they are not purely domestic.
```
. l frame_id_numeric year foreign  if frame_id_numeric == 10259669 

         +---------------------------+
         | frame_~c   year   foreign |
         |---------------------------|
 227994. | 10259669   1989         0 |
 227995. | 10259669   1990         1 |
 227996. | 10259669   1991         1 |
 227997. | 10259669   1992         0 |
 227998. | 10259669   1993         0 |
```

# 2020-05-26
## Discuss firm-year panel

## Manager spells
63,705 changes
27,274 changes
84,070 changes

After bugfix, there are 89,000 changes.

# 2020-06-05
## Main theme
## Parent companies
```
. tab first_year  if ft

 first_year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1990 |         75        3.86        3.86
       1991 |         26        1.34        5.19
       1992 |        109        5.60       10.80
       1993 |        125        6.43       17.22
       1994 |         74        3.80       21.03
       1995 |         82        4.22       25.24
       1996 |         73        3.75       29.00
       1997 |         71        3.65       32.65
       1998 |         94        4.83       37.48
       1999 |         83        4.27       41.75
       2000 |         71        3.65       45.40
       2001 |         56        2.88       48.28
       2002 |         47        2.42       50.69
       2003 |         35        1.80       52.49
       2004 |         50        2.57       55.06
       2005 |         84        4.32       59.38
       2006 |         69        3.55       62.93
       2007 |        101        5.19       68.12
       2008 |        108        5.55       73.68
       2009 |         76        3.91       77.58
       2010 |         51        2.62       80.21
       2011 |         50        2.57       82.78
       2012 |         69        3.55       86.32
       2013 |         38        1.95       88.28
       2014 |         43        2.21       90.49
       2015 |         59        3.03       93.52
       2016 |         47        2.42       95.94
       2017 |         79        4.06      100.00
------------+-----------------------------------
      Total |      1,945      100.00

```

# 2020-12-15
Notes from presentation

18:53:09   From Peter Schott : If a foreign firm does both greenfield and acquisition, would it be included? is that rare?
18:53:48   From Álmos Telegdy : We include firms that start as domestic, and then are acquired by a foreign entity. 
18:54:38   From Álmos Telegdy : It does happen that greenfield firms are divested and acquired again (so they are foreign acquisitions), but this is quite uncommon. 
18:57:27   From Dalia Marin : do you have the countries from which the foreign managers are coming?
18:58:50   From Álmos Telegdy : We have that for some managers, and they seem to come usually from the country of the parent company.
18:59:42   From Peter Schott : are the laborprod, TFP results driven by the addition of lots of capital to the acquired firm?
18:59:47   From Robert : Can you control for capital input?
19:00:22   From Álmos Telegdy : In TFP regressions we control for L,K,M.
19:01:02   From Robert : But not in the labour productivity regressions?
19:01:12   From Álmos Telegdy : Capital is actually not related to the change of the manager. 
19:01:24   From Álmos Telegdy : Not in labor productivity.
19:03:46   From Aksel Erbahar : Does importing play a role? The country imported from might want to install a manager that understands the imported inputs (especially if they are customized)
19:05:20   From Claudia Steinwender : can you distinguish between exports to the HQ (or country of the owner) versus overall exports? do both increase?
19:05:37   From Álmos Telegdy : Good point. What we see is that importing increases with expat managers. But we should check for selection into having an expat as well. 
19:06:01   From Álmos Telegdy : We cannot distinguish between the two kinds of export.

What is the effect of the country of origin?  ERRE TÉNYLEG KONTROLLÁLUNK????
The country of origin may matter for selection into expat. WE MAY WANT TO RUN THIS WITHOUT INDUSTRY EFFECTS (OR LOOK AT INDUSTRY SELECTION).
How trade relations change? 

# 2021-01-22
## Check sample 1992-2003
Before add trade dummies, check all existing results for this sample. #62

Diff-in-diff changes: expats expand employment fast.
```
  (1) (2) (3) (4) (5)
VARIABLES lnL lnQL  TFP_cd  exporter  RperK
          
foreign 0.039 0.121***  0.050***  0.010 0.012***
  (0.035) (0.025) (0.011) (0.017) (0.003)
foreign_hire  -0.077  0.146***  0.021 -0.002  0.008
  (0.060) (0.043) (0.023) (0.022) (0.005)
has_expat 0.145** -0.011  0.003 0.052** -0.016***
  (0.068) (0.049) (0.026) (0.026) (0.006)
          
Observations  111,829 111,829 111,705 111,829 111,386
R-squared 0.778 0.848 0.328 0.722 0.441
Ind-year FE YES YES YES YES YES
Firm FE YES YES YES YES YES
```

Selection equation is very similar to before
```
  (1) (2) (3)
VARIABLES ever_foreign  ever_foreign_hire ever_expat
      
lnL 0.010***  0.007 -0.016
  (0.002) (0.012) (0.014)
exporter  0.030***  0.052 0.073*
  (0.004) (0.032) (0.041)
TFP_cd  -0.003  -0.048* 0.028
  (0.003) (0.028) (0.041)
RperK 0.046***  0.152 -0.242*
  (0.015) (0.119) (0.127)
      
Observations  108,933 5,839 3,883
R-squared 0.095 0.112 0.207
Ind-year FE YES YES YES
```

## Interpret new trade dummies

Expat has an effect on trading with same country, stronger than trading with other country.
```
  (1) (2) (3) (4) (5) (6) (7) (8) (9) (10)
VARIABLES lnL lnQL  TFP_cd  RperK exporter  import_capital  import_material export_same_country import_capital_same_country import_material_same_country
                    
foreign 0.039 0.121***  0.050***  0.012***  0.010 0.077***  0.055***  0.038***  0.042***  0.049***
  (0.035) (0.025) (0.011) (0.003) (0.017) (0.016) (0.015) (0.011) (0.011) (0.014)
foreign_hire  -0.077  0.146***  0.021 0.008 -0.002  -0.022  -0.028  0.012 -0.004  0.022
  (0.060) (0.043) (0.023) (0.005) (0.022) (0.024) (0.022) (0.014) (0.014) (0.017)
has_expat 0.145** -0.011  0.003 -0.016*** 0.052** 0.103***  0.050** 0.054***  0.086***  0.076***
  (0.068) (0.049) (0.026) (0.006) (0.026) (0.028) (0.024) (0.021) (0.020) (0.024)
```

Expat has no effect on trade with other countries
```
  (1) (2) (3) (4) (5) (6)
VARIABLES export_same_country import_capital_same_country import_material_same_country  export_other_country  import_capital_other_country  import_material_other_country
            
foreign 0.038***  0.042***  0.049***  -0.003  0.035** 0.006
  (0.011) (0.011) (0.014) (0.018) (0.016) (0.019)
foreign_hire  0.012 -0.004  0.022 -0.019  -0.017  -0.050*
  (0.014) (0.014) (0.017) (0.024) (0.025) (0.026)
has_expat 0.054***  0.086***  0.076***  -0.025  0.017 -0.026
  (0.021) (0.020) (0.024) (0.030) (0.029) (0.030)
            
Observations  111,829 111,829 111,829 111,829 111,829 111,829
R-squared 0.561 0.482 0.561 0.660 0.580 0.713
Ind-year FE YES YES YES YES YES YES
Firm FE YES YES YES YES YES YES
```

The effects are driven by expats who are from the same country as the owners (and as markets).

# 2021-01-26
## New title and abstract
Foreign Owners and Managers Help Firms Enter Foreign Markets

Most businesses do not engage in foreign trade even though it is associated with positive outcomes such as increased demand, quality upgrading and improved productivity. Small firms do not trade at all, or only trade with a few countries. This suggests that the fixed costs of trading are large. There is, however, little direct evidence on the sources of these fixed costs.

We show that foreign owners and managers facilitate access to their specific home country. We use Hungarian administrative data on the addresses of owners and managers involved in foreign acquisitions in 1992-2003, together with the customs filings of these companies, to study how the direction of trade changes after acquisition and the replacement of management. 

Comparing different markets within the same firm, we find that foreign owners and managers increase the hazard of starting to trade with their home country relative to any other country. The effects are quantitatively large and robust across specification. Our results suggest that information asymmetry is a key part of market access costs. We propose to reevaluate the impact of trade liberalization on firms in light of these findings. 

# 2021-01-27
## Clean up folder
# Suggestions
- Do not mix spells with very different length.
- In transition matrix, report entry and exit, too.

# Nice to have
- Split sample by type of takeover: is parent in same industry as target?
  - use zephyr?
  - use amadeus combined with complex
- Match manager name to offeneregister.de and study experience of expat manager.
- report: nonexporters are better switched to exporting by expat
- young firms for lnQL? 

# 2021-01-28
## Due diligence on country codes
Missing country code is a problem for 21 percent of foreign managers, but only 10 percent of foreign owners. 

```
. use "/Users/koren/Documents/workspace/fo3-owner-names/temp/foreign-name-sample.dta"

. bro

. tabulate country , miss

    country |      Freq.     Percent        Cum.
------------+-----------------------------------
            |        636        9.70        9.70
         AE |          2        0.03        9.73
         AO |          1        0.02        9.75
         AT |      1,003       15.30       25.05
         AU |          5        0.08       25.13
         BA |          2        0.03       25.16
         BE |         55        0.84       26.00
         BG |          5        0.08       26.07
         BS |          6        0.09       26.16
         BY |          1        0.02       26.18
         BZ |         37        0.56       26.74
         CA |         26        0.40       27.14
         CH |        350        5.34       32.48
         CN |          5        0.08       32.56
         CY |        287        4.38       36.93
         CZ |         86        1.31       38.25
         DE |      1,412       21.54       59.79
         DK |         52        0.79       60.58
         DO |          4        0.06       60.64
         EE |          5        0.08       60.72
         EG |          9        0.14       60.85
         ES |         37        0.56       61.42
         FI |         49        0.75       62.17
         FR |        170        2.59       64.76
         GB |        282        4.30       69.06
         GD |          2        0.03       69.09
         GI |          3        0.05       69.14
         GR |          7        0.11       69.24
         GU |          1        0.02       69.26
         GW |          2        0.03       69.29
         GY |          2        0.03       69.32
         HK |          5        0.08       69.40
         HR |         24        0.37       69.76
         HU |          5        0.08       69.84
         IE |         30        0.46       70.30
         IL |         53        0.81       71.11
         IM |          1        0.02       71.12
         IN |         18        0.27       71.40
         IS |         18        0.27       71.67
         IT |        251        3.83       75.50
         JP |         27        0.41       75.91
         KM |          1        0.02       75.93
         KP |          1        0.02       75.94
         KR |          2        0.03       75.97
         KY |          8        0.12       76.09
         KZ |          2        0.03       76.13
         LB |         10        0.15       76.28
         LI |        111        1.69       77.97
         LT |          1        0.02       77.99
         LU |        171        2.61       80.59
         LV |          1        0.02       80.61
         LY |          2        0.03       80.64
         MD |          4        0.06       80.70
         MH |         10        0.15       80.85
         MT |         23        0.35       81.21
         MU |          4        0.06       81.27
         MY |          1        0.02       81.28
         NE |          1        0.02       81.30
         NL |        366        5.58       86.88
         NO |          3        0.05       86.93
         PA |         28        0.43       87.35
         PE |          1        0.02       87.37
         PL |         42        0.64       88.01
         PN |          1        0.02       88.02
         PY |          1        0.02       88.04
         RO |         45        0.69       88.73
         RS |         35        0.53       89.26
         RU |         41        0.63       89.89
         SC |         56        0.85       90.74
         SE |         83        1.27       92.01
         SG |          7        0.11       92.11
         SI |          4        0.06       92.17
         SK |         95        1.45       93.62
         SL |          2        0.03       93.65
         SO |          2        0.03       93.68
         SR |         12        0.18       93.87
         ST |          1        0.02       93.88
         SY |          3        0.05       93.93
         SZ |          2        0.03       93.96
         TH |          5        0.08       94.04
         TN |          1        0.02       94.05
         TR |         18        0.27       94.32
         TW |          5        0.08       94.40
         UA |         49        0.75       95.15
         US |        298        4.55       99.69
         VC |          7        0.11       99.80
         VG |         11        0.17       99.97
         VN |          1        0.02       99.98
         WS |          1        0.02      100.00
------------+-----------------------------------
      Total |      6,555      100.00

. bro

. use "/Users/koren/Tresorit/projects/expat/input/ceo-panel/ceo-panel.dta"

. tabulate country_code if expat, miss

country_cod |
          e |      Freq.     Percent        Cum.
------------+-----------------------------------
            |    241,696       21.16       21.16
         AD |         39        0.00       21.16
         AE |      1,196        0.10       21.27
         AF |         99        0.01       21.27
         AG |         10        0.00       21.28
         AL |        387        0.03       21.31
         AM |        657        0.06       21.37
         AN |        263        0.02       21.39
         AO |         41        0.00       21.39
         AR |        296        0.03       21.42
         AS |         67        0.01       21.43
         AT |     98,064        8.58       30.01
         AU |      3,082        0.27       30.28
         AZ |        246        0.02       30.30
         BA |      1,377        0.12       30.42
         BB |         55        0.00       30.43
         BD |         63        0.01       30.43
         BE |      9,447        0.83       31.26
         BF |          2        0.00       31.26
         BG |      2,675        0.23       31.49
         BH |        571        0.05       31.54
         BI |         22        0.00       31.55
         BJ |          5        0.00       31.55
         BL |         23        0.00       31.55
         BM |         32        0.00       31.55
         BN |         20        0.00       31.55
         BO |        153        0.01       31.57
         BR |        570        0.05       31.62
         BS |        118        0.01       31.63
         BT |         62        0.01       31.63
         BW |         19        0.00       31.63
         BY |        818        0.07       31.70
         BZ |         37        0.00       31.71
         CA |      6,226        0.55       32.25
         CD |         36        0.00       32.26
         CF |          2        0.00       32.26
         CG |         32        0.00       32.26
         CH |     18,447        1.61       33.87
         CI |          9        0.00       33.88
         CL |         96        0.01       33.88
         CM |        110        0.01       33.89
         CN |     82,642        7.23       41.13
         CO |        143        0.01       41.14
         CR |        336        0.03       41.17
         CS |        319        0.03       41.20
         CU |         83        0.01       41.20
         CY |        923        0.08       41.29
         CZ |      8,975        0.79       42.07
         DE |    113,850        9.97       52.04
         DK |      2,205        0.19       52.23
         DM |         70        0.01       52.24
         DO |         86        0.01       52.24
         DZ |        779        0.07       52.31
         EC |         73        0.01       52.32
         EE |        316        0.03       52.35
         EG |      2,340        0.20       52.55
         ER |          7        0.00       52.55
         ES |      8,365        0.73       53.28
         ET |        214        0.02       53.30
         FI |      2,100        0.18       53.49
         FR |     13,811        1.21       54.70
         GA |         36        0.00       54.70
         GB |     22,922        2.01       56.71
         GD |         13        0.00       56.71
         GE |        704        0.06       56.77
         GF |          9        0.00       56.77
         GG |          5        0.00       56.77
         GH |         54        0.00       56.77
         GI |         23        0.00       56.78
         GM |         20        0.00       56.78
         GN |        106        0.01       56.79
         GQ |          1        0.00       56.79
         GR |      2,514        0.22       57.01
         GT |         14        0.00       57.01
         GU |          7        0.00       57.01
         GW |         61        0.01       57.01
         GY |         34        0.00       57.02
         HK |        733        0.06       57.08
         HN |         22        0.00       57.08
         HR |     10,601        0.93       58.01
         ID |        177        0.02       58.03
         IE |     11,061        0.97       59.00
         IL |     24,659        2.16       61.15
         IN |      2,428        0.21       61.37
         IQ |        408        0.04       61.40
         IR |      2,378        0.21       61.61
         IS |        831        0.07       61.68
         IT |     39,584        3.47       65.15
         JM |         11        0.00       65.15
         JO |        866        0.08       65.23
         JP |      2,665        0.23       65.46
         KE |         31        0.00       65.46
         KG |         53        0.00       65.47
         KH |         93        0.01       65.47
         KI |         20        0.00       65.48
         KN |         22        0.00       65.48
         KP |         31        0.00       65.48
         KR |      1,472        0.13       65.61
         KW |        239        0.02       65.63
         KY |         20        0.00       65.63
         KZ |      1,750        0.15       65.79
         LA |          2        0.00       65.79
         LB |        603        0.05       65.84
         LI |        570        0.05       65.89
         LK |         34        0.00       65.89
         LR |         43        0.00       65.89
         LS |         11        0.00       65.90
         LT |        835        0.07       65.97
         LU |      1,176        0.10       66.07
         LV |        574        0.05       66.12
         LY |        593        0.05       66.17
         MA |        159        0.01       66.19
         MC |        316        0.03       66.22
         MD |        953        0.08       66.30
         ME |         37        0.00       66.30
         MG |         38        0.00       66.31
         MK |      1,227        0.11       66.41
         ML |         14        0.00       66.41
         MM |         30        0.00       66.42
         MN |      1,683        0.15       66.56
         MO |        158        0.01       66.58
         MR |          2        0.00       66.58
         MS |          7        0.00       66.58
         MT |        370        0.03       66.61
         MU |         72        0.01       66.62
         MX |        166        0.01       66.63
         MY |        304        0.03       66.66
         MZ |         13        0.00       66.66
         NC |         21        0.00       66.66
         NE |        226        0.02       66.68
         NG |        792        0.07       66.75
         NI |        102        0.01       66.76
         NL |     22,241        1.95       68.71
         NO |      1,111        0.10       68.80
         NP |         56        0.00       68.81
         NR |          7        0.00       68.81
         NZ |        188        0.02       68.83
         OM |         61        0.01       68.83
         PA |         93        0.01       68.84
         PE |         60        0.01       68.84
         PH |        147        0.01       68.86
         PK |        528        0.05       68.90
         PL |      8,374        0.73       69.64
         PS |         11        0.00       69.64
         PT |      1,204        0.11       69.74
         PY |         23        0.00       69.75
         QA |        100        0.01       69.75
         RE |         12        0.00       69.76
         RO |     99,047        8.67       78.43
         RS |     65,268        5.71       84.14
         RU |     35,624        3.12       87.26
         SA |        236        0.02       87.28
         SB |        584        0.05       87.33
         SC |        227        0.02       87.35
         SD |         94        0.01       87.36
         SE |      6,355        0.56       87.91
         SG |        569        0.05       87.96
         SI |      2,280        0.20       88.16
         SK |     25,094        2.20       90.36
         SL |      1,381        0.12       90.48
         SM |      1,485        0.13       90.61
         SN |         64        0.01       90.62
         SO |        141        0.01       90.63
         SR |      4,597        0.40       91.03
         ST |          6        0.00       91.03
         SV |        181        0.02       91.05
         SY |      3,860        0.34       91.39
         SZ |         35        0.00       91.39
         TD |          2        0.00       91.39
         TG |         70        0.01       91.40
         TH |        419        0.04       91.43
         TJ |         16        0.00       91.43
         TM |         14        0.00       91.43
         TN |        255        0.02       91.46
         TO |         13        0.00       91.46
         TR |      8,079        0.71       92.17
         TT |         40        0.00       92.17
         TW |        576        0.05       92.22
         TZ |         69        0.01       92.23
         UA |     54,897        4.81       97.03
         UG |         11        0.00       97.03
         US |     22,075        1.93       98.96
         UY |         69        0.01       98.97
         UZ |        228        0.02       98.99
         VA |        119        0.01       99.00
         VE |        149        0.01       99.01
         VN |     10,631        0.93       99.94
         VU |          8        0.00       99.94
         WS |          1        0.00       99.95
         XK |         12        0.00       99.95
         YE |         37        0.00       99.95
         ZA |        553        0.05      100.00
         ZM |          7        0.00      100.00
         ZW |         19        0.00      100.00
------------+-----------------------------------
      Total |  1,142,329      100.00
```

# 2021-05-19
## Check staggered entry of managers
```
. egen first_year_manager = min(cond(manager==1, year, .)), by(frame_id_numeric country)
(3289221 missing values generated)

. tabulate first_year_manager 

first_year_ |
    manager |      Freq.     Percent        Cum.
------------+-----------------------------------
       1992 |      3,640       17.60       17.60
       1993 |      2,496       12.07       29.67
       1994 |      2,280       11.03       40.70
       1995 |      1,929        9.33       50.03
       1996 |      1,721        8.32       58.35
       1997 |      1,610        7.79       66.13
       1998 |      1,590        7.69       73.82
       1999 |      1,422        6.88       80.70
       2000 |      1,286        6.22       86.92
       2001 |      1,034        5.00       91.92
       2002 |      1,020        4.93       96.85
       2003 |        651        3.15      100.00
------------+-----------------------------------
      Total |     20,679      100.00

. table year, c(mean Lmanager)

--------------------------
Year      |
1992-2018 | mean(Lmanager)
----------+---------------
     1992 |              0
     1993 |        .001504
     1994 |        .002336
     1995 |        .003125
     1996 |        .003658
     1997 |         .00415
     1998 |         .00461
     1999 |        .005045
     2000 |        .005419
     2001 |        .005832
     2002 |        .006009
     2003 |        .006308
--------------------------
```

## Try csdid
```
. egen i = group(frame_id_numeric country )

. mvencode first_year_manager, mv(0)
first_year~r: 3289221 missing values recoded

. csdid export foreign, ivar(i) time(year) gvar(first_year_manager) method(reg)
Time variable can only have 2 values in the working sample
--Break--
r(1);
```

### Alternative versions

```
. reghdfe export foreign manager if inlist(first_year_manager, 0, 1993) & inlist(year, 1992, 1994), a(i year) 
(dropped 146895 singleton observations)
(MWFE estimator converged in 2 iterations)

HDFE Linear regression                            Number of obs   =    316,804
Absorbing 2 HDFE groups                           F(   2, 158399) =      30.37
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.7333
                                                  Adj R-squared   =     0.4665
                                                  Within R-sq.    =     0.0004
                                                  Root MSE        =     0.1331

------------------------------------------------------------------------------
      export |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
     foreign |   .0242483   .0036201     6.70   0.000      .017153    .0313436
     manager |   .1045987   .0290878     3.60   0.000     .0475871    .1616102
       _cons |   .0313433   .0005081    61.68   0.000     .0303474    .0323393
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
           i |    158402           0      158402     |
        year |         2           1           1     |
--
```

First-difference estimator is the same:
```
. xtset i year
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit

. generate d2_export = export - L2.export
(991,150 missing values generated)

. generate d2_foreign = foreign - L2.foreign
(991,150 missing values generated)

. generate d2_manager = manager - L2.manager
(991,150 missing values generated)

. reghdfe d2_export d2_foreign d2_manager if inlist(first_year_manager, 0, 1993) & inlist(year, 1994), a(year) 
(MWFE estimator converged in 1 iterations)

HDFE Linear regression                            Number of obs   =    158,402
Absorbing 1 HDFE group                            F(   2, 158399) =      30.37
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.0004
                                                  Adj R-squared   =     0.0004
                                                  Within R-sq.    =     0.0004
                                                  Root MSE        =     0.1882

------------------------------------------------------------------------------
   d2_export |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
  d2_foreign |   .0242483   .0036201     6.70   0.000      .017153    .0313436
  d2_manager |   .1045987   .0290878     3.60   0.000     .0475871    .1616102
       _cons |   .0029021    .000477     6.08   0.000     .0019672    .0038371
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
        year |         1           0           1     |
-----------------------------------------------------+

```
Can control for differences in country trends:
```
. reghdfe d2_export d2_foreign d2_manager if inlist(first_year_manager, 0, 1993) & inlist(year, 1994), a(country year) 
(MWFE estimator converged in 2 iterations)

HDFE Linear regression                            Number of obs   =    158,402
Absorbing 2 HDFE groups                           F(   2, 158375) =      32.06
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.0068
                                                  Adj R-squared   =     0.0066
                                                  Within R-sq.    =     0.0004
                                                  Root MSE        =     0.1876

------------------------------------------------------------------------------
   d2_export |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
  d2_foreign |   .0240202   .0036088     6.66   0.000      .016947    .0310934
  d2_manager |   .1178869   .0290155     4.06   0.000     .0610171    .1747566
       _cons |   .0029026   .0004755     6.10   0.000     .0019706    .0038346
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
     country |        25           0          25     |
        year |         1           1           0     |
-----------------------------------------------------+
```
or even firm fixed effect:
```
. reghdfe d2_export d2_manager if inlist(first_year_manager, 0, 1993) & inlist(year, 1994), a(frame_id_numeric country year) 
(MWFE estimator converged in 4 iterations)

HDFE Linear regression                            Number of obs   =    158,402
Absorbing 3 HDFE groups                           F(   1, 152012) =       9.55
                                                  Prob > F        =     0.0020
                                                  R-squared       =     0.1060
                                                  Adj R-squared   =     0.0684
                                                  Within R-sq.    =     0.0001
                                                  Root MSE        =     0.1817

------------------------------------------------------------------------------
   d2_export |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
  d2_manager |   .0885173   .0286383     3.09   0.002     .0323867    .1446478
       _cons |   .0033288   .0004565     7.29   0.000      .002434    .0042235
------------------------------------------------------------------------------

Absorbed degrees of freedom:
----------------------------------------------------------+
      Absorbed FE | Categories  - Redundant  = Num. Coefs |
------------------+---------------------------------------|
 frame_id_numeric |      6365           0        6365     |
          country |        25           1          24     |
             year |         1           1           0    ?|
----------------------------------------------------------+
? = number of redundant parameters may be higher
```
Can add not-yet-treated to the controls:
```
. reghdfe d2_export d2_manager if (inlist(first_year_manager, 0, 1993) | first_year_manager > 1994) & inlist(year, 1994), a(frame_id_numeric country
>  year) 
(MWFE estimator converged in 3 iterations)

HDFE Linear regression                            Number of obs   =    158,720
Absorbing 3 HDFE groups                           F(   1, 152330) =       9.21
                                                  Prob > F        =     0.0024
                                                  R-squared       =     0.1056
                                                  Adj R-squared   =     0.0681
                                                  Within R-sq.    =     0.0001
                                                  Root MSE        =     0.1823

------------------------------------------------------------------------------
   d2_export |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
  d2_manager |   .0872117   .0287302     3.04   0.002      .030901    .1435224
       _cons |   .0034232   .0004576     7.48   0.000     .0025264    .0043201
------------------------------------------------------------------------------
```

## Rewrite csadid.ado
```
.  csadid export foreign, treatment(manager) absorb(frame_id_numeric )
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit

. summarize ATT_gt if manager 

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      ATT_gt |      8,119   -.0155202    .0963486  -.2140384   .1495977

. csadid export, treatment(manager)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit

. summarize ATT_gt if manager 

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      ATT_gt |      8,119    .0125299    .1032525  -.2159674   .1930342

```

```
. csadid export, treatment(manager) absorb(cc frame_id_numeric)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
g1992        |
 t_1992_1993 |  -.0021727   .0233414    -0.09   0.926    -.0479211    .0435756
 t_1992_1994 |   .0601994   .0270761     2.22   0.026     .0071313    .1132675
 t_1992_1995 |   .0587084   .0304766     1.93   0.054    -.0010246    .1184414
 t_1992_1996 |   .0776701   .0302962     2.56   0.010     .0182905    .1370496
 t_1992_1997 |   .0899351   .0315509     2.85   0.004     .0280964    .1517737
 t_1992_1998 |   .0421198   .0320793     1.31   0.189    -.0207544    .1049941
 t_1992_1999 |   .0157794   .0337097     0.47   0.640    -.0502903    .0818491
 t_1992_2000 |   .0030498   .0350082     0.09   0.931     -.065565    .0716647
 t_1992_2001 |   .0361096   .0371456     0.97   0.331    -.0366945    .1089137
 t_1992_2002 |   .0639793   .0381444     1.68   0.093    -.0107824    .1387409
 t_1992_2003 |  -.0028263   .0406808    -0.07   0.945    -.0825592    .0769066
-------------+----------------------------------------------------------------
g1993        |
 t_1993_1992 |  -.0443191   .0240484    -1.84   0.065    -.0914532    .0028149
 t_1993_1994 |  -.0122204   .0193702    -0.63   0.528    -.0501852    .0257444
 t_1993_1995 |   .0366973   .0226092     1.62   0.105     -.007616    .0810106
 t_1993_1996 |  -.0644331   .0228589    -2.82   0.005    -.1092357   -.0196306
 t_1993_1997 |  -.1598373   .0236912    -6.75   0.000    -.2062713   -.1134034
 t_1993_1998 |  -.0952647   .0249568    -3.82   0.000    -.1441792   -.0463503
 t_1993_1999 |   -.194848   .0258496    -7.54   0.000    -.2455124   -.1441836
 t_1993_2000 |  -.1201834   .0271189    -4.43   0.000    -.1733354   -.0670315
 t_1993_2001 |  -.1003027   .0294284    -3.41   0.001    -.1579813   -.0426242
 t_1993_2002 |  -.0799435   .0301092    -2.66   0.008    -.1389565   -.0209304
 t_1993_2003 |  -.0652975   .0309337    -2.11   0.035    -.1259265   -.0046684
-------------+----------------------------------------------------------------
g1994        |
 t_1994_1992 |  -.1155024   .0260227    -4.44   0.000     -.166506   -.0644987
 t_1994_1993 |  -.0478375   .0189561    -2.52   0.012    -.0849908   -.0106842
 t_1994_1995 |  -.0096714   .0175002    -0.55   0.581    -.0439712    .0246284
 t_1994_1996 |  -.0887599   .0194217    -4.57   0.000    -.1268258    -.050694
 t_1994_1997 |  -.1343928   .0209826    -6.40   0.000    -.1755179   -.0932677
 t_1994_1998 |   -.135048   .0220692    -6.12   0.000    -.1783029   -.0917932
 t_1994_1999 |  -.0852897   .0238203    -3.58   0.000    -.1319765   -.0386028
 t_1994_2000 |  -.1606403   .0257489    -6.24   0.000    -.2111073   -.1101733
 t_1994_2001 |  -.0832303   .0269037    -3.09   0.002    -.1359606      -.0305
 t_1994_2002 |  -.0826259   .0278395    -2.97   0.003    -.1371904   -.0280615
 t_1994_2003 |  -.0656745   .0300465    -2.19   0.029    -.1245645   -.0067845
-------------+----------------------------------------------------------------
g1995        |
 t_1995_1992 |   -.143104   .0304682    -4.70   0.000    -.2028206   -.0833874
 t_1995_1993 |  -.0588127    .025938    -2.27   0.023    -.1096503   -.0079751
 t_1995_1994 |  -.1209655    .021286    -5.68   0.000    -.1626854   -.0792456
 t_1995_1996 |  -.0162529   .0194337    -0.84   0.403    -.0543423    .0218364
 t_1995_1997 |   -.066332   .0216538    -3.06   0.002    -.1087726   -.0238914
 t_1995_1998 |   -.080765   .0228938    -3.53   0.000     -.125636    -.035894
 t_1995_1999 |   -.081969   .0242298    -3.38   0.001    -.1294586   -.0344793
 t_1995_2000 |  -.1490186   .0259218    -5.75   0.000    -.1998244   -.0982128
 t_1995_2001 |  -.0234851   .0271498    -0.87   0.387    -.0766977    .0297274
 t_1995_2002 |  -.0517614   .0281929    -1.84   0.066    -.1070185    .0034957
 t_1995_2003 |   -.086657   .0293894    -2.95   0.003    -.1442591   -.0290548
-------------+----------------------------------------------------------------
g1996        |
 t_1996_1992 |  -.0088834   .0343871    -0.26   0.796    -.0762808     .058514
 t_1996_1993 |   .0999348    .027956     3.57   0.000      .045142    .1547277
 t_1996_1994 |   .0579054   .0237636     2.44   0.015     .0113297    .1044812
 t_1996_1995 |  -.0266018   .0203091    -1.31   0.190    -.0664068    .0132033
 t_1996_1997 |    .039739    .015208     2.61   0.009     .0099319    .0695462
 t_1996_1998 |   .0210819   .0175624     1.20   0.230    -.0133398    .0555035
 t_1996_1999 |   .0204773   .0203326     1.01   0.314    -.0193739    .0603285
 t_1996_2000 |   .0246295   .0218385     1.13   0.259    -.0181731    .0674321
 t_1996_2001 |   .0330563   .0235256     1.41   0.160     -.013053    .0791655
 t_1996_2002 |    .068584   .0252497     2.72   0.007     .0190955    .1180724
 t_1996_2003 |   .0178731   .0264601     0.68   0.499    -.0339878     .069734
-------------+----------------------------------------------------------------
g1997        |
 t_1997_1992 |  -.0398964   .0307835    -1.30   0.195    -.1002308    .0204381
 t_1997_1993 |   .0083993    .027433     0.31   0.759    -.0453683    .0621669
 t_1997_1994 |   .0472154   .0240844     1.96   0.050      .000011    .0944199
 t_1997_1995 |   .0167731   .0228616     0.73   0.463    -.0280348    .0615811
 t_1997_1996 |   .0089502   .0158268     0.57   0.572    -.0220697    .0399702
 t_1997_1998 |   .0300878    .014074     2.14   0.033     .0025032    .0576724
 t_1997_1999 |   .0234995   .0164426     1.43   0.153    -.0087273    .0557263
 t_1997_2000 |   .0193658    .018536     1.04   0.296     -.016964    .0556957
 t_1997_2001 |   .0571279   .0205181     2.78   0.005     .0169132    .0973427
 t_1997_2002 |   .0401783   .0224405     1.79   0.073    -.0038044     .084161
 t_1997_2003 |   .0847198   .0230471     3.68   0.000     .0395483    .1298913
-------------+----------------------------------------------------------------
g1998        |
 t_1998_1992 |   .0717708   .0334865     2.14   0.032     .0061385    .1374031
 t_1998_1993 |  -.0209922   .0282498    -0.74   0.457    -.0763607    .0343763
 t_1998_1994 |  -.0989435   .0246435    -4.02   0.000    -.1472438   -.0506432
 t_1998_1995 |  -.0948341     .02276    -4.17   0.000    -.1394428   -.0502254
 t_1998_1996 |  -.0405537   .0173403    -2.34   0.019      -.07454   -.0065674
 t_1998_1997 |  -.0459247   .0146476    -3.14   0.002    -.0746334    -.017216
 t_1998_1999 |    .011523   .0138302     0.83   0.405    -.0155836    .0386297
 t_1998_2000 |   .0113445   .0164757     0.69   0.491    -.0209473    .0436364
 t_1998_2001 |   .0274044   .0184135     1.49   0.137    -.0086854    .0634942
 t_1998_2002 |   .0413463   .0200054     2.07   0.039     .0021364    .0805562
 t_1998_2003 |   .0642694   .0218357     2.94   0.003     .0214723    .1070665
-------------+----------------------------------------------------------------
g1999        |
 t_1999_1992 |  -.0144608   .0369271    -0.39   0.695    -.0868365    .0579149
 t_1999_1993 |   .1047991   .0304953     3.44   0.001     .0450294    .1645688
 t_1999_1994 |   .0712968   .0270406     2.64   0.008     .0182981    .1242954
 t_1999_1995 |    .058003   .0257164     2.26   0.024     .0075998    .1084063
 t_1999_1996 |  -.0387115    .020492    -1.89   0.059     -.078875     .001452
 t_1999_1997 |  -.0537174    .017876    -3.01   0.003    -.0887537   -.0186811
 t_1999_1998 |  -.0340115   .0153423    -2.22   0.027    -.0640819   -.0039411
 t_1999_2000 |   .0320163   .0144788     2.21   0.027     .0036385    .0603942
 t_1999_2001 |   .0703678   .0173163     4.06   0.000     .0364285     .104307
 t_1999_2002 |   -.011234   .0197259    -0.57   0.569     -.049896     .027428
 t_1999_2003 |   .0251771    .021819     1.15   0.249    -.0175874    .0679416
-------------+----------------------------------------------------------------
g2000        |
 t_2000_1992 |  -.0120678   .0385085    -0.31   0.754    -.0875431    .0634074
 t_2000_1993 |  -.0034329   .0326285    -0.11   0.916    -.0673837    .0605178
 t_2000_1994 |  -.0760464   .0305702    -2.49   0.013     -.135963   -.0161298
 t_2000_1995 |  -.1244169   .0299523    -4.15   0.000    -.1831222   -.0657115
 t_2000_1996 |  -.0660065   .0250164    -2.64   0.008    -.1150378   -.0169752
 t_2000_1997 |  -.0520808   .0213112    -2.44   0.015    -.0938499   -.0103117
 t_2000_1998 |  -.0625072   .0186216    -3.36   0.001    -.0990047   -.0260096
 t_2000_1999 |  -.0176379   .0157171    -1.12   0.262    -.0484428     .013167
 t_2000_2001 |   .0322161   .0152645     2.11   0.035     .0022982     .062134
 t_2000_2002 |   .0773906   .0184405     4.20   0.000     .0412479    .1135333
 t_2000_2003 |   .0672768    .020038     3.36   0.001     .0280031    .1065506
-------------+----------------------------------------------------------------
g2001        |
 t_2001_1992 |  -.0798915    .043618    -1.83   0.067    -.1653812    .0055982
 t_2001_1993 |    -.04552   .0357318    -1.27   0.203     -.115553    .0245131
 t_2001_1994 |  -.1134761   .0317403    -3.58   0.000     -.175686   -.0512662
 t_2001_1995 |  -.0573441   .0301812    -1.90   0.057    -.1164981    .0018099
 t_2001_1996 |  -.0758579   .0245756    -3.09   0.002    -.1240252   -.0276906
 t_2001_1997 |   -.074342   .0215845    -3.44   0.001     -.116647   -.0320371
 t_2001_1998 |  -.0923371   .0200499    -4.61   0.000    -.1316342     -.05304
 t_2001_1999 |  -.0305492   .0177715    -1.72   0.086    -.0653807    .0042822
 t_2001_2000 |  -.0163271   .0151003    -1.08   0.280    -.0459231    .0132688
 t_2001_2002 |   .0942785   .0142307     6.63   0.000     .0663869    .1221702
 t_2001_2003 |   .0784626   .0164769     4.76   0.000     .0461684    .1107567
-------------+----------------------------------------------------------------
g2002        |
 t_2002_1992 |  -.1154185   .0494917    -2.33   0.020    -.2124205   -.0184165
 t_2002_1993 |  -.0696734   .0421706    -1.65   0.098    -.1523262    .0129795
 t_2002_1994 |  -.0527804    .037239    -1.42   0.156    -.1257674    .0202067
 t_2002_1995 |   .0356422   .0341562     1.04   0.297    -.0313027    .1025871
 t_2002_1996 |  -.1076778    .029906    -3.60   0.000    -.1662924   -.0490632
 t_2002_1997 |  -.1429661   .0284918    -5.02   0.000    -.1988089   -.0871232
 t_2002_1998 |  -.0857289   .0261804    -3.27   0.001    -.1370416   -.0344161
 t_2002_1999 |  -.0202509   .0236956    -0.85   0.393    -.0666933    .0261916
 t_2002_2000 |   .0019808   .0212113     0.09   0.926    -.0395927    .0435543
 t_2002_2001 |  -.0452224   .0182087    -2.48   0.013    -.0809108   -.0095341
 t_2002_2003 |  -.0152261    .016677    -0.91   0.361    -.0479125    .0174602
------------------------------------------------------------------------------
```

# 2021-05-20
## Experiment with Lexport
```
. csadid Lexport if year <= 1999 & (first_manager <= 1997 | missing(first_manager)) , treatment(manager) absorb(cc frame_id_numeric)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
g1992        |
     manager |
      L1993. |   .2241591   .0223373    10.04   0.000     .1803788    .2679394
      L1994. |   .2270748   .0273302     8.31   0.000     .1735087     .280641
      L1995. |   .2720631   .0317266     8.58   0.000     .2098801     .334246
      L1996. |   .3452787   .0347389     9.94   0.000     .2771917    .4133658
      L1997. |   .3676974   .0364376    10.09   0.000      .296281    .4391138
      L1998. |   .4502792   .0372596    12.08   0.000     .3772519    .5233066
      L1999. |   .4371834   .0398524    10.97   0.000     .3590741    .5152928
-------------+----------------------------------------------------------------
g1993        |
     manager |
      L1992. |  -.3636161   .0230182   -15.80   0.000     -.408731   -.3185012
      L1994. |   .1080969   .0157577     6.86   0.000     .0772124    .1389814
      L1995. |   .1500086   .0202268     7.42   0.000     .1103647    .1896524
      L1996. |    .129054   .0236222     5.46   0.000     .0827553    .1753527
      L1997. |    .119919   .0250119     4.79   0.000     .0708966    .1689414
      L1998. |   .0974074   .0266878     3.65   0.000     .0451003    .1497146
      L1999. |   .1043948   .0285314     3.66   0.000     .0484743    .1603153
-------------+----------------------------------------------------------------
g1994        |
     manager |
      L1992. |  -.3304273   .0262687   -12.58   0.000    -.3819129   -.2789417
      L1993. |  -.1440006   .0154345    -9.33   0.000    -.1742517   -.1137494
      L1995. |   .0637001   .0131151     4.86   0.000      .037995    .0894051
      L1996. |   .0948447   .0173427     5.47   0.000     .0608537    .1288356
      L1997. |   .1073547   .0195846     5.48   0.000     .0689696    .1457398
      L1998. |   .1056666   .0213514     4.95   0.000     .0638185    .1475146
      L1999. |   .1491466   .0240169     6.21   0.000     .1020745    .1962188
-------------+----------------------------------------------------------------
g1995        |
     manager |
      L1992. |  -.4279598    .031729   -13.49   0.000    -.4901475   -.3657722
      L1993. |  -.0001692   .0232097    -0.01   0.994    -.0456594     .045321
      L1994. |  -.0192271    .015945    -1.21   0.228    -.0504787    .0120244
      L1996. |    .069762    .013464     5.18   0.000     .0433731    .0961509
      L1997. |   .0825182   .0166895     4.94   0.000     .0498074     .115229
      L1998. |   .0814514   .0189863     4.29   0.000      .044239    .1186638
      L1999. |    .105656   .0214755     4.92   0.000     .0635648    .1477471
-------------+----------------------------------------------------------------
g1996        |
     manager |
      L1992. |  -.2980959   .0394539    -7.56   0.000    -.3754242   -.2207676
      L1993. |  -.1179495   .0288971    -4.08   0.000    -.1745867   -.0613123
      L1994. |  -.0478687   .0212213    -2.26   0.024    -.0894616   -.0062757
      L1995. |   .0169028     .01406     1.20   0.229    -.0106543    .0444599
      L1997. |   .0847707   .0096214     8.81   0.000     .0659132    .1036283
      L1998. |   .1215889   .0131282     9.26   0.000      .095858    .1473198
      L1999. |   .1455636   .0170502     8.54   0.000     .1121458    .1789813
------------------------------------------------------------------------------
```
Even among ever_foreign firms, there are strong pretrends.
```
. csadid Lexport if ever_foreign & year <= 1999 & (first_manager <= 1999 | missing(first_manager)) , treatment(manager) absorb(cc frame_id_numeric) 
> notyet
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
manager_1992 |
     Lexport |
         F1. |   .1817342   .0297199     6.11   0.000     .1234843    .2399841
         F2. |   .1508607   .0362964     4.16   0.000     .0797211    .2220003
         F3. |   .2109924   .0419239     5.03   0.000     .1288232    .2931617
         F4. |   .2832793   .0460299     6.15   0.000     .1930624    .3734961
         F5. |   .3103002   .0481253     6.45   0.000     .2159764     .404624
         F6. |   .3964981   .0491799     8.06   0.000     .3001072    .4928889
         F7. |   .3815503   .0529272     7.21   0.000     .2778149    .4852857
-------------+----------------------------------------------------------------
manager_1993 |
     Lexport |
         L1. |  -.2989661   .0298609   -10.01   0.000    -.3574924   -.2404398
         F1. |   .0958138   .0221122     4.33   0.000     .0524748    .1391529
         F2. |   .1356096   .0281582     4.82   0.000     .0804205    .1907986
         F3. |   .1110359   .0328108     3.38   0.001     .0467278     .175344
         F4. |   .1024317   .0348644     2.94   0.003     .0340987    .1707648
         F5. |    .075379   .0367424     2.05   0.040     .0033652    .1473927
         F6. |   .0799835    .039264     2.04   0.042     .0030275    .1569395
-------------+----------------------------------------------------------------
manager_1994 |
     Lexport |
         L2. |  -.2626504   .0340712    -7.71   0.000    -.3294288   -.1958719
         L1. |  -.1173732    .021592    -5.44   0.000    -.1596928   -.0750535
         F1. |   .0542504   .0179524     3.02   0.003     .0190644    .0894364
         F2. |   .0820886   .0239767     3.42   0.001     .0350951    .1290822
         F3. |   .0922517    .027098     3.40   0.001     .0391405    .1453629
         F4. |   .0891054   .0294348     3.03   0.002     .0314142    .1467966
         F5. |   .1362128   .0330608     4.12   0.000     .0714148    .2010108
-------------+----------------------------------------------------------------
manager_1995 |
     Lexport |
         L3. |  -.3613167   .0413044    -8.75   0.000    -.4422718   -.2803617
         L2. |   .0215858   .0320123     0.67   0.500    -.0411571    .0843288
         L1. |   -.004954   .0216596    -0.23   0.819     -.047406    .0374981
         F1. |   .0612765   .0191346     3.20   0.001     .0237733    .0987797
         F2. |   .0695491    .023626     2.94   0.003      .023243    .1158551
         F3. |   .0678204    .026601     2.55   0.011     .0156834    .1199573
         F4. |   .0925762   .0298104     3.11   0.002     .0341489    .1510035
-------------+----------------------------------------------------------------
manager_1996 |
     Lexport |
         L4. |  -.2496573   .0514568    -4.85   0.000    -.3505108   -.1488038
         L3. |  -.1008888   .0396928    -2.54   0.011    -.1786852   -.0230924
         L2. |  -.0341262   .0290695    -1.17   0.240    -.0911013    .0228489
         L1. |   .0235359   .0199298     1.18   0.238    -.0155258    .0625977
         F1. |   .0784613   .0140406     5.59   0.000     .0509422    .1059804
         F2. |   .1126218   .0189663     5.94   0.000     .0754484    .1497951
         F3. |    .137694    .024017     5.73   0.000     .0906215    .1847664
-------------+----------------------------------------------------------------
manager_1997 |
     Lexport |
         L5. |  -.1523576   .0462744    -3.29   0.001    -.2430539   -.0616614
         L4. |  -.0800349   .0399197    -2.00   0.045    -.1582761   -.0017938
         L3. |  -.0523875   .0307907    -1.70   0.089    -.1127362    .0079612
         L2. |  -.0285703   .0248877    -1.15   0.251    -.0773492    .0202086
         L1. |  -.0049024   .0145451    -0.34   0.736    -.0334103    .0236055
         F1. |   .0328453   .0127736     2.57   0.010     .0078095     .057881
         F2. |   .0754254   .0175242     4.30   0.000     .0410787    .1097721
-------------+----------------------------------------------------------------
manager_1998 |
     Lexport |
         L6. |  -.1217334   .0506191    -2.40   0.016    -.2209451   -.0225217
         L5. |   .1110363   .0415134     2.67   0.007     .0296715    .1924011
         L4. |   .0660343   .0325862     2.03   0.043     .0021666     .129902
         L3. |  -.0348702   .0264063    -1.32   0.187    -.0866257    .0168853
         L2. |  -.0536571   .0186926    -2.87   0.004    -.0902939   -.0170204
         L1. |  -.0171691   .0132044    -1.30   0.194    -.0430493    .0087111
         F1. |   .0416703   .0118466     3.52   0.000     .0184513    .0648893
------------------------------------------------------------------------------
```
Among ever exporters, pretrends equally strong:
```
. egen ever_export = max(export), by(frame_id_numeric )

. csadid Lexport if ever_foreign & ever_export & year <= 1999 & (first_manager <= 1999 | missing(first_manager)) , treatment(Lmanager) absorb(cc fra
> me_id_numeric) notyet
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
-------------------------------------------------------------------------------
              |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
--------------+----------------------------------------------------------------
Lmanager_1992 |
      Lexport |
          F1. |   .2969234   .0136493    21.75   0.000     .2701712    .3236756
          F2. |   .3209074   .0161563    19.86   0.000     .2892416    .3525732
          F3. |   .3568295   .0178186    20.03   0.000     .3219056    .3917534
          F4. |   .3573283    .019539    18.29   0.000     .3190326    .3956241
          F5. |   .3794401   .0203634    18.63   0.000     .3395287    .4193516
          F6. |   .3712695   .0209929    17.69   0.000     .3301242    .4124147
          F7. |   .3770446   .0219315    17.19   0.000     .3340595    .4200296
--------------+----------------------------------------------------------------
Lmanager_1993 |
      Lexport |
          L1. |  -.1890033   .0378278    -5.00   0.000    -.2631445   -.1148621
          F1. |   .3154408   .0141246    22.33   0.000     .2877571    .3431246
          F2. |   .3903788   .0179391    21.76   0.000     .3552189    .4255388
          F3. |   .4298195   .0209765    20.49   0.000     .3887063    .4709328
          F4. |   .4470248   .0225241    19.85   0.000     .4028783    .4911713
          F5. |   .5089789   .0235951    21.57   0.000     .4627334    .5552244
          F6. |   .4920126   .0250609    19.63   0.000     .4428941    .5411311
--------------+----------------------------------------------------------------
Lmanager_1994 |
      Lexport |
          L2. |  -.2948529    .036896    -7.99   0.000    -.3671677   -.2225382
          L1. |  -.1053515   .0258121    -4.08   0.000    -.1559424   -.0547607
          F1. |   .3094007   .0130719    23.67   0.000     .2837802    .3350211
          F2. |   .3952461    .017276    22.88   0.000     .3613857    .4291065
          F3. |   .3976003    .019066    20.85   0.000     .3602316    .4349691
          F4. |   .3835455   .0203457    18.85   0.000     .3436686    .4234224
          F5. |   .3733755   .0217836    17.14   0.000     .3306803    .4160706
--------------+----------------------------------------------------------------
Lmanager_1995 |
      Lexport |
          L3. |  -.2842114   .0440192    -6.46   0.000    -.3704874   -.1979355
          L2. |  -.1545045   .0324539    -4.76   0.000     -.218113    -.090896
          L1. |  -.0665735   .0223069    -2.98   0.003    -.1102943   -.0228528
          F1. |   .3033584   .0136195    22.27   0.000     .2766648    .3300521
          F2. |   .3302493   .0166801    19.80   0.000     .2975568    .3629417
          F3. |   .3147961   .0188226    16.72   0.000     .2779045    .3516876
          F4. |   .3614566   .0206866    17.47   0.000     .3209115    .4020016
--------------+----------------------------------------------------------------
Lmanager_1996 |
      Lexport |
          L4. |  -.3348864   .0479234    -6.99   0.000    -.4288145   -.2409583
          L3. |   .0184837   .0410253     0.45   0.652    -.0619243    .0988918
          L2. |  -.0077895    .032311    -0.24   0.809    -.0711179    .0555389
          L1. |  -.0353877   .0228579    -1.55   0.122    -.0801884    .0094131
          F1. |   .2300862   .0108679    21.17   0.000     .2087855    .2513868
          F2. |   .2948616    .014631    20.15   0.000     .2661854    .3235378
          F3. |   .3583457   .0173509    20.65   0.000     .3243387    .3923528
--------------+----------------------------------------------------------------
Lmanager_1997 |
      Lexport |
          L5. |  -.2325572   .0581724    -4.00   0.000    -.3465729   -.1185414
          L4. |  -.1211056   .0487113    -2.49   0.013    -.2165779   -.0256333
          L3. |  -.0495295   .0376454    -1.32   0.188    -.1233132    .0242542
          L2. |   .0090199   .0283906     0.32   0.751    -.0466245    .0646644
          L1. |  -.0901018   .0169624    -5.31   0.000    -.1233475    -.056856
          F1. |   .2549277   .0104677    24.35   0.000     .2344115     .275444
          F2. |   .3555517   .0142602    24.93   0.000     .3276022    .3835012
--------------+----------------------------------------------------------------
Lmanager_1998 |
      Lexport |
          L6. |  -.1853721   .0509592    -3.64   0.000    -.2852503   -.0854939
          L5. |  -.1024549   .0474601    -2.16   0.031    -.1954749   -.0094349
          L4. |   -.064054    .036597    -1.75   0.080    -.1357829    .0076748
          L3. |  -.0371915    .032578    -1.14   0.254    -.1010431    .0266602
          L2. |  -.0402584   .0232387    -1.73   0.083    -.0858053    .0052886
          L1. |  -.0260793   .0166691    -1.56   0.118    -.0587502    .0065916
          F1. |   .2478526    .010421    23.78   0.000     .2274278    .2682773
--------------+----------------------------------------------------------------
Lmanager_1999 |
      Lexport |
          L7. |  -.1480863   .0567055    -2.61   0.009    -.2592269   -.0369456
          L6. |   .0644019    .048744     1.32   0.186    -.0311346    .1599383
          L5. |   .0085719   .0401077     0.21   0.831    -.0700377    .0871815
          L4. |  -.0893483   .0334308    -2.67   0.008    -.1548716   -.0238251
          L3. |  -.1129533   .0261529    -4.32   0.000    -.1642121   -.0616945
          L2. |  -.0739093   .0212851    -3.47   0.001    -.1156273   -.0321914
          L1. |  -.0544047   .0152908    -3.56   0.000    -.0843741   -.0244353
-------------------------------------------------------------------------------
```
Is this a timing issue? Yes, but why are the numbers much smaller?
```
. generate after_export = Lexport | export

. csadid after_export if year <= 1999, treatment(manager) absorb(cc frame_id_numeric) notyet
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
manager_1992 |
after_export |
         F1. |    .028867   .0163627     1.76   0.078    -.0032033    .0609372
         F2. |   .0619436   .0224623     2.76   0.006     .0179183    .1059689
         F3. |   .0872683   .0277374     3.15   0.002      .032904    .1416326
         F4. |   .1617088   .0302573     5.34   0.000     .1024056    .2210121
         F5. |   .2242626   .0323499     6.93   0.000      .160858    .2876673
         F6. |   .2115142   .0337715     6.26   0.000     .1453232    .2777052
         F7. |   .1947857   .0364499     5.34   0.000     .1233451    .2662263
-------------+----------------------------------------------------------------
manager_1993 |
after_export |
         L1. |  -.0605284   .0168436    -3.59   0.000    -.0935412   -.0275155
         F1. |   .0437342   .0136219     3.21   0.001     .0170356    .0704327
         F2. |   .0343862    .018618     1.85   0.065    -.0021045    .0708769
         F3. |   .0203704   .0210399     0.97   0.333    -.0208671    .0616079
         F4. |  -.0141228   .0226692    -0.62   0.533    -.0585537     .030308
         F5. |  -.0157635   .0246497    -0.64   0.522     -.064076    .0325491
         F6. |  -.0200303   .0265257    -0.76   0.450    -.0720197    .0319591
-------------+----------------------------------------------------------------
manager_1994 |
after_export |
         L2. |  -.0728137   .0215682    -3.38   0.001    -.1150867   -.0305408
         L1. |  -.0372346   .0133268    -2.79   0.005    -.0633546   -.0111146
         F1. |   .0199282   .0117278     1.70   0.089    -.0030578    .0429143
         F2. |   .0283902   .0147108     1.93   0.054    -.0004425    .0572228
         F3. |   .0177069   .0172433     1.03   0.304    -.0160893    .0515031
         F4. |   .0450177   .0192793     2.34   0.020      .007231    .0828044
         F5. |   .0495716     .02204     2.25   0.025      .006374    .0927692
-------------+----------------------------------------------------------------
manager_1995 |
after_export |
         L3. |  -.0597397    .027718    -2.16   0.031    -.1140659   -.0054135
         L2. |  -.0019291   .0213608    -0.09   0.928    -.0437955    .0399373
         L1. |  -.0302316   .0142613    -2.12   0.034    -.0581832   -.0022801
         F1. |   .0327185   .0096666     3.38   0.001     .0137724    .0516646
         F2. |   .0463247   .0136492     3.39   0.001     .0195728    .0730766
         F3. |   .0322342   .0164626     1.96   0.050    -.0000319    .0645004
         F4. |   .0234867   .0191555     1.23   0.220    -.0140574    .0610308
-------------+----------------------------------------------------------------
manager_1996 |
after_export |
         L4. |  -.0566683   .0343293    -1.65   0.099    -.1239525    .0106159
         L3. |   .0215041   .0257249     0.84   0.403    -.0289158     .071924
         L2. |    .016146   .0179948     0.90   0.370    -.0191232    .0514153
         L1. |  -.0202538   .0100913    -2.01   0.045    -.0400324   -.0004751
         F1. |     .03281   .0091484     3.59   0.000     .0148795    .0507406
         F2. |   .0484625   .0127464     3.80   0.000     .0234801     .073445
         F3. |   .0585947    .016608     3.53   0.000     .0260436    .0911459
-------------+----------------------------------------------------------------
manager_1997 |
after_export |
         L5. |  -.1136076   .0315438    -3.60   0.000    -.1754323   -.0517828
         L4. |  -.0555838   .0262284    -2.12   0.034    -.1069906   -.0041769
         L3. |  -.0383059   .0197763    -1.94   0.053    -.0770667    .0004549
         L2. |  -.0329116   .0144063    -2.28   0.022    -.0611474   -.0046757
         L1. |  -.0327735   .0095052    -3.45   0.001    -.0514033   -.0141437
         F1. |   .0569091   .0084183     6.76   0.000     .0404095    .0734086
         F2. |   .0569673   .0119599     4.76   0.000     .0335264    .0804083
-------------+----------------------------------------------------------------
manager_1998 |
after_export |
         L6. |   .0752338    .035233     2.14   0.033     .0061784    .1442892
         L5. |   .0353123   .0278864     1.27   0.205    -.0193441    .0899687
         L4. |  -.0323526   .0215226    -1.50   0.133    -.0745361    .0098309
         L3. |   -.069244   .0163607    -4.23   0.000    -.1013104   -.0371777
         L2. |   -.051374   .0125782    -4.08   0.000    -.0760268   -.0267213
         L1. |  -.0452034   .0087488    -5.17   0.000    -.0623507   -.0280562
         F1. |   .0284864   .0079169     3.60   0.000     .0129695    .0440033
-------------+----------------------------------------------------------------
manager_1999 |
after_export |
         L7. |  -.1500836   .0398826    -3.76   0.000     -.228252   -.0719151
         L6. |  -.0772577   .0312668    -2.47   0.013    -.1385394   -.0159759
         L5. |  -.0360463    .025005    -1.44   0.149    -.0850552    .0129626
         L4. |    .011625   .0203209     0.57   0.567    -.0282032    .0514532
         L3. |  -.0271381   .0167294    -1.62   0.105    -.0599272     .005651
         L2. |  -.0479374   .0129913    -3.69   0.000    -.0733998    -.022475
         L1. |  -.0295148   .0087772    -3.36   0.001    -.0467179   -.0123117
------------------------------------------------------------------------------
```

## Test if csadid works as expected
```
. use testdata

. csadid y, treatment(treatment)
       panel variable:  i (strongly balanced)
        time variable:  t, 1 to 10
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
treatment_2  |
           y |
         L1. |          0  (omitted)
         F1. |          1          .        .       .            .           .
         F2. |          2          .        .       .            .           .
         F3. |          3          .        .       .            .           .
         F4. |          4          .        .       .            .           .
         F5. |          5          .        .       .            .           .
         F6. |          6          .        .       .            .           .
         F7. |          7          .        .       .            .           .
         F8. |          8          .        .       .            .           .
-------------+----------------------------------------------------------------
treatment_5  |
           y |
         L4. |          0  (omitted)
         L3. |          0  (omitted)
         L2. |          0  (omitted)
         L1. |          0  (omitted)
         F1. |         .5          .        .       .            .           .
         F2. |          1          .        .       .            .           .
         F3. |        1.5          .        .       .            .           .
         F4. |          2          .        .       .            .           .
         F5. |        2.5          .        .       .            .           .
------------------------------------------------------------------------------
```
What if we lag treatment by one year?

## Exclude firm-year FE

Estimates are more stable, but clear pre-trends.

```
. csadid after_export if year <= 1999, treatment(manager) absorb(cc) notyet
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
manager_1992 |
after_export |
         F1. |   .0471862    .016717     2.82   0.005     .0144214     .079951
         F2. |   .1023705   .0233411     4.39   0.000     .0566227    .1481183
         F3. |   .1493617     .02927     5.10   0.000     .0919936    .2067298
         F4. |   .2260227    .032192     7.02   0.000     .1629275     .289118
         F5. |   .3025076   .0346451     8.73   0.000     .2346044    .3704108
         F6. |   .2942579   .0364735     8.07   0.000     .2227711    .3657446
         F7. |   .2881089   .0397005     7.26   0.000     .2102974    .3659205
-------------+----------------------------------------------------------------
manager_1993 |
after_export |
         L1. |  -.0940354   .0171956    -5.47   0.000    -.1277381   -.0603327
         F1. |   .0816814   .0138413     5.90   0.000      .054553    .1088098
         F2. |   .1123561   .0192786     5.83   0.000     .0745707    .1501415
         F3. |   .1108398   .0220138     5.04   0.000     .0676936    .1539861
         F4. |   .1033936   .0238883     4.33   0.000     .0565734    .1502138
         F5. |   .1197993   .0262046     4.57   0.000     .0684392    .1711594
         F6. |   .1223215   .0284228     4.30   0.000     .0666139    .1780291
-------------+----------------------------------------------------------------
```

When only looking at German managers / exporters, there is no robust correlation. We don't believe this.
```
. csadid export if year <= 1999 & country =="DE", treatment(manager)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
manager_1992 |
      export |
         F1. |   .0050341   .0742991     0.07   0.946    -.1405895    .1506577
         F2. |   -.074056   .0864934    -0.86   0.392    -.2435799    .0954679
         F3. |   .0085699   .1019184     0.08   0.933    -.1911865    .2083263
         F4. |   .0357761   .1068507     0.33   0.738    -.1736474    .2451996
         F5. |  -.0650565   .1075936    -0.60   0.545     -.275936     .145823
         F6. |   .0325901   .1081261     0.30   0.763    -.1793331    .2445132
         F7. |   .0287721   .1109737     0.26   0.795    -.1887325    .2462766
-------------+----------------------------------------------------------------
manager_1993 |
      export |
         L1. |  -.0764626   .0745073    -1.03   0.305    -.2224943     .069569
         F1. |  -.0502433   .0562954    -0.89   0.372    -.1605803    .0600938
         F2. |   .1548223   .0662154     2.34   0.019     .0250426    .2846021
         F3. |  -.0895596   .0745457    -1.20   0.230    -.2356665    .0565472
         F4. |  -.1515711   .0773499    -1.96   0.050    -.3031742     .000032
         F5. |   -.046196   .0836739    -0.55   0.581    -.2101938    .1178018
         F6. |  -.1817125   .0857714    -2.12   0.034    -.3498213   -.0136037
-------------+----------------------------------------------------------------
manager_1994 |
      export |
         L2. |  -.1831904   .0627235    -2.92   0.003    -.3061263   -.0602545
         L1. |  -.1108678   .0483451    -2.29   0.022    -.2056225   -.0161132
         F1. |  -.0718647   .0465649    -1.54   0.123    -.1631303    .0194009
         F2. |  -.1937966   .0562071    -3.45   0.001    -.3039605   -.0836327
         F3. |   -.226382   .0608314    -3.72   0.000    -.3456095   -.1071546
         F4. |  -.1888686   .0624901    -3.02   0.003    -.3113469   -.0663903
         F5. |  -.2087887   .0670702    -3.11   0.002    -.3402438   -.0773336
-------------+----------------------------------------------------------------
```

# 2021-05-21
## Mata implementation
Mata implementation gives "the same" results
```
. attgt export if year <= 1999 & country =="DE", treatment(manager)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
manager_1993 |
      export |
         L1. |  -.0764456          .        .       .            .           .
         F1. |       -.05          .        .       .            .           .
         F2. |   .1547049          .        .       .            .           .
         F3. |  -.0892814          .        .       .            .           .
         F4. |  -.1510938          .        .       .            .           .
         F5. |  -.0456731          .        .       .            .           .
         F6. |  -.1814815          .        .       .            .           .
-------------+----------------------------------------------------------------
manager_1994 |
      export |
         L2. |  -.1833164          .        .       .            .           .
         L1. |  -.1111111          .        .       .            .           .
         F1. |  -.0722944          .        .       .            .           .
         F2. |  -.1939477          .        .       .            .           .
         F3. |  -.2265101          .        .       .            .           .
         F4. |  -.1889785          .        .       .            .           .
         F5. |  -.2090391          .        .       .            .           .
-------------+----------------------------------------------------------------
```

Construct weights in advance. There is, however, something wrong with the the control group, as the weights are not symmetric.
```
1

   __00000P |      Freq.     Percent        Cum.
------------+-----------------------------------
       -.05 |         20        0.00        0.00
  -.0344828 |         29        0.00        0.00
          0 |  3,309,802      100.00      100.00
   .0344828 |         29        0.00      100.00
        .05 |         20        0.00      100.00
------------+-----------------------------------
      Total |  3,309,900      100.00

   __00000Q |      Freq.     Percent        Cum.
------------+-----------------------------------
  -.0001204 |      8,309        0.25        0.25
  -.0001101 |      1,619        0.05        0.30
          0 |  3,282,584       99.17       99.47
   .0000102 |      7,460        0.23       99.70
   .0001101 |      9,079        0.27       99.97
   .0001204 |        849        0.03      100.00
------------+-----------------------------------
      Total |  3,309,900      100.00
```
First mata estimates with bootstrapped s.e.
```
. attgt export if year <= 1999 & country =="DE", treatment(manager) aggregate(gt)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
-----------------------------------------------------------------------------------
                  |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
treated_1993_1992 |  -.0592065   .1866457    -0.32   0.751    -.4250254    .3066123
treated_1993_1994 |  -.0265734   .1752429    -0.15   0.879    -.3700433    .3168964
treated_1993_1995 |   .1800711   .1724157     1.04   0.296    -.1578576    .5179997
treated_1993_1996 |  -.0976027   .1941147    -0.50   0.615    -.4780605    .2828551
treated_1993_1997 |  -.1045276   .1781576    -0.59   0.557    -.4537101     .244655
treated_1993_1998 |  -.0506153   .1885256    -0.27   0.788    -.4201187    .3188881
treated_1993_1999 |  -.1915825   .1800001    -1.06   0.287    -.5443763    .1612113
treated_1994_1992 |  -.1401829   .1780629    -0.79   0.431    -.4891798     .208814
treated_1994_1993 |  -.0845377   .1807465    -0.47   0.640    -.4387942    .2697188
treated_1994_1995 |  -.0863871   .1492202    -0.58   0.563    -.3788534    .2060791
treated_1994_1996 |  -.1791188   .1640818    -1.09   0.275    -.5007132    .1424756
treated_1994_1997 |  -.2156489   .1803357    -1.20   0.232    -.5691003    .1378026
treated_1994_1998 |  -.1774055   .1754218    -1.01   0.312    -.5212259    .1664149
treated_1994_1999 |  -.1999876   .2102592    -0.95   0.342     -.612088    .2121128
treated_1995_1992 |  -.3160751   .2388313    -1.32   0.186    -.7841759    .1520257
treated_1995_1993 |  -.0828488    .205394    -0.40   0.687    -.4854137     .319716
treated_1995_1994 |  -.1643966   .1857817    -0.88   0.376     -.528522    .1997288
treated_1995_1996 |   .0536481    .169875     0.32   0.752    -.2793008    .3865969
treated_1995_1997 |  -.0024649   .1856499    -0.01   0.989    -.3663319    .3614022
treated_1995_1998 |   .0427928   .1626074     0.26   0.792    -.2759118    .3614974
treated_1995_1999 |  -.0131772   .1694166    -0.08   0.938    -.3452277    .3188732
treated_1996_1992 |   .2514531   .2128081     1.18   0.237    -.1656432    .6685493
treated_1996_1993 |   .3059361   .1764318     1.73   0.083     -.039864    .6517361
treated_1996_1994 |   .1443966   .1551361     0.93   0.352    -.1596646    .4484577
treated_1996_1995 |   .1130186   .1403595     0.81   0.421    -.1620809    .3881181
treated_1996_1997 |    .076937   .1290997     0.60   0.551    -.1760937    .3299678
treated_1996_1998 |  -.0163432   .1374815    -0.12   0.905     -.285802    .2531156
treated_1996_1999 |  -.0216216   .1484376    -0.15   0.884     -.312554    .2693108
treated_1997_1992 |  -.1175824   .1940119    -0.61   0.544    -.4978388     .262674
treated_1997_1993 |  -.0204724   .1883993    -0.11   0.913    -.3897282    .3487833
treated_1997_1994 |   .1656489   .1702168     0.97   0.330    -.1679699    .4992676
treated_1997_1995 |  -.0451542   .1699192    -0.27   0.790    -.3781897    .2878813
treated_1997_1996 |   .0139721   .1335958     0.10   0.917    -.2478708    .2758149
treated_1997_1998 |   .0354463    .114105     0.31   0.756    -.1881954    .2590879
treated_1997_1999 |  -.0146341   .1145113    -0.13   0.898    -.2390722    .2098039
treated_1998_1992 |    .059867   .2473444     0.24   0.809    -.4249191     .544653
treated_1998_1993 |  -.0160514   .2037537    -0.08   0.937    -.4154012    .3832985
treated_1998_1994 |  -.0309278   .1738579    -0.18   0.859    -.3716831    .3098274
treated_1998_1995 |   .0048263   .1608503     0.03   0.976    -.3104346    .3200871
treated_1998_1996 |   .0580099   .1388521     0.42   0.676    -.2141352     .330155
treated_1998_1997 |  -.0354463   .1529757    -0.23   0.817    -.3352731    .2643806
treated_1998_1999 |   .0282728   .1340105     0.21   0.833     -.234383    .2909286
-----------------------------------------------------------------------------------
```

# 2021-05-23
Test clustering. Firm vs firm-country clusters dont seem to matter much.
```

. attgt export if year<=1995, treatment(manager) reps(99)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit
Callaway Sant'Anna (2021)
-----------------------------------------------------------------------------------
                  |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
treated_1993_1992 |  -.0590969   .0525704    -1.12   0.261     -.162133    .0439393
treated_1993_1994 |   .0109231   .0535004     0.20   0.838    -.0939358     .115782
treated_1993_1995 |     .08376   .0551321     1.52   0.129    -.0242969    .1918169
treated_1994_1992 |  -.1338758    .056385    -2.37   0.018    -.2443883   -.0233633
treated_1994_1993 |  -.0666398    .035124    -1.90   0.058    -.1354816    .0022021
treated_1994_1995 |  -.0033484   .0373056    -0.09   0.928     -.076466    .0697692
-----------------------------------------------------------------------------------

. attgt export if year<=1995, treatment(manager) reps(99) cluster(frame_id_numeric)
       panel variable:  i (unbalanced)
        time variable:  year, 1992 to 2003, but with gaps
                delta:  1 unit

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    __000001 |  3,309,900    229155.4    139114.4          1     504575

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    __000002 |  3,309,900    229155.4    139114.4          1     504575
Callaway Sant'Anna (2021)
-----------------------------------------------------------------------------------
                  |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
treated_1993_1992 |  -.0590969   .0586134    -1.01   0.313    -.1739771    .0557834
treated_1993_1994 |   .0109231    .053693     0.20   0.839    -.0943133    .1161595
treated_1993_1995 |     .08376   .0533542     1.57   0.116    -.0208122    .1883322
treated_1994_1992 |  -.1338758   .0525491    -2.55   0.011    -.2368701   -.0308815
treated_1994_1993 |  -.0666398    .030906    -2.16   0.031    -.1272143   -.0060652
treated_1994_1995 |  -.0033484   .0400586    -0.08   0.933    -.0818618    .0751651
-----------------------------------------------------------------------------------
```

# 2021-06-01
## Implement event study
```
. attgt lnQ if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(3) post(5) re
> ps(20)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating event_m3
Estimating event_m2
Estimating event_m1
Estimating event_1
Estimating event_2
Estimating event_3
Estimating event_4
Estimating event_5
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    event_m3 |   .1034773   .0682791     1.52   0.130    -.0303472    .2373017
    event_m2 |   .0116384   .0515863     0.23   0.822    -.0894689    .1127457
    event_m1 |  -.0166506    .030912    -0.54   0.590    -.0772369    .0439357
     event_1 |    .213958   .0519147     4.12   0.000      .112207     .315709
     event_2 |   .3780437   .0649388     5.82   0.000      .250766    .5053214
     event_3 |   .4667226   .0694317     6.72   0.000     .3306389    .6028063
     event_4 |   .4957758   .0637879     7.77   0.000     .3707538    .6207977
     event_5 |   .6623637    .085337     7.76   0.000     .4951063    .8296212
------------------------------------------------------------------------------

. attgt exporter if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(3) post(
> 5) reps(20)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating event_m3
Estimating event_m2
Estimating event_m1
Estimating event_1
Estimating event_2
Estimating event_3
Estimating event_4
Estimating event_5
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    event_m3 |    .020763   .0392726     0.53   0.597    -.0562099    .0977359
    event_m2 |  -.0140938   .0325203    -0.43   0.665    -.0778323    .0496448
    event_m1 |  -.0322272    .018028    -1.79   0.074    -.0675615    .0031071
     event_1 |   .0405351   .0205509     1.97   0.049      .000256    .0808142
     event_2 |   .0739714   .0277126     2.67   0.008     .0196558     .128287
     event_3 |   .0738011   .0308385     2.39   0.017     .0133588    .1342434
     event_4 |   .0339298   .0382931     0.89   0.376    -.0411232    .1089828
     event_5 |   .0302095    .033302     0.91   0.364    -.0350611    .0954802
------------------------------------------------------------------------------
```

# 2021-06-04
## Implement att
```
. attgt lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(att)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating att
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
lnQL         |
         att |   .2270268    .047694     4.76   0.000     .1335483    .3205053
------------------------------------------------------------------------------

. attgt lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(foreign ) aggregate(att) reps(50)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating att
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
lnQL         |
         att |   .1448863   .0242845     5.97   0.000     .0972896     .192483
------------------------------------------------------------------------------

. attgt lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(foreign_hire ) aggregate(att) reps(50)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating att
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
lnQL         |
         att |   .1574648   .0354046     4.45   0.000     .0880732    .2268565
------------------------------------------------------------------------------

. attgt lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(3) post(6) r
> eps(50)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating event_m3
Estimating event_m2
Estimating event_m1
Estimating event_1
Estimating event_2
Estimating event_3
Estimating event_4
Estimating event_5
Estimating event_6
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
lnQL         |
    event_m3 |   .0439256   .0559961     0.78   0.433    -.0658248     .153676
    event_m2 |   .0567715    .039594     1.43   0.152    -.0208313    .1343743
    event_m1 |  -.0016242   .0269028    -0.06   0.952    -.0543528    .0511043
     event_1 |   .1157186     .04367     2.65   0.008     .0301269    .2013103
     event_2 |   .2348289   .0583469     4.02   0.000      .120471    .3491868
     event_3 |    .291681   .0688352     4.24   0.000     .1567664    .4265956
     event_4 |   .3455067   .0735155     4.70   0.000      .201419    .4895943
     event_5 |   .4164837   .0911845     4.57   0.000     .2377653     .595202
     event_6 |   .4113804   .1114671     3.69   0.000     .1929089    .6298518
------------------------------------------------------------------------------

```

## Test loop over several variables
Gives the same result with one variable
```
. attgt lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(2) post(3) r
> eps(20)
       panel variable:  frame_id_numeric (unbalanced)
        time variable:  year, 1988 to 2018, but with gaps
                delta:  1 unit
Generating weights...
Estimating event_m2
Estimating event_m1
Estimating event_1
Estimating event_2
Estimating event_3
Callaway Sant'Anna (2021)
------------------------------------------------------------------------------
             |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
lnQL         |
    event_m2 |   .0567715   .0431826     1.31   0.189    -.0278649    .1414079
    event_m1 |  -.0016242    .024751    -0.07   0.948    -.0501352    .0468868
     event_1 |   .1157186    .036145     3.20   0.001     .0448756    .1865616
     event_2 |   .2348289   .0513223     4.58   0.000     .1342391    .3354188
     event_3 |    .291681   .0735978     3.96   0.000      .147432      .43593
------------------------------------------------------------------------------
```
