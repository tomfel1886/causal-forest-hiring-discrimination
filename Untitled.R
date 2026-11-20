# Machine Learning 
# Causal forest analysis
# Thomas Felder (21-103-098)

## Loading the packages
library(grf)

# I use a couple of packages which are not covered in the lecture.
library(haven) #I use this to load the dataset.
library(lmtest) #This contains coeftest() for clustering the standard errors.
library(sandwich) #I use this to construct a clustered variance-covariance matrix. It provides vcovCL()
library(stargazer) #I use this to make the output table look much nicer.

set.seed(1234)

######### Loading data

data <- read_dta("lakisha_aer.dta")

# Variables are sometimes coded with characters. I need to reconstruct them to create dummies.

# Treatment variable if application has African-American sounding Name.
data$AAName <- as.numeric(data$race == "b")

# Gender and Place dummy.
data$female  <- as.numeric(data$sex == "f")
data$chicago <- as.numeric(data$city == "c")

Y <- as.numeric(data$call)
treatment <- data$AAName

nrow(data)          
mean(treatment)             

######### Linear probability model

# This are the Callback rates to compare against the original paper.
tapply(data$call, data$race, mean)

#Linear probability model
lpm <- lm(call ~ AAName, data = data)

summary(lpm)

# Clustered standard errors at advertisement level.
coeftest(lpm, vcov = vcovCL(lpm, cluster = data$adid))

######### Covariates

# These are the Variables which are excluded from the causal forest.
drop <- c("id", "ad", "adid", "firstname", "kind", "expminreq", "schoolreq", "ownership",
          "call", "race", "AAName", "l", "boston", "sex", "city", "occupspecific", "occupbroad",
          "fed", "parent_sales", "parent_emp", "branch_sales", "branch_emp", "fracblack_empzip",
          "fracwhite_empzip", "lmedhhinc_empzip", "fracdropout_empzip", "fraccolp_empzip", "linc_empzip")

Covariates <- data[,!(names(data) %in% drop)]
Covariates <- as.data.frame(Covariates)

ncol(Covariates)      
dim(Covariates)      

colSums(is.na(Covariates))

######### Causal Forest Estimation

# I define the Advertisement identifier for the forest clustering 
ads <- as.integer(factor(data$adid))

c.forest <- causal_forest(Covariates, Y, treatment, W.hat = 0.5, clusters = ads, sample.fraction = 0.5, 
                           num.trees = 10000, honesty = TRUE, ci.group.size = 10)

summary(c.forest)

######### Average Treatment Effect 

ATE <- average_treatment_effect(c.forest, target.sample ="all")

ATE

######### Table 1

lpm.estimate <- coef(lpm)["AAName"]

lpm.se <- sqrt(diag(vcovCL(lpm, cluster = data$adid)))["AAName"]

forest.estimate <- ATE[1]

forest.se <- ATE[2]

Table1 <- data.frame(Method = c("Linear probability model","Causal forest"),
  ATE = c(lpm.estimate,forest.estimate), SE = c(lpm.se,forest.se))

Table1$ATE <- round(Table1$ATE,4)

Table1$SE  <- round(Table1$SE,4)

Table1

stargazer(Table1,type = "html",summary = FALSE,rownames = FALSE,digits = 4,
  title = "",notes = "Note: Standard errors clustered at the advertisement level. Estimated on all 4,870 applications.",
  notes.align = "l",out = "Table1.html")

######### Figure 1

# Prediction from forest for every application for the plot
Pred <- predict(c.forest)$predictions

summary(Pred)

hist(Pred, breaks = 50, col = "grey80", border = "white", main = "", xlab = "Predicted treatment effect")

# Overall ATE

abline(v = ATE[1], col = "red", lwd = 2)

legend("topright", legend = "ATE", col = "red", lwd = 2, bty = "n")


# Min./Max. of the observations

min(Pred)
max(Pred)

######### Calibration test

test_calibration(c.forest)

######### variable importance

importance <- variable_importance(c.forest)

importance <- data.frame(variable = colnames(Covariates), importance = importance)

# sorting from most to least important

importance <- importance[order(importance$importance, decreasing = TRUE), ]

# Ten most important characteristics

importance10 <- importance[1:10, ]

importance10

# I reverse the order so the most important appears at the top

importance10 <- importance10[10:1, ]

importance10$label <- c("Honors mentioned on resume","Special skills mentioned on resume",
  "Number of jobs listed on resume","Share Black in neighbourhood",
  "Share White in neighbourhood","College educated in neighbourhood",
  "Log per capita income in neighbourhood","Log median household income in neighbourhood",
  "Years of experience","High school dropouts in neighbourhood")

# All values
importance10[,c("label","importance")]

par(mar = c(5, 20, 2, 2))

barplot(importance10$importance, names.arg = importance10$label, horiz = TRUE,
        las = 1, col = "grey70", border = NA, xlim = c(0,0.14), xlab = "Variable importance", 
        main = "")

par(mar = c(5, 4, 4, 2))

######### Figure 3
# Resume quality
lowquality <- average_treatment_effect( c.forest, subset = data$h == 0)

highquality <- average_treatment_effect(c.forest, subset = data$h == 1)

lowquality
highquality

quality <- data.frame( group = c("Low quality", "High quality"),
  estimate = c(lowquality[1], highquality[1]),se = c(lowquality[2], highquality[2]))

quality

# Resume quality variables
quality[,c("group", "estimate")]

# Difference between high quality and low quality
quality$estimate[2]-quality$estimate[1]

# Resume characteristics

volunteer <- average_treatment_effect(c.forest,subset = data$volunteer == 1)
email <- average_treatment_effect(c.forest,subset = data$email == 1)
empholes <- average_treatment_effect(c.forest,subset = data$empholes == 1)
workschool <- average_treatment_effect(c.forest,subset = data$workinschool == 1)
computer <- average_treatment_effect(c.forest,subset = data$computerskills == 1)
special <- average_treatment_effect(c.forest,subset = data$specialskills == 1)

resume <- data.frame(group = c("Volunteering", "E-mail","Employment holes",
            "Work in school","Computer skills","Special skills"),
            estimate = c(volunteer[1],email[1],empholes[1],workschool[1],computer[1],special[1]),
            se = c(volunteer[2],email[2],empholes[2],workschool[2],computer[2],special[2]))
resume
# Resume characteristics variables
# Same y-axis for both panels

lower <- min(c( quality$estimate - 1.96*quality$se, resume$estimate - 1.96*resume$se))
upper <- max(c(quality$estimate + 1.96*quality$se,resume$estimate + 1.96*resume$se,0))

par(mfrow = c(2, 2))

# Panel A: resume quality
barA <- barplot(quality$estimate,names.arg = quality$group, ylim = c(lower, upper),col = "steelblue",
  border = NA,ylab = "Estimated treatment effect",main = "Resume quality")

arrows(barA,quality$estimate - 1.96*quality$se, barA,quality$estimate + 1.96*quality$se,angle =90,code = 3,length = 0.05)

abline(h = 0)

abline(h = ATE[1],col = "red" ,lty = 2)

legend("bottomleft",legend = "Overall ATE",col ="red",lty = 2,bty = "n")

# Panel B: resume characteristics
barB <- barplot(resume$estimate,names.arg = resume$group,ylim = c(lower, upper),col = "steelblue",
  border = NA,ylab = "Estimated treatment effect",main = "Resume characteristics",las = 2,cex.names = 0.8)

arrows(barB,resume$estimate - 1.96*resume$se,barB,resume$estimate + 1.96*resume$se,angle = 90,code = 3,length = 0.05)
abline(h = 0)
abline(h = ATE[1],col ="red",lty = 2)
par(mfrow = c(1, 1))

######### Robustness
# Check 1 with 4'784 Observations

complete <- complete.cases(Covariates)

sum(complete)     

c.forest.complete <- causal_forest(Covariates[complete, ],Y[complete],treatment[complete],
  W.hat = 0.5,clusters = ads[complete],sample.fraction = 0.5,num.trees = 10000,honesty = TRUE,
  ci.group.size = 10)

average_treatment_effect(c.forest.complete,target.sample = "all")

test_calibration(c.forest.complete)

# Check 2 with add excluded employer variables

# Here only identifiers, text variables, treatment, outcome, and redundant variables are removed for covariate matrix.

X_all <- data[, !(names(data) %in% c("id", "ad", "adid", "firstname", "kind", "expminreq", "schoolreq", "ownership",
                      "call", "race", "AAName", "l", "boston", "sex", "city", "occupspecific", "occupbroad"))]

# I only want the numeric variables

Covariates_all <- X_all[, sapply(X_all, is.numeric)]

ncol(Covariates_all)

c.forest.all <- causal_forest(Covariates_all, Y,treatment, W.hat = 0.5, clusters = ads,
  sample.fraction = 0.5,num.trees = 10000,honesty = TRUE,ci.group.size = 10)

average_treatment_effect(c.forest.all,target.sample = "all")

test_calibration(c.forest.all)
# Check 3: Number of trees

# 500 Trees
c.forest.500 <- causal_forest( Covariates, Y,treatment,W.hat = 0.5,clusters = ads,
  sample.fraction = 0.5,num.trees = 500,honesty = TRUE,ci.group.size = 10)

average_treatment_effect(c.forest.500,target.sample = "all")

test_calibration(c.forest.500)

# 2'000 trees
c.forest.2000 <- causal_forest(Covariates,Y,treatment,W.hat = 0.5,clusters = ads,
  sample.fraction = 0.5,num.trees = 2000,honesty = TRUE,ci.group.size = 10)

average_treatment_effect(c.forest.2000,target.sample = "all")

test_calibration(c.forest.2000)

# 10'000 trees
average_treatment_effect(c.forest,target.sample = "all")

test_calibration(c.forest)

