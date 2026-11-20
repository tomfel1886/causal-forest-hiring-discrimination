# Causal Forest Analysis: Racial Discrimination in Hiring

## Project Overview

This project was completed as part of the course Machine Learning in Economics during my MSc in Economics at the University of Bern.

The objective is to investigate racial discrimination in the hiring process using causal machine learning methods. Specifically, I examine whether job applicants with African-American-sounding names receive fewer callbacks than applicants with White-sounding names, and whether the effect differs across applicant characteristics.

The analysis is based on the experimental dataset from Bertrand and Mullainathan (2004), Are Emily and Greg More Employable than Lakisha and Jamal? A Field Experiment on Labor Market Discrimination.

The project combines traditional econometric methods with causal machine learning to estimate average and heterogeneous treatment effects.

## Research Questions

1. Does having an African-American-sounding name affect the probability of receiving a callback?
2. Does the treatment effect vary across applicant characteristics, such as resume quality, work experience, and skills?
3. How do estimates from a traditional linear probability model compare with those from a causal forest?

## Data

The analysis uses data from the correspondence experiment conducted by Bertrand and Mullainathan (2004).

The dataset contains 4,870 fictitious job applications sent in response to job advertisements in Boston and Chicago.

The main variables are:

* Outcome: Whether an applicant received a callback.
* Treatment: Whether the application was assigned an African-American-sounding name.
* Covariates: Resume characteristics, work experience, education, skills, and neighbourhood characteristics.

## Methodology

**1. Linear Probability Model**

As a benchmark, I estimate a linear probability model (OLS) to measure the average effect of an African-American-sounding name on callback probability.

Standard errors are clustered at the job advertisement level to account for potential dependence between applications submitted to the same advertisement.

**2. Causal Forest**

I implement a causal forest using the grf package in R.

The model is designed to estimate treatment effects while allowing them to vary across observations.

Key specifications include:

* 10,000 trees
* Honest estimation
* Clustering at the job advertisement level
* Known treatment probability of 0.5

I use the model to estimate the average treatment effect (ATE) and explore treatment-effect heterogeneity across applicant characteristics.

**3. Model Evaluation and Robustness**

To evaluate the results, I conduct several additional analyses:

* Calibration tests using test_calibration().
* Variable importance analysis to identify characteristics used by the forest when estimating treatment-effect heterogeneity.
* Subgroup analyses based on resume quality and individual resume characteristics.
* Robustness checks using complete observations and an extended set of covariates.
* Sensitivity analysis using different numbers of trees (500, 2,000, and 10,000).

## Visualizations

The analysis includes several visualizations:

* Distribution of predicted treatment effects.
* Variable importance ranking.
* Estimated treatment effects across resume-quality groups.
* Estimated treatment effects for selected resume characteristics, including computer skills, volunteering, and employment gaps.

## Tools and Packages

Programming language: R

Main packages:

* grf – Causal forest estimation and treatment-effect analysis.
* haven – Importing Stata datasets.
* lmtest – Statistical hypothesis testing.
* sandwich – Cluster-robust variance estimation.
* stargazer – Regression tables and presentation of results.

## Data Availability and Reproducibility

The dataset used in this project originates from Bertrand and Mullainathan (2004) and is available through the openICPSR repository.

The dataset (lakisha_aer.dta) is included in the data/ directory to facilitate reproducibility.

### Data License

The original dataset is copyrighted by the American Economic Association (2004) and distributed under the Creative Commons Attribution 4.0 International License (CC BY 4.0).

The dataset is redistributed without modification, with attribution to the original authors and copyright holder.

### Reproducing the Analysis

1. Download or clone this repository.
2. Install the required R packages (grf, haven, lmtest, sandwich, stargazer).
3. Open the project directory in RStudio.
4. Run causal_forest_analysis.R.

The analysis uses a fixed random seed (set.seed(1234)) to support reproducibility.

## Reference

Bertrand, M., & Mullainathan, S. (2004). Are Emily and Greg More Employable than Lakisha and Jamal? A Field Experiment on Labor Market Discrimination. American Economic Review, 94(4), 991–1013.

⸻

Author: Thomas Felder
Institution: University of Bern
Program: MSc Economics
