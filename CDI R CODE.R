###CREATING DISTANCE VARIABLE (LIVING W/IN 75TH OR 90TH PERCENTILE)
#install and load packages
library(tidyverse)
install.packages("tidycensus")
library(tidycensus)
install.packages("tigris")
library(tigris)
install.packages("sf")
library(sf)
options(tigris_class ="sf") # set shapefile class to work with sf package
install.packages("ggsn")
library(ggsn) # lets us add a distance scale

### Merge data and geometry ###

# Get geometry
US.tracts <- tracts(state=NULL, county=NULL, cb=T, year=2019)

cdiff <- read.csv("/Users/nicolerafalko/OneDrive - Drexel University/CDI/CDI/cdiff_r3_geocoded.csv") 
cdiff.geo <- cdiff %>% st_as_sf(coords = c("lon", "lat"), agr="constant", crs = 4269)
CDI_retro<- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/Cdiff materials for predictive models/CDI_retro[81].csv") 
# Set points and geometry to same coordinate system
proj <- st_crs(4269)
US.tracts <- US.tracts %>% st_transform(proj)
cdiff.geo <- cdiff.geo %>% st_transform(proj)
# Add geometry data to points
cdiff.geo2 <- st_join(cdiff.geo, US.tracts, join=st_nearest_feature)


###LINKING SDI TO PT BY CENSUS TRACT
sdi <- read.csv("/Users/nicolerafalko/OneDrive - Drexel University/CDI/CDI/rgcsdi-2014-2018-censustract.csv")
#renaming the census tract column to match for merging
sdi$GEOID<-sdi$CENSUSTRACT_FIPS
#merging SDI and geo by CT
library(dplyr)
sdi_geo<-merge(cdiff.geo2,sdi, by='GEOID',all.x=TRUE)

#creating a new dataset with ID, lat and lon of patient home address, lat and lon of HH
locations <- tibble(
  id = cdiff$id,
  homelong = cdiff$lon,
  homelat = cdiff$lat,
  worklong = -75.163243,
  worklat = 39.9569351
)
#creating a distance variable (dist) using lat and lon of HH and home address(in meters)
install.packages("geosphere")
install.packages("tidyverse")
locations <- locations %>%
  mutate(
    dist = geosphere::distHaversine(cbind(homelong, homelat), cbind(worklong, worklat))
  )
#creating quantile variables for 75th and 90th percentiles, 0=no, 1=yes
locations$quantile75 <- ifelse(locations$dist<=quantile(locations$dist, probs=0.75, na.rm=T), 1, 0)
locations$quantile90 <- ifelse(locations$dist<=quantile(locations$dist, probs=0.9, na.rm=T), 1, 0)
#summarizing quantiles
miles.dist<-locations$dist *0.000621371
summary(miles.dist)
#histogram of distances
hist(miles.dist,breaks=600, xlim=c(0,100), main="Distance from HH to Patient Home",xlab="Distance in miles", ylab="Counts")
#boxplot of distances
boxplot(miles.dist,outline=FALSE, main="Distribution of Distance from HH to Patient Home")
#Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#0.0276    1.9965    3.8043   20.6443    8.5456 2371.9988 
#subsetting only 75th percentile
quantile75<-locations %>%
  subset(quantile75==1)
#summary distance for those in 75th percentile(miles)
quantile75$miles.dist<-quantile75$dist *0.000621371
summary(quantile75$miles.dist)
#creating histogram
hist(quantile75$miles.dist,breaks=500, xlim=c(0,20), main="Distance from HH to Patient Home,75th percentile",xlab="Distance in miles", ylab="Counts")
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#0.02763 1.62511 2.61497 3.20903 4.43659 8.44239 
#creating boxplot
boxplot(quantile75$miles.dist,outline=FALSE, main="Distribution of Distance from HH to Patient Home,75th percentile")
#subsetting for those in the 90th percentile
quantile90<-locations %>%
  subset(quantile90==1)
quantile90$miles.dist<-quantile90$dist *0.000621371
#summary distance for those in the 95th percentile(miles)
summary(quantile90$miles.dist)
#creating a histogram
hist(quantile90$miles.dist,breaks=500, xlim=c(0,30), main="Distance from HH to Patient Home,90th percentile",xlab="Distance in miles", ylab="Counts")
#creating a boxplot
boxplot(quantile90$miles.dist,outline=FALSE, main="Distribution of Distance from HH to Patient Home,90th percentile")
#    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#0.02763  1.84702  3.34279  5.37756  6.42402 28.98374 

#renaming ID variable to match the study dataset for merging
colnames(locations)[1]="id"

#merging the datasets
CDI_geo<-full_join(locations,sdi_geo, by='id')
CDI_SDI<-CDI_geo%>%
  select(id,dist,quantile75,quantile90,GEOID,SDI_score,)
colnames(CDI_SDI)[1]="study_redcap_id"
#looking at distribution of SDI_scores in study pop
hist(CDI_SDI$SDI_score,xlab="SDI score",main="Counts of SDI scores of study pop")
summary(CDI_SDI$SDI_score)
boxplot(CDI_SDI$SDI_score,outline=FALSE, main="Distribution of SDI score in study pop")
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#1.00   60.00   87.00   73.82   95.00  100.00       3 

#merging the study set to include SDI score, location data
CDI_retro_final<-full_join(CDI_SDI,CDI_retro, by='study_redcap_id')

# Export the dataset to a CSV file
#write.csv(CDI_retro_final, file = "CDI_retro_final.csv", row.names = FALSE,na="")

###CREATING FOREST PLOTS
#Infection Models
#creating dataframe of unweighted estimates
estimates.inf.un<-data.frame(
  OR=c(0.99, 1.01, 2.30, 3.57, 4.49, 3.47, 3.72, 1.65, 2.59, 5.25, 8.50, 0.51, 1.97, 2.82, 1.53),
  Lower=c(0.98, 1.00, 1.41, 1.70, 2.10, 1.49, 1.85, 0.77, 1.07, 1.97, 3.20, 0.29, 0.98, 1.67, 0.87),
  Upper=c(1.01, 1.02, 3.75, 7.48, 9.60, 8.11, 7.47, 3.53, 6.31, 13.94, 22.62, 0.90, 3.94, 4.77, 2.70)
  
)
rownames(estimates.inf.un) <- c("Age", "Length of stay", "ICU stay, yes", "Current antibiotics, 1", "Current antibiotics, 2", "Current antibiotics, 3", "Current antibiotics, 4",
                                "Prior antibiotics, 1","Prior antibiotics, 2","Prior antibiotics, 3","Prior antibiotics, 4",
                                "Current steroid use, yes","Prior steroid use, yes", "Non-private insurance", "Healthcare referral")
#creating dataframe of estimates-weighted at 75th
estimates.inf.75<-data.frame(
  OR=c(0.99, 1.01, 1.93, 6.01, 7.08, 11.61, 6.90, 1.34, 2.13, 7.38, 9.27, 0.69, 1.68, 2.82, 1.38),
  Lower=c(0.97, 1.00, 1.23, 2.89, 3.34, 5.09, 3.57, 0.71, 0.93, 3.47, 3.69, 0.40, 0.91, 1.71, 0.82),
  Upper=c(1.00, 1.02, 3.02, 12.50, 15.05, 26.51, 13.32, 2.52, 4.87, 15.68, 23.30, 1.19, 3.13, 4.64, 2.31)
)

#creating dataframe of estimates-weighted at 90th
estimates.inf.90<-data.frame(
  OR=c(0.99, 1.01, 1.83, 3.02, 4.46, 10.95, 4.63, 1.87, 1.64, 4.70, 11.98, 0.65, 1.40, 2.30, 1.97),
  Lower=c(0.98, 1.00, 1.16, 1.56, 2.26, 5.09, 2.51, 0.95, 0.77, 2.00, 4.61, 0.39, 0.74, 1.45, 1.17),
  Upper=c(1.00, 1.02, 2.89, 5.83, 8.81, 23.55, 8.52, 3.71, 3.50, 11.03, 31.14, 1.09, 2.65, 3.66, 3.31)
)

#loading forest plot package
install.packages("forestplot")
library(forestplot)

#tailored-unewighted+75th+90th
forestplot(labeltext=rownames(estimates.inf.un), 
           mean=cbind(estimates.inf.un$OR, estimates.inf.75$OR,estimates.inf.90$OR),
           lower=cbind(estimates.inf.un$Lower,estimates.inf.75$Lower,estimates.inf.90$Lower),
           upper=cbind(estimates.inf.un$Upper, estimates.inf.75$Upper,estimates.inf.90$Upper),
           xlab="Odds Ratio, log scale (95% CI)", 
           title="CDI Predictive Models",
           boxsize=0.15,
           fn.ci_norm=c(fpDrawNormalCI,fpDrawCircleCI,fpDrawDiamondCI), 
           legend=c("Unweighted Model", "Weighted at the 75th percentile","Weighted at the 90th percentile"), 
           txt_gp=fpTxtGp(ticks=gpar(cex=0.75),xlab=gpar(cex=1)),
           hrzl_lines=list("2"=gpar(lty=2),"3"=gpar(lty=2),"4"=gpar(lty=2),"8"=gpar(lty=2),"12"=gpar(lty=2),"13"=gpar(lty=2),"14"=gpar(lty=2),"15"=gpar(lty=2)),
           xlog=TRUE)

#Severity Models
#creating dataframe of unweighted estimates
estimates.sev.un<-data.frame(
  OR=c(1.00, 1.00, 1.59, 5.42, 3.08, 2.43, 0.07, 1.68, 1.96, 3.04),
  Lower=c(0.97, 1.00, 0.47, 1.49, 0.84, 0.80, 0.01, 0.86, 0.73, 0.51),
  Upper=c(1.02, 1.01, 5.42, 19.70, 11.24, 7.43, 0.35, 3.30, 5.21, 17.99)
  
)
rownames(estimates.sev.un) <- c("Age", "Length of stay", "Current antibiotics, 1", "Current antibiotics, 2", "Current antibiotics, 3", "Current antibiotics, 4",
                                "Current chemotherapy, yes","Prior PPI use, yes", "Non-private insurance", "Transplant surgery, yes")
#creating dataframe of estimates-weighted at 75th
estimates.sev.75<-data.frame(
  OR=c(1.00, 1.01, 1.43, 5.36, 2.13, 3.53, 0.05, 1.82, 2.41, 8.38),
  Lower=c(0.98, 1.00, 0.39, 1.39, 0.60, 1.13, 0.01, 0.92, 0.95, 1.64),
  Upper=c(1.02, 1.02, 5.25, 20.64, 7.59, 11.03, 0.24, 3.60, 6.11, 42.82)
)

#creating dataframe of estimates-weighted at 90th
estimates.sev.90<-data.frame(
  OR=c(1.00, 1.01, 3.91, 9.68, 9.09, 9.52, 0.06, 0.97, 2.79, 2.92),
  Lower=c(0.98, 1.00, 1.03, 2.51, 2.50, 3.00, 0.01, 0.50, 1.19, 1.01),
  Upper=c(1.02, 1.02, 14.83, 37.37, 33.03, 30.25, 0.27, 1.88, 6.53, 8.45)
)
#tailored-unewighted+75th+90th
forestplot(labeltext=rownames(estimates.sev.un), 
           mean=cbind(estimates.sev.un$OR, estimates.sev.75$OR,estimates.sev.90$OR),
           lower=cbind(estimates.sev.un$Lower,estimates.sev.75$Lower,estimates.sev.90$Lower),
           upper=cbind(estimates.sev.un$Upper, estimates.sev.75$Upper,estimates.sev.90$Upper),
           xlab="Odds Ratio, log scale (95% CI)", 
           title="CDI Severity Predictive Models",
           boxsize=0.15,
           fn.ci_norm=c(fpDrawNormalCI,fpDrawCircleCI,fpDrawDiamondCI), 
           legend=c("Unweighted Model", "Weighted at the 75th percentile","Weighted at the 90th percentile"), 
           txt_gp=fpTxtGp(ticks=gpar(cex=0.75),xlab=gpar(cex=1)),
           hrzl_lines=list("2"=gpar(lty=2),"3"=gpar(lty=2),"7"=gpar(lty=2),"8"=gpar(lty=2),"9"=gpar(lty=2),"10"=gpar(lty=2)),
           xlog=TRUE)

#Recurrence Models
#creating dataframe of unweighted estimates
estimates.rec.un<-data.frame(
  OR=c(0.97, 1.00, 1.04, 1.21, 0.58, 0.64, 0.99, 0.29, 2.14, 3.12, 1.22),
  Lower=c(0.94, 0.99, 0.99, 1.04, 0.11, 0.13, 0.20, 0.06, 0.83, 0.63, 0.43),
  Upper=c(1.01, 1.01, 1.09, 1.42, 3.02, 3.16, 4.92, 1.35, 5.54, 15.39, 3.45)
  
)
rownames(estimates.rec.un) <- c("Age", "Length of stay", "White blood cell count", "Charlson comorbidity score", "Current antibiotics, 1", "Current antibiotics, 2", "Current antibiotics, 3", "Current antibiotics, 4",
                                "Prior PPI use, yes", "Transplant surgery, yes", "GI surgery, yes")
#creating dataframe of estimates-weighted at 75th
estimates.rec.75<-data.frame(
  OR=c(0.98, 0.99, 1.06, 1.22, 0.43, 0.43, 0.51, 0.27, 3.96, 7.87, 1.89),
  Lower=c(0.95, 0.99, 1.00, 1.05, 0.07, 0.07, 0.10, 0.06, 1.36, 2.43, 0.64),
  Upper=c(1.01, 1.00, 1.11, 1.43, 2.67, 2.53, 2.63, 1.22, 11.54, 25.45, 5.57)
)

#creating dataframe of estimates-weighted at 90th
estimates.rec.90<-data.frame(
  OR=c(0.98, 0.99, 1.07, 1.17, 2.97, 2.83, 3.22, 1.85, 4.12, 3.49, 1.63),
  Lower=c(0.95, 0.99, 1.01, 1.00, 0.44, 0.42, 0.53, 0.36, 1.46, 1.20, 0.59),
  Upper=c(1.02, 1.00, 1.12, 1.37, 20.23, 19.00, 19.43, 9.57, 11.64, 10.14, 4.51)
)
#tailored-unewighted+75th+90th
forestplot(labeltext=rownames(estimates.rec.un), 
           mean=cbind(estimates.rec.un$OR, estimates.rec.75$OR,estimates.rec.90$OR),
           lower=cbind(estimates.rec.un$Lower,estimates.rec.75$Lower,estimates.rec.90$Lower),
           upper=cbind(estimates.rec.un$Upper, estimates.rec.75$Upper,estimates.rec.90$Upper),
           xlab="Odds Ratio, log scale (95% CI)", 
           title="CDI Recurrence Predictive Models",
           boxsize=0.15,
           fn.ci_norm=c(fpDrawNormalCI,fpDrawCircleCI,fpDrawDiamondCI), 
           legend=c("Unweighted Model", "Weighted at the 75th percentile","Weighted at the 90th percentile"), 
           txt_gp=fpTxtGp(ticks=gpar(cex=0.75),xlab=gpar(cex=1)),
           hrzl_lines=list("2"=gpar(lty=2),"3"=gpar(lty=2),"4"=gpar(lty=2),"5"=gpar(lty=2),"9"=gpar(lty=2),"10"=gpar(lty=2),"11"=gpar(lty=2)),
           xlog=TRUE)

###BOOTSTRAPPING CI FOR AIC, SENS, SPEC, AUROC

###INFECTION MODEL
#unweighted
infection <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_infection.probs.csv")
inf.model <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
                   priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection, family = binomial)

#obtain AIC
original_aic <- AIC(inf.model)
original_aic
library(boot)

# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
               priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection[indices, ], family = binomial)
  return(AIC(fit))
}

# Perform bootstrap resampling
boot_results <- boot(data = infection, statistic = aic_func, R = 1000)
# calculate CI
set.seed(1234)
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

#### bootstrapping CI for sensitivity
#packages
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Predict probabilities
#F_cdiff=observed
#I_cdiff=predicted
# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = infection, statistic = calc_sensitivity, R = 1000)

# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")

# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = infection, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_spec)

#### bootstrapping CI for AUC
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Predict probabilities
#F_cdiff=observed
#I_cdiff=predicted
# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = infection, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 75th percentile
rm(list = ls())
infection.75 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_infection.75probs.csv")
inf.model.75 <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
                      priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection.75, family = binomial,weights=w)
#obtain AIC
original_aic_75 <- AIC(inf.model.75)
original_aic_75

library(boot)
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
               priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection.75[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = infection.75, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Predict probabilities
#F_cdiff=observed
#I_cdiff=predicted
# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = infection.75, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = infection.75, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = infection.75, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 90th percentile
rm(list = ls())
infection.90 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_infection.90probs.csv")
inf.model.90 <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
                      priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection.90, family = binomial,weights=w)
#obtain AIC
original_aic_90 <- AIC(inf.model.90)
original_aic_90

library(boot)
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(cdiff ~ v1_demog_age + v1_course_los + v1_course_icu + currentant +
               priorant + v1_currentabx_steroid + v1_priorabx_steroid + insurance + HC_referral, data = infection.90[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = infection.90, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Predict probabilities
#F_cdiff=observed
#I_cdiff=predicted
# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = infection.90, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "I_cdiff"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = infection.90, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_cdiff"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = infection.90, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

###SEVERITY MODEL
#unweighted
rm(list = ls())
severity <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_severity.probs.csv")
sev.model<- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
                  insurance + v1_comorbid_transplant, data = severity, family = binomial)
#obtain AIC
original_aic <- AIC(sev.model)
original_aic

library(boot)
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
               insurance + v1_comorbid_transplant, data = severity[indices, ], family = binomial)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = severity, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = severity, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = severity, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = severity, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 75th percentile
rm(list = ls())
severity.75 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_severity.75probs.csv")
sev.model.75 <- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
                      insurance + v1_comorbid_transplant, data = severity.75, family = binomial,weights=w)
#obtain AIC
original_aic_75 <- AIC(sev.model.75)
original_aic_75

library(boot)
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
               insurance + v1_comorbid_transplant, data = severity.75[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = severity.75, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = severity.75, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = severity.75, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = severity.75, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 90th percentile
rm(list = ls())
severity.90 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_severity.90probs.csv")
sev.model.90 <- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
                      insurance + v1_comorbid_transplant, data = severity.90, family = binomial,weights=w)
#obtain AIC
original_aic_90 <- AIC(sev.model.90)
original_aic_90

library(boot)
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(severity ~ v1_demog_age + v1_course_los + currentant + v1_currentabx_chemo + v1_priorabx_proton +
               insurance + v1_comorbid_transplant, data = severity.90[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = severity.90, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = severity.90, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "I_severity"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = severity.90, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_severity"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = severity.90, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

###REINFECTION MODEL
#unweighted
rm(list = ls())
rec <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_reinfection.probs.csv")
rec.model <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
                 + v1_comorbid_transplant + gastro, data = rec, family = binomial)
#obtain AIC
original_aic <- AIC(rec.model)
original_aic
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
             + v1_comorbid_transplant + gastro, data = rec[indices, ], family = binomial)
  return(AIC(fit))
}

# Perform bootstrap resampling
# Set seed for reproducibility
set.seed(1234)
boot_results <- boot(data = rec, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = rec, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = rec, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = rec, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 75th percentile
rm(list = ls())
rec.75 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_rec.75probs.csv")
rec.model.75 <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
                    + v1_comorbid_transplant + gastro, data = rec.75, family = binomial,weights=w)
#obtain AIC
original_aic_75 <- AIC(rec.model.75)
original_aic_75
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
             + v1_comorbid_transplant + gastro, data = rec.75[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = rec.75, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = rec.75, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = rec.75, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = rec.75, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)

#weighted 90th percentile
rm(list = ls())
rec.90 <- read.csv("/Users/nicolerafalko/Desktop/RA/CDI/final datasets/cdi_rec.90probs.csv")
rec.model.90 <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
                    + v1_comorbid_transplant + gastro, data = rec.90, family = binomial,weights=w)
#obtain AIC
original_aic_90 <- AIC(rec.model.90)
original_aic_90
# Create a function to calculate AIC
aic_func <- function(data, indices) {
  fit <- glm(reinfection ~ v1_demog_age + v1_course_los + currentant + v1_priorabx_proton + v1_chem_wbc + v1_cci_total
             + v1_comorbid_transplant + gastro, data = rec.90[indices, ], family = binomial, weights=w)
  return(AIC(fit))
}

# Perform bootstrap resampling
set.seed(1234)
boot_results <- boot(data = rec.90, statistic = aic_func, R = 1000)
# calculate CI
boot_ci <- boot.ci(boot_results, type = "all")
boot_ci

# Function to calculate sensitivity
calc_sensitivity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true positive and false negative counts
  true_pos <- sum(observed == 1 & predicted == 1)
  false_neg <- sum(observed == 1 & predicted == 0)
  # Calculate sensitivity
  sensitivity <- true_pos / (true_pos + false_neg)
  return(sensitivity)
}

# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_sensitivity <- boot(data = rec.90, statistic = calc_sensitivity, R = 1000)
print(boot_sensitivity)
# Get bootstrap results
boot_results_sens <- boot.ci(boot.out = boot_sensitivity, type = "all")
# Print bootstrap confidence intervals
print(boot_results_sens)

#### bootstrapping CI for specificity
# Function to calculate specificity
calc_specificity <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "I_reinfection"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate true negative and false positive counts
  true_neg <- sum(observed == 0 & predicted == 0)
  false_pos <- sum(observed == 0 & predicted == 1)
  # Calculate specificity (true negative rate)
  specificity <- true_neg / (true_neg + false_pos)
  return(specificity)
}
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_specificity <- boot(data = rec.90, statistic = calc_specificity, R = 1000)
# Get bootstrap results
boot_results_spec <- boot.ci(boot.out = boot_specificity, type = "all")
print(boot_specificity)
# Print bootstrap confidence intervals
print(boot_results_spec)

# Function to calculate AUROC
calc_auroc <- function(data, indices) {
  observed <- data[indices, "F_reinfection"]
  predicted <- data[indices, "P_1"]
  # Exclude missing values
  complete_cases <- complete.cases(observed, predicted)
  observed <- observed[complete_cases]
  predicted <- predicted[complete_cases]
  # Calculate AUROC
  roc_obj <- roc(observed, predicted)
  auroc <- auc(roc_obj)
  return(auroc)
}
library(pROC)
library(boot)
install.packages("caret")
library(caret)
# Set seed for reproducibility
set.seed(1234)
# Bootstrap function
boot_auroc <- boot(data = rec.90, statistic = calc_auroc, R = 1000)
#
print(boot_auroc)
# Get bootstrap results
boot_results_auc <- boot.ci(boot.out = boot_auroc, type = "all")
# Print bootstrap confidence intervals
print(boot_results_auc)
