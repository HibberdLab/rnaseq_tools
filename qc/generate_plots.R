# plot the data produce by summarise_fastqc.rb

# libraries
library(ggplot2)
library(grid)
library(plyr)

# load data
data = read.csv('aggregated_fastq.csv', as.is=T, header=T)

# set colours for species
cols <- c(Fp = "#558ED5", Fr = "#558ED5", Ft = "#339933")

# functions
## Summarizes data.
## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else length(x)
  }
  
  # This is does the summary; it's not easy to understand...
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun= function(xx, col, na.rm) {
                   c( N    = length2(xx[,col], na.rm=na.rm),
                      mean = mean   (xx[,col], na.rm=na.rm),
                      sd   = sd     (xx[,col], na.rm=na.rm)
                   )
                 },
                 measurevar,
                 na.rm
  )
  
  # Rename the "mean" column    
  datac <- rename(datac, c("mean"=measurevar))
  
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  names(datac)[4] <-  'value'
  return(datac)
}

pretty_plot <- function(df, y, ylab) {
  ggplot(df, 
         aes_string(x="sp", y=y, group="smpl", fill="sp")) + 
    geom_bar(position="dodge", stat="identity", colour='black') +
    scale_fill_manual(values = cols) +
    geom_errorbar(aes_string(ymin=as.formula(paste(y, '-se', sep='')), 
                             ymax=as.formula(paste(y, '+se', sep=''))), 
                  colour="black", width=.1) +
    ylab(ylab) +
    theme_bw()
}

# plots
totd <- summarySE(data, measurevar="total_seqs", groupvars=c("sp","smpl"))
totd$panel <- "no. read pairs"
gcd <- summarySE(data, measurevar="gc_percent", groupvars=c("sp","smpl"))
gcd$panel <- "GC%"
meand <- summarySE(data, measurevar="mean_qual", groupvars=c("sp","smpl"))
meand$panel <- "mean quality"
data$b13 <- data$n_seqs_b13 / data$total_seqs
b13d <- summarySE(data, measurevar="b13", groupvars=c("sp","smpl"))
b13d$panel <- "prop. q =< 13"
propnd <- summarySE(data, measurevar="prop_ns", groupvars=c("sp","smpl"))
propnd$panel <- "mean % N"

d <- rbind(totd, gcd)
d <- rbind(d, meand)
d <- rbind(d, b13d)
d <- rbind(d, propnd)

p <- ggplot(data=d, mapping = aes(x = sp, y = value, fill=sp, group=smpl)) +
  facet_grid(panel~., scale="free") +
  layer(data=totd, geom=c("bar"), stat="identity", position="dodge", colour="black") +
  layer(data=gcd, geom=c("bar"), stat="identity", position="dodge", colour="black") +
  layer(data=meand, geom=c("bar"), stat="identity", position="dodge", colour="black") +
  layer(data=b13d, geom=c("bar"), stat="identity", position="dodge", colour="black") +
  layer(data=propnd, geom=c("bar"), stat="identity", position="dodge", colour="black") +
  geom_errorbar(aes(ymin=value-se, ymax=value+se), 
                colour="black", width=.1, position=position_dodge(.9)) +
  scale_fill_manual(values = cols) +
  ylab('') +
  xlab('Species')
p