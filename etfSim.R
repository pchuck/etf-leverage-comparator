## ETF simulation/plotting functions
##

## load security data into an xts object using quantmod.
## fetches dividend/split adjusted data, if available.
## adds daily and monthly returns columns.
##
## returns the xts object
##
loadSeries <- function(sym, data.source, startDate, endDate) {
    xts.ohlc <- getSymbols(Symbols=sym, src=data.source,
                           from=startDate, to=endDate, auto.assign=F, adjust=T)
    sym.clean <- gsub("\\^", "", sym) # remove index prefix characters from sym
    xts.r <- merge(dailyReturn(xts.ohlc), monthlyReturn(xts.ohlc))
    colnames(xts.r) <- c(paste(sym.clean, ".", "Return", sep=""), 
                         paste(sym.clean, ".", "Return.Monthly", sep=""))
    merge(xts.ohlc, xts.r)
}

## given a quantmod/xts object, rename selected columns and
## optionally scale the prices based on a reference value.
##
##   xts.prices: an xts object containing quantmod data loaded via getSymbols()
##   sym: the symbol for the target security/etf
##   annotation: annotation for the target column
##   refValue: a reference starting value used to re-scale the target column
##   target: a string contained in the target column
##
## returns an xts object containing the modified price data
##
##  e.g. cleanSeries(xts.prices, "DOG.Close", "n1x.DOG.Close", 10000.0)
##
cleanSeries <- function(xts.prices, sym.old, sym.new, refValue) {
    names(xts.prices) <- sub(paste("^", sym.old, sep=""),
                             paste(sym.new), 
                             names(xts.prices))

    if(!is.na(refValue)) {
        index <- grep(sym.new, names(xts.prices))
        target.series <- xts.prices[1, index]

        factor <- refValue / target.series
        xts.prices[, index] <- xts.prices[, index] * rep(factor)
    }
    xts.prices
}

## given an initial value and vector of incremental return deltas, 
## calculate a vector of compounded balances based on incremental
## return deltas. if multiplier is provided, each incremental return delta is
## magnified by its value.
##
##   initial: initial starting balance
##   deltas: vector of price deltas
##   multiplier: factor for magnifying price deltas (optional, default: 1.0)
##   expense: factor for decreasing daily balances (optional, default: 0.0)
##
## returns a vector of balances based on application of the compounded returns.
##
##    e.g. compoundBalances(100, c(0.1, -0.05, 0.1, multiplier=1.0))
##         [1] 100.00 110.00 104.50 114.95
##
compoundBalances <- function(initial, deltas, multiplier=1.0, expense=0.0) {
#    compounded <- c(initial)
#
#    ## calculate daily leveraged returns
#    for(i in 2:(length(deltas) + 1)) {
#        previous <- compounded[i - 1]
#        compounded[i] <- 
#            previous + previous * deltas[i - 1] * multiplier -
#                previous * expense
#    }
#    compounded

    cumprod(1 + (deltas * multiplier - expense)) * initial
}

## simulate a set of leveraged daily balances into a new xts object
## assumes OHLCR data (particularly, the existence of Close and Return cols)
##
##   xts.ohlcr - xts object (ohlc+r) containing close and return data
##   base.cname - name of the column containing price data 
##   multiplier - the leverage multiplier to apply to the price deltas
##   sim.col.name - the name of the column to contain the simulated balances
##
## returns a new xts object containing the simulated leveraged balances
##
##   e.g. simLeverage(xts.ohlcr, 2.0, "p2x.sim.Close")
##
simLeverage <- function(xts.ohlcr, multiplier, prefix, start.date) {
    xts.sub <- xts.ohlcr[index(xts.ohlcr) >= start.date, ]
    close.col.index <- grep("Close", names(xts.sub))
    return.col.index <- grep("Return$", names(xts.sub))
    date.row.index <- which(index(xts.sub) >= start.date)
    
    # start with the initial balance..
    initial <- as.vector(xts.sub[, close.col.index])[1]
    ## create a new, unitialized, xts from date index
    xts.sim <- xts(order.by=index(xts.sub))
    ## simulate the compound balances from initial using the deltas
    v.base <- as.vector(xts.sub[, return.col.index])
    v.leveraged <- compoundBalances(initial, v.base, multiplier=multiplier)
    ## merge the returns and compound balances into the new xts timeseries
    xts.sim <- merge(xts.sim, sim.col.name.close=v.leveraged)
    xts.sim <- merge(xts.sim, sim.col.name.return=(v.base * multiplier))
    xts.sim <- merge(xts.sim, sim.col.name.rmonthly=monthlyReturn(xts.sim))
    ## rename the simulated data columns to something more meaningful
    colnames(xts.sim) <- c(paste(prefix, ".sim.Close", sep=""),
                           paste(prefix, ".sim.Return", sep=""),
                           paste(prefix, ".sim.Return.Monthly", sep=""))
    xts.sim
}

## from an xts obj, fetch the price from the named column at the specified date
priceAtDate <- function(xts.prices, col.name, date) {
    col.index <- grep(col.name, names(xts.prices))
    as.vector(xts.prices[index(xts.prices) == date, col.index])[1]
}

## load a leveraged ETF and run a corresponding sim on the base index
##
##   xts.base: an xts object containing prices for the base index
##   symbol.base: the symbol for the base index, e.g. "DJI"
##   source: market source from which to load data, e.g. "yahoo"
##   symbol.etf: the symbol for the leveraged etf, e.g. "^DOG"
##   type: the type of prices to use, e.g. "Close"
##   prefix: symbolic prefix for columns, e.g. "n1x"
##   leverage: the leverage multiplier to apply in simulation, e.g. -1.0
##
## returns a list containing the etf and simulated price data in xts objects
##
loadAndSim <-function(xts.base, source, symbol.etf, type, prefix, leverage) {
    ## load the ETF and transform the data
    xts.etf <- loadSeries(symbol.etf, source, startDate, endDate)
    start.date <- index(xts.etf)[1]
    start.val <- priceAtDate(xts.base, type, start.date)
    row.name <- paste(symbol.etf, ".", type, sep="")
    row.name.new <- paste(prefix, ".", row.name, sep="")
    xts.etf <- cleanSeries(xts.etf, row.name, row.name.new, start.val)
    
    ## run a simulation using the same leverage factor
    xts.sim <- simLeverage(xts.base, leverage, prefix, start.date)

    ## return both the etf and simulated xts objects
    list("etf"=xts.etf, "sim"=xts.sim)
}

## convert xts to dataframe and plot date vs. value lines for matching types
##
##   xts.merged: xts object containing quantmod prices for multiple securities
##   type: string identifying columns containing price data, e.g. 'Close'
##   title: plot title text
##
## returns the ggplot object
##
xtsMultiPlot <- function(xts.merged, symbol.base, colors, title) {
    ## convert to dataframe 
    df.merged <- as.data.frame(xts.merged)
    ## create separate data column
    df.merged$Date <- as.Date(rownames(df.merged))
    ## melt by date
    df.melted <- melt(df.merged, id.vars=c("Date"))
    colnames(df.melted) <- c("Date", "Price", "Value")
    ## decompose all columns containing closing prices into rows
    df.filtered <- df.melted[grep("Close", df.melted$Price), ]
    ## render the plot of prices vs. date for each variable series
    ggplot(df.filtered, aes(x=Date, y=Value, color=Price)) + geom_line() +
        scale_color_manual(values=colors) + 
        ylab("Price") + ggtitle(paste(symbol.base, "vs.", title))
}

## convert numerics to percentages
percent <- function(x, digits = 2, format = "f", ...) {
    paste0(formatC(100 * x, format = format, digits = digits, ...), "%")
}
