## diurnal changes
##' 
##'
##' This function calculates the diurnal profile of a pollutant with
##' the effect of meteorology removed. Its primary use is to compare
##' two periods to determine whether there has been a shift in diurnal
##' profile e.g. due to some intervention.
##' @title Plot diurnal changes, removing the effect of meteorology
##' @param dat A data frame to analyse.
##' @param vars The explanatory variables used in the model.
##' @param pollutant Name of the pollutant to apply meteorological
##'     normalisation to.
##' @param date A vector of dates, length three. These dates are used
##'     to parition the data into two categories (before/after). The
##'     date format is UK e.g. \code{date = c("19/2/2005",
##'     "19/2/2007", "19/2/2010")}.
##' @param single Not used.
##' @import reshape2
##' @export
##' @return Some data
##' @author David Carslaw
diurnalGbm <- function(dat, vars = c("ws", "wd", "hour", "weekday"),  pollutant = "nox", 
                       date = c("01/01/2012", "31/12/2012",
                                "31/12/2013"), single = FALSE){


    ## format dates
    date <- as.POSIXct(strptime(date, format = "%d/%m/%Y", "GMT"), "GMT")

    ## silence R check
    Hour = Weekday = value = variable = difference = NULL


    mod1 <- buildMod(selectByDate(dat, start = date[1], end = date[2]),
                     vars = vars, pollutant = pollutant, B = 1)
    
    res1 <- plot2Way(mod1, variable = c("weekday", "hour"))
    
    name1 <- paste(format(date[1], "%d %b %Y"), "to", format(date[2], "%d %b %Y"))
    names(res1)[which(names(res1) == "y")] <- name1
    
    results <- res1

    if (!single) {

        if (length(date) == 4) {
            start1 <- date[3]
            end1 <- date[4]
        } else {
            start1 <- date[2] + 24 * 3600 ## start of next day
            end1 <- date[3]
        }
        
        mod2 <- buildMod(selectByDate(dat, start = start1, end = end1), vars = vars,
                         pollutant = pollutant, B = 1)

        res2 <- plot2Way(mod2, variable = c("weekday", "hour"))

        name2 <- paste(format(start1, "%d %b %Y"), "to", format(end1, "%d %b %Y"))
        names(res2)[which(names(res2) == "y")] <- name2
        
        results <- merge(res1, res2, by = c("Hour", "Weekday"))
        results <- arrange(results, Hour) ## order Hours/weekdays
        
        ## only need weekday/sat/sun
        ids <- which(results$Weekday %in% c("Sat", "Sun"))
        results$Weekday <- as.character(results$Weekday)
        results$Weekday[-ids] <- "Weekday"
        
        results <- plyr::ddply(results,
                               plyr::.(Weekday = Weekday, Hour = Hour),
                               plyr::numcolwise(mean))
        
        results$Weekday <- ordered(results$Weekday, levels = c("Weekday", "Sat", "Sun"),
                                   labels = c("Weekday", "Saturday", "Sunday"))

        ## difference
        results$difference <- results[, 4] - results[, 3]

        results <- melt(results, id.var = c("Weekday", "Hour", "difference"))
        ylim <- range(c(results$difference, results$value)) * 1.03
        
        
        plt <- ggplot(results, aes(x = Hour, y = value, colour = variable)) +
            geom_line(size = 1) +
            facet_grid(~ Weekday) +
            theme(legend.position = "top") +
            geom_ribbon(aes(ymin = 0, ymax = difference),
                            fill = "tomato", colour = "tomato") +
            scale_colour_brewer(palette = "Set1", name = "period") +
            scale_x_continuous(breaks = c(0, 6, 12, 18))
        
        print(plt)
        
        
    } else {


        results <- arrange(results, Hour) ## order Hours/Weekdays
        
        ## only need Weekday/sat/sun
        ids <- which(results$Weekday %in% c("Sat", "Sun"))
        results$Weekday <- as.character(results$Weekday)
        results$Weekday[-ids] <- "Weekday"
        results <- plyr::ddply(results, plyr::.(Weekday = Weekday, Hour = Hour),
                               plyr::numcolwise(mean))
        results$Weekday <- ordered(results$Weekday, levels =c("Weekday", "Sat", "Sun"),
                                   labels = c("Weekday", "Saturday", "Sunday"))

        plt <- ggplot(results, aes(x = Hour, y = value, colour = variable)) +
            geom_line(size = 1) +
            facet_grid(~ Weekday) +
            theme(legend.position = "top") +
            scale_x_continuous(breaks = c(0, 6, 12, 18))

        print(plt)

    }
    print(plt)
    invisible(list(results, plt))

}

