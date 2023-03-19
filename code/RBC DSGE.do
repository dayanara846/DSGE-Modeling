clear
clear all
macro drop _all
capture log close 
set maxvar 32767
set matsize 11000
set more off, permanently
cd "C:\Users\scyth\OneDrive - Northeastern University\Macro-7720\My_Project\Data"

********************************************************************************
******* 	Data Clean for Puerto Rico Macroeconomic Info   ********************
******* 				DSGE RCB				  ******************************
*******  		YEAR 1976 - 2021 	                      **********************
***			All raw data is downloaded from different datasets               ***
********************************************************************************


import excel "Data.xlsx", firstrow clear

**----- Descriptive Statistics
ssc install asdoc
summarize 
asdoc sum

**----- set working directory again
cd "C:\Users\scyth\OneDrive - Northeastern University\Macro-7720\My_Project\Results"

** ---- Generate trend and elasticities
tsset Time
* HP Filter \w lamnbda=6.25 (smoothing parameter for annual data according to https://www.econstor.eu/bitstream/10419/75742/1/cesifo_wp479.pdf)
generate ln_GDP = 100*ln(GDP)
*----- hp(ln(GDP)) = Y
tsfilter hp hp_ln_GDP = ln_GDP, smooth(6.25) trend(trend)

generate ln_Consumption = 100*ln(Consumption)
tsfilter hp hp_ln_C = ln_Consumption, smooth(6.25) 

destring Investment, replace force

generate ln_Investment = 100*ln(Investment)
tsfilter hp hp_ln_I = ln_Investment, smooth(6.25) 

generate ln_Hours = 100*ln(Hours)
tsfilter hp hp_ln_H = ln_Hours, smooth(6.25) 


*labels
label variable hp_ln_I "Investment Cycle"
label variable hp_ln_H "Hours Worked Cycle"
label variable hp_ln_GDP "GDP Cycle"
label variable GDP "GDP"
label variable trend "GDP Trend"
label variable hp_ln_C "Consumption Cycle"

**----- Graphs
*graph GDP trend 
tsline ln_GDP trend, ytitle("Millions of Dollars (Current USD)") xtitle("Years") xtitle("Years") ylabel(#5) ylabel(,labsize(small)) ytick(#5) graphregion(color(white)) title("GDP PR") subtitle("Actual - Trend") 

*graph the GDP cycle
tsline hp_ln_GDP, yline(0)  legend(col(1))  ytitle("Difference from trend (%)") xtitle("Years") xtitle("Years") ylabel(#5) ylabel(,labsize(small)) ytick(#5) graphregion(color(white)) title("PR GDP Cycle") subtitle("1976-2021") 

*graph the business cycles for all the endogenous variables
tsline hp_ln_GDP hp_ln_C hp_ln_I hp_ln_H, yline(0) ytitle("Difference from trend (%)") xtitle("Years") xtitle("Years") ylabel(#5) ylabel(,labsize(small)) ytick(#5) graphregion(color(white)) title("PR Business Cycle - w/ Variables") subtitle("1976-2021") 




** -------- Model

constraint 1 _b[beta]=0.99	        // Utility Discount Factor or Intertemporal Consumption
constraint 2 _b[alpha]=0.33		    // Capital Share 
constraint 3 _b[delta]=0.10	        // Depreciation Rate of Capital
constraint 4 _b[gamma]=3.8	        // Elasticity Share of Leisure

dsgenl  ( (F.hp_ln_C/hp_ln_C) = ({beta}*(1+F.r-{delta})) ) 	    /// Euler Equation (13)
        ( hp_ln_GDP = k^({alpha})*(a*hp_ln_H)^(1-{alpha}) ) 	/// Production Function (1)
        ( r = {alpha}*hp_ln_GDP/k ) 							/// Interest (16)
        ( hp_ln_H =  (w-{gamma}*hp_ln_C)/w) 				    /// Labor Supply (12)
        ( w = (1-{alpha})*hp_ln_GDP/hp_ln_H) 				    /// Wages (20)
        ( F.k = (1-{delta})*k+hp_ln_I ) 						/// Law of Motion of Capital (15)
        ( ln(F.a) = {rho_a}*ln(a) ) 					        /// Productivity Shock (21) 
		(hp_ln_GDP =hp_ln_I+hp_ln_C) 							/// Aggregate equation (14) 
        , constraint(1/4) observed(hp_ln_GDP) unobserved(hp_ln_C r hp_ln_H w hp_ln_I) endostate(k) exostate(a) noidencheck
* export table
outreg2 using First_order_DSGE_Model.doc, replace ctitle(control) 

	estat steady, compact	
* export table
* 	just copy paste into Word

	estat covariance, nocovariance
* export table
* outreg2 using Variance.doc

	estat policy, compact

	estat transition, compact
	
	summarize hp_ln_C hp_ln_I hp_ln_H hp_ln_GDP
	
* export table
outreg2 using Summary.doc


     

// Check on Model

// Eigenvalue stability
*estat stable
	  
// Steady state
estat steady, compact

// Display estimated covariances of model variables

estat covariance
estat covariance, nocovariance

summarize hp_ln_C hp_ln_I hp_ln_H hp_ln_GDP

// Impulse Response Functions

irf set solowirf
irf create imp_res, replace step(48)
irf graph irf, irf(imp_res) impulse(a) response(a hp_ln_GDP hp_ln_I k hp_ln_C hp_ln_H r w) yline(0) xlabel(0(4)48) byopts(yrescale) legend( nobox region(lstyle(none)) ) xtitle("Years") scheme(s1mono) 


// Out of Sample Forecast

* Set the time variable to quarterly
tsset Time, quarterly

estimates store dsge_est
tsappend, add(16)
forecast create dsgemodel, replace
forecast estimates dsge_est
forecast solve, prefix(d1_) begin(tq(2465q1))
label variable hp_ln_GDP "GDP Cycle"
label variable d1_hp_ln_GDP "GDP Cycle Forecast"
tsline d1_hp_ln_GDP hp_ln_GDP, tline(2464q4) yline(0)legend(col(1))  ytitle("% Change") xtitle("Years") xtitle("Years") ylabel(#5) ylabel(,labsize(small)) ytick(#5) graphregion(color(white)) title("U.S GDP Cycle") subtitle("Actual - Forecast") 

// One Step Ahead Prediction
predict dep
label variable dep "GDP - One Step Ahead Prediction"
tsline hp_ln_GDP dep, legend(col(1)) legend(col(1))  ytitle("Deviation from Trend (%)") xtitle("Years") xtitle("Years") ylabel(#5) ylabel(,labsize(small)) ytick(#5) graphregion(color(white)) title("U.S GDP Cycle") subtitle("Actual - One Step Ahead Forecast") 
