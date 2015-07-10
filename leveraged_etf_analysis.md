# Long-Term Leveraged ETF Performance
[patrick charles](http://www.pchuck.org)  

# Long-Term Leveraged ETF Performance
## An Analysis of Theoretical Simulated vs Actual Performance
- Author: [patrick charles](http://www.pchuck.org)
- Date: 2015-07-09


## Summary

The long-term performance of leveraged ETFs is analyzed. Leveraged ETF performance is compared to simulated ideal leverage and underlying non-leveraged indexes, and a number of characterizations are drawn from the analysis.

Some unexpected results, both in short and long-term performance, are presented. And, an [ETF Leverage Simulator](https://pchuck.shinyapps.io/etf-leverage-simulator) was developed to interactively demonstrate different leverage factors, expense ratios, and their effects on performance.


## Background

[Leveraged ETFs](http://www.investopedia.com/terms/l/leveraged-etf.asp)
are exchanged traded funds that use derivatives
and debt to magnify the returns of an underlying index. Such funds
apply a leverage multiplier (typical 2x or 3x) to amplify an index's
actual returns on a daily basis.

Because of the compounding effects of magnified daily returns and
price decay due to volatility, leveraged ETF issuers do not
recommend[^1] holding such funds for long periods.

Much has also been written about the dangers and folly of holding
leveraged ETFs for periods longer than a day[^2].


## Analysis

All analysis below is performed in R, and the code to transform and
manipulate the data is shown for reproducibility.





---

## DJI Index

Several leveraged ETFs offer the ability to magnify the daily performance
of the [Dow Jones Industrial Average](http://finance.yahoo.com/q?s=%5EDJI).
Here's a look at historical performance, since 2006-06-21,
the date that leveraged ETF's tracking the index were first introduced.


```r
  base.symbol <- "^DJI"
  startDate <- "2006-06-21"
  endDate <- Sys.Date()
  source <- "yahoo"

  ## load the dji index historical data (+1x, actuals)
  xts.base <- loadSeries(base.symbol, source, startDate, endDate)  

  ggplot(xts.base, aes(x=index(xts.base), y=DJI.Close)) + geom_line() +
          xlab("Date") + ylab("Price") + ggtitle("DJI Closing Price")
```

![](leveraged_etf_analysis_files/figure-html/dji-1.png) 

## DJI Index vs. ProShares Leveraged Dow ETFs

On 2006.06.21, [ProShares](http://www.proshares.com/) introduced leveraged ETF's to amplify the daily performance of the DJI Index by -1x ([DOG](http://www.proshares.com/funds/dog.html)), -2x ([DXD](http://www.proshares.com/funds/dxd.html)) and +2x ([DDM](http://www.proshares.com/funds/ddm.html)). On 2010.02.11, ProShares introduced DJI-based ETFs with -3x ([UDOW](http://www.proshares.com/funds/udow.html)) and +3x ([SDOW](http://www.proshares.com/funds/sdow.html)) leverage.

### Performance

The performance of the ETFs, since their inception, relative the underlying
index, can be visualized using ggplot.

In addition, using simulation, we can see how perfectly efficient leverage
would have performed over the same period.


```r
  type <- "Close" # use closing prices, to mirror the actual ETF daily target
  base.name <- "DJI" 

  ## load the etf's and run comparable simulations
  n1x <- loadAndSim(xts.base, source, "DOG", type, "n1x", -1.0)
  p2x <- loadAndSim(xts.base, source, "DDM", type, "p2x", 2.0)
  n2x <- loadAndSim(xts.base, source, "DXD", type, "n2x", -2.0)
  p3x <- loadAndSim(xts.base, source, "UDOW", type, "p3x", 3.0)
  n3x <- loadAndSim(xts.base, source, "SDOW", type, "n3x", -3.0)

  ## merge all the series into a single xts
  xts.merged <- merge(xts.base,
                      p2x$etf, p2x$sim,
                      p3x$etf, p3x$sim,
                      n1x$etf, n1x$sim,
                      n2x$etf, n2x$sim,
                      n3x$etf, n3x$sim) 
                    
  ## plot the results
  xtsMultiPlot(xts.merged, base.name, colors.pair, 
               "Leveraged ETF Performance: Actual and Simulated")
```

![](leveraged_etf_analysis_files/figure-html/dji_sim-1.png) 

To simulate efficient leverage, the daily returns of base index are calculated,
multiplied by a leverage factor, and compounded daily.

The leveraged ETFs use complex financial instruments to achieve the same principle but differ from the ideal or 'perfect' simulated leverage due to a variety of factors which include:

* Management Fees (typically ~1%)
* Tracking Error (deviations from the target daily return factor)

These small differences, compounded over time, lead to divergent results
seen in the plot.


### Observations: (DJI) 2x Leveraged ETF Relative Performance

Notice that the leveraged ETFs tend to outperform simulated ideal leverage
in periods of mostly steady increase or decrease.

![](leveraged_etf_analysis_files/figure-html/ddm_vs_dji_plot-1.png) 

Let's look more closely at the differences in returns between the
2x leveraged ETF and the underlying index over longer periods, where
the compounding effects cause divergences in performance between the ETF,
simulated ETF and underlying index.

#### Annual Return Comparison

```r
  return.mon.col.idx <- grep("Return.Monthly", names(p2x.merged))
  tc <- table.CalendarReturns(p2x.merged[,return.mon.col.idx])[, -(1:12)]
  tc$DDM_v_DJI <- round(tc$DDM.Return.Monthly / tc$DJI.Return.Monthly, digits=2)
  tc$DDM_v_SIM <- round(tc$DDM.Return.Monthly / tc$p2x.sim.Return.Monthly, digits=2)
  kable(tc)
```

        DJI.Return.Monthly   DDM.Return.Monthly   p2x.sim.Return.Monthly   DDM_v_DJI   DDM_v_SIM
-----  -------------------  -------------------  -----------------------  ----------  ----------
2006                  13.6                 26.8                     26.0        1.97        1.03
2007                   6.4                  8.6                     10.9        1.34        0.79
2008                 -33.8                -61.8                    -62.1        1.83        1.00
2009                  18.8                 39.7                     33.2        2.11        1.20
2010                  11.0                 25.4                     20.1        2.31        1.26
2011                   5.5                 10.4                      6.5        1.89        1.60
2012                   7.3                 17.7                     13.5        2.42        1.31
2013                  26.5                 64.7                     58.4        2.44        1.11
2014                   7.5                 18.0                     14.2        2.40        1.27
2015                  -1.7                 -2.4                     -4.2        1.41        0.57

Leveraged ETF prospectuses[^1] warn that performance for any period
longer than a day, returns can diverge significantly from the target
leverage multiplier. Nonetheless, on an annual basis,
DDM averaged **2.012x**!

Note, though, that this is due to coincidence more than design, particularly
the existence of a bull market over the same period.

Within that period, there was very significant variation in the returns
from year to year.. Compared to the DJI, DDM had best and worst year
multiples of
**2.44x** and **1.34x**, respectively.

#### Total Annualized Returns


```r
  return.col.index <- grep("Return$", names(p2x.merged))
  returns.annual <- Return.annualized(p2x.merged[,return.col.index])

  dji.return.annual <- returns.annual[1]
  ddm.return.annual <- returns.annual[2]
  p2x.return.annual <- returns.annual[3]

  kable(round(returns.annual * 100, digits=2))
```

                     DJI.Return   DDM.Return   p2x.sim.Return
------------------  -----------  -----------  ---------------
Annualized Return          5.31         9.48             6.77

On a yearly basis, at least since its inception, DDM has nearly doubled
**(by 1.78x)**
the annual return of the underlying DJI index 
**(5.31%)** and
has outperformed the 2x simulated ETF
**(by 1.4x)**.

#### Performance Comparison
![](leveraged_etf_analysis_files/figure-html/dji_2x_perf-1.png) 

The DDM ETF appears to have done better than the simulated ETF
in terms of risk. While the drawdown chart highlights the significant
potential downsides leveraged ETFs in general, it also shows less total
downside exposure in DDM than the simulated 2x ETF.

#### Performance Statistics Comparison

```r
  kable(table.Stats(p2x.merged[,return.col.index]))
```

                   DJI.Return   DDM.Return   p2x.sim.Return
----------------  -----------  -----------  ---------------
Observations        2277.0000    2277.0000        2277.0000
NAs                    0.0000       0.0000           0.0000
Minimum               -0.0787      -0.1597          -0.1575
Quartile 1            -0.0043      -0.0084          -0.0085
Median                 0.0006       0.0014           0.0011
Arithmetic Mean        0.0003       0.0006           0.0006
Geometric Mean         0.0002       0.0004           0.0003
Quartile 3             0.0055       0.0110           0.0110
Maximum                0.1108       0.2259           0.2216
SE Mean                0.0003       0.0005           0.0005
LCL Mean (0.95)       -0.0002      -0.0003          -0.0004
UCL Mean (0.95)        0.0008       0.0016           0.0016
Variance               0.0002       0.0006           0.0006
Stdev                  0.0123       0.0237           0.0245
Skewness               0.1487       0.0213           0.1487
Kurtosis              10.9049       9.9589          10.9049

#### Trailing 36-Month Returns

```r
  p2x.box <- chart.Boxplot(p2x.merged[,return.mon.col.idx], colorset=colors.pair)
```

![](leveraged_etf_analysis_files/figure-html/dji_2x_rdist-1.png) 

The DDM and simulated monthly return boxplot reiterates the slightly
better average performance of DDM vs. simulated ideal leverage. It shows
a similar range of returns for DDM and the simulation. Also note the
large range of return distributions and the very wide confidence interval
compared to the base index. Again, these indicate the potential risks of
holding leveraged ETF for longer intervals (in this case, monthly return
intervals).


#### Probability Density (Monthly Returns)

Finally, lets look at the probability density function for the distribution
of monthly returns for the underlying index vs. leveraged ETF and simulation.


```r
  ## convert to dataframe 
  df.merged <- as.data.frame(p2x.merged)
  ## create separate data column
  df.merged$Date <- as.Date(rownames(df.merged))
  ## melt by date
  df.melted <- melt(df.merged, id.vars=c("Date"))
  ## decompose all columns containing monthly returns into rows
  df.filtered <- df.melted[grep("Return.Monthly", df.melted$variable), ]
  ## eliminate dji by only selecting ETF and simulated leverage
  ggplot(df.filtered, aes(x=value*100, fill=variable)) +
    geom_density(alpha=0.3, position="identity") + 
    xlab("% Return") + ylab("Probability") + ggtitle("Probability Density - DJI v. DDM v. 2x Simulation") +
    scale_fill_manual("", values=colors.pair)
```

![](leveraged_etf_analysis_files/figure-html/dji_2x_histograms-1.png) 

This curve represents the likelihood of various levels of monthly returns
for DDM compared to the DJI and simulated ETF, based on all daily
returns since the inception of DDM. As expected, the functions are 'wider'
and 'shorter' (because of the application of leverage to magnify returns)
than the index and have more skew (because
of the compounding effects of leverage).

Notice the very subtle difference between the shape of the DDM and
simulated leverage curves. Again, very small differences in the periodic
returns compound into signficant differences over longer periods.

#### Relative Risk vs. Return (Trailing 36-Month Returns)

The relative risk and return for the DJI, 2x ETF (DDD) and simulated 2x ETF
are shown. The risk/reward for a risk-free rate of return (~3%) is superimposed
over the plot.


```r
chart.RiskReturnScatter(p2x.merged[,return.mon.col.idx], Rf=0.03/12, add.boxplots=TRUE, colorset=colors.pair, xlim=c(0.0, 2.0), "Trailing 36-Month Performance")
```

![](leveraged_etf_analysis_files/figure-html/dji_2x_rrr-1.png) 

### Tracking Error

While leveraged ETFs are very good at magnifying the daily returns
of an underlying index, they aren't perfect.

Tracking errors are the differences between the actual and expected
daily returns. Note that this is synonymous here with the
difference between the actual and simulated leveraged daily returns.

Tracking error can be visualized using a scatter plot of
daily returns of the index vs. ETF. The slope of this relationship
should equal the leverage factor.


```r
  ddm <- ggplot(xts.merged, aes(x=DDM.Return, y=DJI.Return)) +
    geom_point(alpha=0.9, color=colors.pair[2]) +
    geom_smooth(method=lm, color="white", alpha=0.2) +
    ggtitle("Daily Index Return vs. 2x ETF (DDM) Return") +
    xlab("DDM Daily Return") + ylab("DJI Daily Return")

  p2x.sim <- ggplot(xts.merged, aes(x=p2x.sim.Return, y=DJI.Return)) +
    geom_point(alpha=0.9, color=colors.pair[3]) +
    geom_smooth(method=lm, color="white", alpha=0.2) +
    ggtitle("Daily Index Return vs. 2x Simulated Return") +
    xlab("2x Simulated Daily Return") + ylab("DJI Daily Return")

  grid.arrange(p2x.sim, ddm, ncol=2)
```

![](leveraged_etf_analysis_files/figure-html/scatter_dji_vs_etf-1.png) 

#### Linear Model

Linear models can be constructed from the actual daily returns of the ETFs
versus the corresponding underlying index.


```r
  ddm.fit <- lm(data=xts.merged, DDM.Return ~ DJI.Return)
  ddm.fit
```

```
## 
## Call:
## lm(formula = DDM.Return ~ DJI.Return, data = xts.merged)
## 
## Coefficients:
## (Intercept)   DJI.Return  
##   0.0001052    1.9078655
```
The slope of the DDM model is **1.91**,
indicating that the 2x ETF appears to be targeting/maintaining a
slightly lower than advertised level of leverage.


#### Residuals

Residuals (the difference between the expected and actual value)
of the daily returns can be visualized to determine if there is a
discernable pattern in the tracking error of the ETFs.


```r
  ddm.resid <- resid(ddm.fit)

  ddm <- ggplot(xts.merged, aes(x=DDM.Return, y=ddm.resid)) + 
    geom_point(alpha=0.9, color=colors.pair[2]) +
    geom_smooth(method=lm) + 
    ggtitle("Residuals: DDM vs. DJI") +
    xlab("DDM Daily Return") +
    ylab("Variation from Expected")

#  grid.arrange(gdxx, ddm, ncol=2)
```

#### Diagnostics

A set of diagnostics plots is used to identify outliers in the residuals
vs. fitted values.


```r
  autoplot(ddm.fit, data=as.data.frame(xts.merged),
    colour=colors.pair[2], smooth.colour='gray', label.size=3)
```

![](leveraged_etf_analysis_files/figure-html/dji_diagnostic-1.png) 

Notice the serial nature of the tracking error. The very largest
tracking errors happened on subsequent trading days.. 2008.09.29-30,
2008.10.10-11.

---

## GDM Index

Let's look now at an index that hasn't seen the same virtually monotonic
increases in value during the recent bull run in the equity markets.

Several leveraged ETFs track the
[AMEX Gold Mining Index (GDM)](http://finance.yahoo.com/q?s=%5EGDM)
which has seen significant volatility during 2014 and 2015. Here's a look
at performance since the inception of corresponding leveraged
ETFs on 2015-02-13.


```r
  base.symbol <- "GDM"
  startDate <- "2015-02-13"
  endDate <- Sys.Date()
  source <- "yahoo"

  ## load the gdm index historical data (+1x, actuals) 
  xts.base <- loadSeries(base.symbol, source, startDate, endDate)
  
  ggplot(xts.base, aes(x=index(xts.base), y=GDM.Close)) + geom_line() +
          xlab("Date") + ylab("Price") + ggtitle("GDM Closing Price")
```

![](leveraged_etf_analysis_files/figure-html/gdm-1.png) 

## GDM Index vs. ProShares Leveraged ETFs

On 2015.02.13, ProShares introduced leveraged ETFs to amplify
the daily performance of the GDM Index by +2x ([GDXX](http://www.proshares.com/funds/gdxx.html)) and -2x ([GDXS](http://www.proshares.com/funds/gdxs.html)).

### Performance

The performance of the ETFs, since their inception, relative the underlying
index, can be visualized using ggplot.

In addition, using simulation, we can see how perfectly efficient leverage
would have performed over the same period.


```r
  type <- "Close" # use closing prices, to mirror the actual ETF daily target
  base.name <- "GDM" 

  ## load the etf's and run comparable sims
  p2x <- loadAndSim(xts.base, source, "GDXX", type, "p2x", 2.0)
  n2x <- loadAndSim(xts.base, source, "GDXS", type, "n2x", -2.0)

  ## merge all the series into a single xts
  xts.merged <- merge(xts.base,
                      p2x$etf, p2x$sim,
                      n2x$etf, n2x$sim) 
                    
  ## plot the results 
  xtsMultiPlot(xts.merged, base.name, colors.pair, 
               "Leveraged ETF Performance: Actual and Simulated")
```

![](leveraged_etf_analysis_files/figure-html/gdm_sim-1.png) 

### Observations: (GDM) -2x Leveraged ETF Relative Performance

Let's look more closely at the differences in yearly returns between the
-2x leveraged ETF and the underlying index. Here, the -2x leveraged fund is
chosen because the GDM index lost ground over the observation period.

![](leveraged_etf_analysis_files/figure-html/gdxs_vs_gdm_plot-1.png) 

Notice that in this case, where there has been volatility in the underlying
index, simulated leverage outperformed the leveraged ETF.

Again, let's look more closely at differences in returns between the -2x
leveraged ETF and the underlying index over longer periods, where the
compounding effects cause divergences in performance between the ETF,
simulated ETF and underlying index.

#### Annual Return Comparison

```r
  return.mon.col.idx <- grep("Return.Monthly", names(n2x.merged))
  tc <- table.CalendarReturns(n2x.merged[,return.mon.col.idx])[, -(1:12)]
  tc$GDXS_v_GDM <- round(tc$GDXS.Return.Monthly / tc$GDM.Return.Monthly, digits=2)
  tc$GDXS_v_SIM <- round(tc$GDXS.Return.Monthly / tc$n2x.sim.Return.Monthly, digits=2)
  kable(tc)
```

        GDM.Return.Monthly   GDXS.Return.Monthly   n2x.sim.Return.Monthly   GDXS_v_GDM   GDXS_v_SIM
-----  -------------------  --------------------  -----------------------  -----------  -----------
2015                 -20.4                  40.9                     44.4           -2         0.92

On an annual basis, GDXS averaged **-2x** the return
of the base index.

At the same time, GDXS underperformed ideal simulated leverage,
with a return that was was **0.92x** that of ideal.



#### Performance Comparison
![](leveraged_etf_analysis_files/figure-html/gdm_2x_perf-1.png) 

The GDXS ETF underperformed and was more risky than the ideal -2x simulated
ETF. This is evident in the drawdown chart which shows consistently larger
potential losses for the ETF vs. simulated returns.

#### Performance Statistics Comparison

```r
  kable(table.Stats(n2x.merged[,return.col.index]))
```

                   GDM.Return   GDXS.Return   n2x.sim.Return
----------------  -----------  ------------  ---------------
Observations         100.0000      100.0000         100.0000
NAs                    0.0000        0.0000           0.0000
Minimum               -0.0671       -0.1060          -0.0905
Quartile 1            -0.0126       -0.0182          -0.0159
Median                -0.0010        0.0056           0.0019
Arithmetic Mean       -0.0021        0.0042           0.0042
Geometric Mean        -0.0023        0.0034           0.0036
Quartile 3             0.0079        0.0271           0.0252
Maximum                0.0452        0.1432           0.1341
SE Mean                0.0018        0.0040           0.0036
LCL Mean (0.95)       -0.0057       -0.0038          -0.0030
UCL Mean (0.95)        0.0015        0.0123           0.0114
Variance               0.0003        0.0016           0.0013
Stdev                  0.0181        0.0404           0.0362
Skewness              -0.1507        0.0517           0.1507
Kurtosis               1.1748        0.9785           1.1748

#### Trailing 36-Month Returns

```r
  n2x.box <- chart.Boxplot(n2x.merged[,return.mon.col.idx], colorset=colors.pair[c(1, 4:5)])
```

![](leveraged_etf_analysis_files/figure-html/gdm_2x_rdist-1.png) 
The simulated ETF shows a wider range of monthly with a higher
average result than the GDXS ETF.

#### Probability Density (Monthly Returns)

Finally, lets look at the probability density function for the distribution
of monthly returns for the underlying index vs. leveraged ETF and simulation.


```r
  ## convert to dataframe 
  df.merged <- as.data.frame(n2x.merged)
  ## create separate data column
  df.merged$Date <- as.Date(rownames(df.merged))
  ## melt by date
  df.melted <- melt(df.merged, id.vars=c("Date"))
  ## decompose all columns containing daily returns into rows
  df.filtered <- df.melted[grep("Return$", df.melted$variable), ]
  ## eliminate gdm by only selecting ETF and simulated leverage
  ggplot(df.filtered, aes(x=value*100, fill=variable)) +
    geom_density(alpha=0.3, position="identity") + 
    xlab("% Return") + ylab("Probability") + ggtitle("Probability Density - GDM vs. GDXS vs -2x Simulation") +
    scale_fill_manual("", values=colors.pair[c(1, 4:5)])
```

![](leveraged_etf_analysis_files/figure-html/gdm_2x_histograms-1.png) 

#### Relative Risk vs. Return (Trailing 36-Month Returns)

The relative risk and return for the GDM, 2x ETF (DDD) and simulated 2x ETF
are shown. The risk/reward for a risk-free rate of return (~3%) is superimposed
over the plot.


```r
chart.RiskReturnScatter(n2x.merged[,return.col.index], Rf=0.03/12, add.boxplots=TRUE, colorset=colors.pair[c(1, 4:5)], xlim=c(0.0, 2.0), "Trailing 36-Month Performance")
```

![](leveraged_etf_analysis_files/figure-html/gdm_2x_rrr-1.png) 


### Tracking Error

Again, while leveraged ETFs are very good at magnifying the daily returns
of an underlying index, they aren't perfect.

Tracking errors are the differences between the actual and expected
daily returns. Note that this is synonymous here with the
difference between the actual and simulated leveraged daily returns.

Tracking error can be visualized using a scatter plot of
daily returns of the index vs. ETF. The slope of this relationship
should equal the leverage factor.


```r
  gdxs <- ggplot(xts.merged, aes(x=GDXS.Return, y=GDM.Return)) +
    geom_point(alpha=0.9, color=colors.pair[4]) +
    geom_smooth(method=lm, color="white", alpha=0.2) +
    ggtitle("Daily Index Return vs. -2x ETF (GDXS) Return") +
    xlab("GDXS Daily Return") + ylab("GDM Daily Return")

  n2x.sim <- ggplot(xts.merged, aes(x=n2x.sim.Return, y=GDM.Return)) +
    geom_point(alpha=0.9, color=colors.pair[5]) +
    geom_smooth(method=lm, color="white", alpha=0.2) +
    ggtitle("Daily Index Return vs. -2x Simulated Return") +
    xlab("-2x Simulated Daily Return") + ylab("GDM Daily Return")

  grid.arrange(n2x.sim, gdxs, ncol=2)
```

![](leveraged_etf_analysis_files/figure-html/scatter_gdm_vs_etf-1.png) 

#### Linear Model

Linear models can be constructed from the actual daily returns of the ETFs
versus the corresponding underlying index.


```r
  gdxs.fit <- lm(data=xts.merged, GDXS.Return ~ GDM.Return)
  gdxs.fit
```

```
## 
## Call:
## lm(formula = GDXS.Return ~ GDM.Return, data = xts.merged)
## 
## Coefficients:
## (Intercept)   GDM.Return  
##  -0.0003739   -2.1787756
```
The slope of the GDXS model is **-2.18**,
indicating that the -2x ETF appears to be targeting/maintaining a
slightly higher than advertised level of leverage.

#### Residuals

Residuals (the difference between the expected and actual value)
of the daily returns can be visualized to determine if there is a
discernable pattern in the tracking error of the ETFs.


```r
  gdxs.resid <- resid(gdxs.fit)

  gdxs <- ggplot(xts.merged, aes(x=GDXS.Return, y=gdxs.resid)) + 
    geom_point(alpha=0.9, color=colors.pair[4]) +
    geom_smooth(method=lm) + 
    ggtitle("Residuals: GDXS vs. GDM") +
    xlab("GDXS Daily Return") +
    ylab("Variation from Expected")

#  grid.arrange(gdxx, gdxs, ncol=2)
```

#### Diagnostics

A set of diagnostics plots is used to identify outliers in the residuals
vs. fitted values.


```r
  autoplot(gdxs.fit, data=as.data.frame(xts.merged),
    colour=colors.pair[4], smooth.colour='gray', label.size=3)
```

![](leveraged_etf_analysis_files/figure-html/gdm_diagnostic-1.png) 

While there don't appear to be any discernable patterns
in the residuals, scale-location trends or points exerting impactful
leverage, several dates appear to be associated with the largest
tracking errors.

* 2015-03-11 GDM: 13.56-14.58  7.52%    vs.  1.60% expected  (vol 11594)
* 2015-03-10 GDM: 14.22-13.56 -4.64%    vs.  0.00% expected  (vol  6301)
* 2015-02-20 GDM: 19.37-18.66 -3.67%    vs. -5.96% expected  (vol  6901)
* 2015-02-17 GDM: 20.56-19.00 -7.58%    vs. -5.98% expected  (vol  1000)

Again though, notice the serial nature of the tracking error,
as was also the case with the DJI leveraged ETFs.
The very largest tracking errors happened on subsequent trading days.


---

## Conclusions

### Short-term Performance

The short-term characteristics of leveraged ETFs are well understood
and documented in fund prospectuses. But do they track daily returns
as closely as portrayed?

* Over daily periods, leveraged ETFs achieve returns that are statistically different than the advertised target leverage multipliers.
  * Based on the linear models above, the +2x leveraged ETF DDM consistently achieves daily leverage of **1.9x** while the -2x leveraged ETF GDXS appears to target daily leverage of **-2.2x**.
* Significant tracking errors can occur, and they tend to be serially clustered.

### Long-term Performance 

Long-term performance of leveraged ETFs is not as well understood due to the impacts compounded leverage and volatility in differerent market scenarios. 

The visualizations presented illustrate the long-term impact of different levels of leverage and the relative performance of an underlying index compared to the family of leveraged ETFs derived from the index. The drawdown charts highlight potential long-term loss exposures at varying levels of leverage.

* Over longer periods, leveraged ETFs can consistently achieve returns that are better than underlying indexes, despite warnings from issuers and financial market pundits against long-term holdings.
  * The DDM leveraged ETF has existed for over nine years. Over this period
(which includes both the secular bull market starting in 2009 and the financial crisis of 2008 that preceded it), DDM has nearly doubled **(by 1.78x)** the annual return of the underlying DJI index **(5.31%)**

* Over periods of mostly monotonic returns in the underlying index, leveraged ETFs can significantly outperform the simulated/ideal ETF returns.
  * Since its inception, the DDM leveraged ETFs annualized return **(9.48%)** outperformed the simulated 2x ETF return **(by 1.4x)**.

### Risk vs. Return

More important than raw returns, is relative risk. In the ETFs analyzed, this metric varies.

* In the case of DDM, the return/risk ratio is superior to the risk-free rate of return, the underlying index and simulated leverage.
* In the case of GDXS, the return/risk ratio lags slightly behind the simulated leverage.


## Further Work

* The Q-Q diagnostic plot indicates that the daily returns of the leveraged ETFs are not statistically normal. The curves exhibit 'heavy tails'. A T-distribution might be more representative and more work could be done to characterize and understand the distribution of leveraged daily returns.

* The diagnostic leverage plots identified a number of points/dates where the leveraged ETFs deviated from their target leverage multiplier. A time-serial relationship is noted, and more work could be done to identify the market factors that cause such outlying variances and to quantify the impact on long-term returns.

* The tracking error plots and linear models also identify consistent variances from advertised leverage factors. While the variance is statistically significant, the cause is not known (e.g. whether the increased/decreased leverage is intentional or due to inaccuracies in the financial methods or instruments used to attain leverage.)

* The performance statistics comparison charts highlight some
interesting statistical differences between the leveraged and simulated
leveraged ETFs which could be elaborated on and explored further.


---

### Notes

[^1]: [ProShares Leveraged ETF Prospectuses](http://www.proshares.com/resources/prospectus_reports.html)

[^2]: Articles negative on long-term leveraged ETF investment
  * [Leveraged 3X ETFs Are Much More Dangerous Than You May Think!](http://www.ino.com/blog/2014/12/leveraged-3x-etfs-are-much-more-dangerous-than-you-may-think/#.VZ615RNVhBc)
  * [7 Risks of Trading Leveraged ETFs and How to Avoid Them](http://etfdb.com/leveraged-etfs/7-mistakes-to-avoid-when-trading-leveraged-etfs/)
  * [What's the Problem with Leveraged ETFs?](http://www.wealthdaily.com/articles/whats-the-problem-with-leveraged-etfs/5186)
  * [Warning: Leveraged and Inverse ETFs Kill Portfolios](http://news.morningstar.com/articlenet/article.aspx?id=271892)
  * [The Perils of the ProShares UltraShorts](http://www.thestreet.com/story/10457663/1/the-perils-of-the-proshares-ultrashorts.html)
  * [Why Short Sector ETFs Aren't So Smart](http://www.thestreet.com/story/10454678/1/why-short-sector-etfs-arent-so-smart.html)
  * [The Case Against Leveraged ETFs](http://seekingalpha.com/article/35789-the-case-against-leveraged-etfs)
  * [The Dangers Of Leveraged ETFs](http://seekingalpha.com/article/309261-the-dangers-of-leveraged-etfs)

