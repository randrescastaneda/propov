*! v BETA: 2.2.1	<24Mar2015>		
*! add option macrodata for selection of GDP projection
*! Add option to modifying monthly conversion

/*===========================================================================
project:       Calculate poverty projections based quantile-to-growth contribution, 
				elasticity and Neutral distribution
Author:        Andres Castaneda 
Dependencies:  The World Bank
---------------------------------------------------------------------------
Creation Date:     February 5, 2015 
Modification Date: February 24, 2015   
Do-file version:    06
References:          
Output:             excel and dta file
===========================================================================*/

/*=======================================================================================
                                  0: Program set up            
=======================================================================================*/
version 12

program define propov, rclass

syntax  [anything(name=lookup)], 					///
		COUNtry(string)								///
		PERiod(numlist min=2 max=2 sort)			///
		[											///
		nq(integer 20)								///
		POVlines(numlist)							///
		LASTyear(numlist max=1 integer)				///
		PASSthrough(numlist max=1 >0 <=1 )			/// factor to adjust growth
		povdata(string)								/// save results of poverty
		welfaredata(string)							/// save results of welfare
		GRaph(string)								/// gic | den | cont 
		replace										///
		clear										///
		region(string)								/// uses lac data
		annualized									/// annualized growth and poverty for elasticity
		welfvar(string)								///
		DISTribution(string)						///  democratic or plutocratic distribution of income within quantile 
		CONTribution(string)						///  Select mean or sum of each quantile
		method(string)								///
		MACROdata(string)							///
		MONTHly(string)								/// default 30.42
		write										/// write on final spreadsheet.
		]

		
** -------------------------- 0.1 Considerations and defaults
* Check latest version
qui adoupdate propov
if (strmatch( "`r(pkglist)'","propov" ) & "${propovpopup}" != "check") {
	cap window stopbox note "A new version of -propov- has been released." ///
		"To update -propov- you can do one of the following:"  ///
		"i) Follow instruction on screen, or ii) type propov_update in stata." ///
		"If you don't want to update, this message will pop up next time you open Stata and use -propov-"
	global propovpopup "check"
	noi disp in y _n "Click {stata propov_update:here} to update {cmd: propov}"
}
*/


* Poverty lines
if ("`povlines'" == "") {
	numlist "1.25 2.5 4"
	local povlines = "`r(numlist)'"
}
local years = "`period'"

* Pass-through
if ("`passthrough'" == "") local passthrough = 1

* Distribution
if ("`distribution'" == "") local distribution = "plutocratic"

* contribution
if ("`contribution'" == "") local contribution = "sum"
if ("`contribution'" == "sum") local gdp2use ""
if ("`contribution'" == "mean") local gdp2use "pc"

* Monthly factor for poverty line. 
if ("`monthly'" == "") local monthly = 30.42

** ----------------------------- 0.2 General Variables


if ("`region'" == "") {
	if ("`welfvar'" == "") local welfvar  "welfare" // in case user wants to use another welfare var
	local weight    "weight"
	local hhid      "hhid"
	local hsize     "hsize"
	local year      "year"
	local datain "\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\_ado\propov\_projections"
}
if ("`region'" == "lac") {
	if ("`welfvar'" == "") local welfvar  "ipcf"	// in case user wants to use another welfare var
	local weight "pondera"
	local hhid   "id"
	local hsize  "miembros"
	local year   "ano"
	local datain "Z:\public\Stats_Team\Poverty Projections\data\Projections"
}

qui {		// qui the entire program. 
cap which renvars
if _rc ssc install renvars

cap which apoverty
if _rc ssc install apoverty

cap which quantiles
if _rc ssc install quantiles

cap findfile scheme-burd.scheme
cap if _rc ssc install scheme-burd, replace
cap set scheme burd

preserve
*------------------------------------0.3: Initial conditions

local yeara: word 1 of `years'				//first year of the period of reference 
local yearb: word 2 of `years'				//second year of the period of reference (Base line)


**********   USING INTERNAL DATALIB 
if ("`region'" == "lac") datalib_displaysedlac, country(`country') type(sedlac) pro(02)

*********** USING GPWG database
if ("`region'" == "") datalib2_years `country'

** Identify last available year. 
local avyears = "`r(years)'"
if ("`lastyear'" == "") {
	local yearc = word("`avyears'", -1)
}

* Check availability of data
else {
	if (`: list posof "`lastyear'" in avyears' == 0) {
		noi disp as err "`lastyear' is not available in datalib dataset"
		error 197
	}
	else {
		local yearc = `lastyear'
	}
}

if ("`yearb'" != "`yearc'") local years "`years'  `yearc'"
if ("`yearc'" < "`yearb'") {
	noi disp as err "Last year disposable with data (`yearc') cannot be smaller than second year of period of reference (`yearb')"
	err 197
}
/*====================================================================================
                          1: data with population and GDP
====================================================================================*/

*------------------------------------1.1: Load GDP and population

if ("`macrodata'" == "") {		// use global Macro data
	propov_macrodata `country', indicator(gdp) datain("`datain'")
	keep if (year >= `=`yeara'-1')
}

else {		//  use Internal Macro data
	use if (country == "`country'" & year >= `=`yeara'-1') ///
		using "`macrodata'", clear
	sort year
}


* calculate growth and cumulative growth PER CAPITA and total growth

foreach pc in pc t {
	if ("`pc'" == "t") local pc ""
	gen gdp`pc'_gr = (gdp`pc'[_n]/gdp`pc'[_n-1])-1		// percentage growth
	gen gdp`pc'_grp = gdp`pc'_gr*`passthrough'			// Pass through effect
	gen gdp`pc'_tgr = gdp`pc'_grp +1 					// total growth = total value + change (1 + g)

	replace gdp`pc'_tgr = 1 if gdp`pc'_tgr == .

	gen gdp`pc'_cgr = 1 if year <= `yearc'
	replace gdp`pc'_cgr = gdp`pc'_tgr[_n]*gdp`pc'_cgr[_n-1] ///  cumulative growth
		if (gdp`pc'_cgr != 1)	
	
	// years to use in calculations
	local N = _N-1
	foreach n of numlist 1/`N' {
		if year[_n+`n'] > `yearc' local gdp`pc'grs "`gdp`pc'grs' `:disp gdp`pc'_cgr[_n+`n']'"
	}
}


* Population growth
gen     pop_tgr = (pop[_n]/pop[_n-1])		// Total growth
gen     pop_gr = pop_tgr-1					// percentage growth
gen pop_cgr = 1 if year <= `yearc'
replace pop_cgr = pop_tgr[_n]*pop_cgr[_n-1] ///  cumulative growth
	if (pop_cgr != 1)	

local N = _N-1
foreach n of numlist 1/`N' {
	if year[_n+`n'] > `yearc' local popgrs "`popgrs' `:disp pop_cgr[_n+`n']'"
}


* Matrix to be loaded for Elasticities
drop *_tgr

tempname GDP GDPpc POP
mkmat year gdp gdp_gr gdp_grp gdp_cgr, mat(`GDP')
mkmat year gdppc gdppc_gr gdppc_grp gdppc_cgr, mat(`GDPpc')
mkmat year pop pop_gr pop_cgr, mat(`POP')

drop gdp pop gdppc gdp country 
reshape long gdppc_ gdp_ pop_, i(year) j(type) string
renvars gdppc_ gdp_ pop_, prefix(value)
renvars value*, postdrop(1)
reshape long value, i(year type) j(indicator) string

** Labels and names


replace type = "Cumulative growth" 					  if type == "cgr"
replace type = "annual growth"     					  if type == "gr"
replace type = "annual growth adj by pass-trough"     if type == "grp"

replace indicator = " Total GDP. "       if indicator == "gdp"  
replace indicator = " GDP per capita. "  if indicator == "gdppc"
replace indicator = "Population. "      if indicator == "pop"  

label var type      "Type of growth"
label var value     "growth rates"
label var year      "Growth projection for "
label var indicator "Indicator"

* Display
noi tabdisp type  year ///
	if (inlist(year,`yeara',`yearb') | year >= `yearc'), ///
	c(value) by(indicator) format(%5.3f)
noi disp in green "Pass-through in use = " in y `passthrough'
 
/*====================================================================================
                               2: create quantiles
====================================================================================*/

*-----------------------------2.0: Load data bases 

**********   USING INTERNAL DATALIB 
if ("`region'" == "lac") {

* Call both surveys at the same time
	datalib, countr(`country') year(`years')  clear
	keep `year' `welfvar'_ppp `weight' `hhid' `hsize' 
	renvars `year' `welfvar'_ppp `weight' `hhid' `hsize' \ year welfare weight hhid hsize
}
*********** USING GPWG database
if ("`region'" == "") {			// NOTE: the append option of datlaib2 is not working correctly
	
	if (`yearb' < `yearc') {
		datalib2, year(`yearc') country(`country') type(gpwg) welfppp(`welfvar') clear
		tempfile gpwgsvc
		save `gpwgsvc'
	}
	
	datalib2, year(`yearb') country(`country') type(gpwg) welfppp(`welfvar') clear
	tempfile gpwgsvb
	save `gpwgsvb'
	
	datalib2, year(`yeara') country(`country') type(gpwg) welfppp(`welfvar') clear
	append using `gpwgsvb' `gpwgsvc', force
	
	keep `year' `welfvar'_ppp `weight' `hhid' `hsize' 
	ren `welfvar'_ppp welfare
	replace welfare = welfare/12		// transform to monthly 
}

*-----------------------------2.1: Poverty with Real welfare 

tempname PovGQC
foreach y of local years {
	foreach povline of local povlines {
		apoverty welfare [pw = weight] if (year == `y'), line(`=`povline'*`monthly'')
		mat `PovGQC' = nullmat(`PovGQC')\ `y', `povline', `r(head_1)', 0
	}
}

*-----------------------------2.2: Quantiles
drop if welfare == .  			//  if wanted, here we can exclude welfare == 0 as well. 
bysort year (welfare): quantiles welfare [fw = int(weight)], gen(qtl) n(`nq')  keeptog(hhid) // quantiles  

* save survey of the second year for further procedures

tempfile svy1 svy2
save `svy1', replace
	keep if year == `yearc'
	rename welfare welfare`yearc'
	tempfile svy2
	save `svy2', replace
use `svy1', clear


*specify mean or sum by quantile 
* Create data at quantile level
noi disp _n in y "Contribution of quantiles based on the " ///
	in green "`contribution'" in y " of welfare of each quantile" _n

collapse (`contribution') welfare [pw = weight], by(year qtl)   // This is the controversial issue

drop if qtl == .
reshape wide welfare, i(q) j(year)

/*====================================================================================
                                  3: Contributions  
====================================================================================*/

*----------------------------3.1:differences and total

* generate differences
gen diffwelfare = welfare`yearb' - welfare`yeara'		// Bins differences

sum diffwelfare
local totdiff = r(sum)		//  total welfare chance

gen cont = diffwelfare/`totdiff' // contributions 
label var cont "contribution by quantile"

sum cont 
assert round(r(sum), 0.001) == 1 

tempfile qtlsvys
save `qtlsvys', `replace'			// database in case user needs GIC

*-------------------------3.2: get back to survey of second year
keep qtl cont
merge 1:m qtl using `svy2', nogen
sort year qtl

/*=====================================================================================
                                  4: Calculate new welfare
=====================================================================================*/

*----------------------4.1: redistribution of growth 

* democratic distribution
tempvar wwelfare welfqtl
if ("`distribution'" == "democratic") {
	noi disp in g "DEMOCRATIC" in y " distribution within quantile" _n
	gen `wwelfare' = weight
	bysort qtl: egen `welfqtl' = total(`wwelfare')
}

* Plutocratic redistribution
if ("`distribution'" == "plutocratic") {
	noi disp in g "PLUTOCRATIC" in y " distribution within quantile"
	gen `wwelfare' = weight*welfare`yearc'
	bysort qtl: egen `welfqtl' = total(`wwelfare')
}


*------------------------------4.2: New welfare
sum welfare`yearc'     [fw = int(weight)] 
local totwelfareb = r(sum)

local n = 0 		// number of years to project
qui foreach gdpgr of numlist `gdp`gdp2use'grs' {
	local ++n 
	local expwelfare = `totwelfareb'*`gdpgr'		// Expected welfare for projected year 
	local welfare2dist = `expwelfare'-`totwelfareb'		// welfare to be distributed
	
	** New population
	gen weight`=`yearc'+`n'' = weight*`: word `n' of `popgrs''
	
	**  transfer and proportion per household
	tempvar trans hhshare 
	
	gen `hhshare' = (`wwelfare'/`welfqtl')*(cont/weight`=`yearc'+`n'')  // share of inc to each hh 
	gen `trans' = `welfare2dist'*`hhshare'			// increase of welfare to each household
	egen welfare`=`yearc'+`n'' =  rowtotal(welfare`yearc' `trans')
	
	* poverty rates
	foreach povline of local povlines {
		local line = `povline'*`monthly'
		apoverty welfare`=`yearc'+`n''  [pw = weight`=`yearc'+`n''], line(`line')
		mat `PovGQC' = nullmat(`PovGQC')\ `=`yearc'+`n'', `povline', `r(head_1)', 1 
	} 		// end of pov lines loop

}	//  end of loop for projected years

/*=====================================================================================
                       5: Projecting poverty with other methods
=====================================================================================*/
 


*----------------------------- 5.1: elasticities

* Load matrix with poverty rates
mat colnames `PovGQC' = ys povline rate method
svmat `PovGQC', n(col)

foreach y of local years {
	local l = 0 
	foreach line of local povlines {
		local ++l
		sum rate if (ys == `y' & povline == `line'), meanonly
		local r`y'`l' = r(mean)
	}
}

drop ys povline rate method


* Load matrix GDP Growth 

mat colnames `GDPpc' = ys gdp gr grp cgr 
svmat `GDPpc', n(col)

levelsof ys, local(ys)

foreach y of local ys {
	sum   gr if (ys == `y'), meanonly 	// growth
	local g`y'  = r(mean)

	sum  cgr if (ys == `y'), meanonly 	// cumulative growth
	local cg`y' = r(mean)
	
	sum  gdp if (ys == `y'), meanonly 	// gdp
	local gdp`y' = r(mean)
}

drop  ys gdp gr grp cgr 

local a = `gdp`yearb''/`gdp`yeara''
if ("`annualized'" == "annualized") {
	local b = 1/(`yearb'-`yeara')
	local ag = (`a'^`b')-1		//  Annualized GDP growth
}
else local ag = `a'-1		//  Non-Annualized GDP growth


* Elasticities
tempname E
local l = 0 
foreach line of local povlines {
	local ++l
	if ("`annualized'" == "annualized") {
		local a = (`r`yearb'`l''/`r`yeara'`l'')
		local b = (1/(`yearb'-`yeara'))
		local ar`l' = (`a'^`b')-1 // Annualized pov change
	}
	else local ar`l' = (`r`yearb'`l''/`r`yeara'`l'')-1 // Non-Annualized pov change
	local e`l' = `ar`l''/`ag'				// elasticity 
	mat `E' = nullmat(`E') \ `line', `e`l''
}

** Poverty rates for elasticity method

local l = 0 
foreach povline of local povlines {
	local ++l
	foreach y of local ys {
		if (`y' > `yearc') {
			local r`y'`l' = (`e`l''*`g`y''+1)*`r`=`y'-1'`l''
			mat `PovGQC' = nullmat(`PovGQC')\ `y', `povline', `r`y'`l'', 2
		}
	}	// end of years loop
}	// end of poverty lines loop



*------------------------------- 5.2. Neutral distribution

foreach povline of local povlines {
	foreach y of local ys {
		if (`y' > `yearc') {
			tempvar welfare`y'
			gen `welfare`y'' = welfare`yearc'*`cg`y''				// new welfare
			apoverty `welfare`y'' [pw = weight`=`yearc'+`n''], line(`=`povline'*`monthly'')
			mat `PovGQC' = nullmat(`PovGQC')\ `y', `povline', `r(head_1)', 3
		}
	}	// end of years loop
}	// end of poverty lines loop


*----------------- 5.3. Display all methods

svmat `PovGQC', n(col)
label define method 0 "Real" 1 "GCQ" 2 "Elasticity" 3 "Neutral Dist.", modify
label values method method

label var ys        "Year"
label var povline   "Pov. Line-USD"
label var rate      "Poverty rate"
label var method    "Poverty Rate for each Method"

noi tabdisp ys method if !missing(ys), c(rate) format(%4.3f) by(povline) center

*----------------- 5.4 Fix data and save
rename weight weight`yearc'

* save poverty data
if ("`povdata'" != "") {
	tempfile aa
	save `aa', replace
	keep ys povline rate method 
	drop if ys == . 
	save "`povdata'", `replace'
	use `aa', clear
}

* save welfare data
keep qtl cont weight* welfare*
if ("`welfaredata'" != "") {
	save "`welfaredata'", `replace'
}


/*=====================================================================================
                       6: Density and GICs
=====================================================================================*/

*-------------------------6.1: Density
if (regexm("`graph'", "den")) {
	
	local lplace = .0009
	foreach povline of local povlines {
		local xlines = "`xlines'  `=`povline'*`monthly''"
		local textlines `"`textlines' text(`lplace' `=`povline'*`monthly'' " `povline' usd", place(e) size(small))"'
		local lplace = `lplace'-.0003
	}
	tempname grdensity
	twoway (kdensity welfare`yearc' [w = weight`yearc'], range(0 500)) ///
		   (kdensity welfare`=`yearc'+1' [w = weight`=`yearc'+1'], range(0 500)),  ///
		xline(`xlines') name(`grdensity') legend(size(small)) ///
		xtitle("Monthly Welfare USD PPP") title("Kernel Density for `country'") ///
		legend(label(1 "Welfare `yearc' (real)") label(2 "Welfare `=`yearc'+1' (projected)")) ///
		`textlines'
	local grnames "`grnames' `grdensity' "
}		//  end of condition for density


*------------------------6.2: Calculation of GICs 

if (inlist("`graph'", "gic", "cont")) {
	gen n = _n
	reshape long weight welfare, i(n qtl) j(year)
	drop n
	collapse (mean) welfare [pw = weight], by(year qtl)   
	reshape wide welfare, i(qtl) j(year)
	merge 1:1 qtl using `qtlsvys', nogen  keepusing(welfare`yeara' welfare`yearb' cont)

	* GICs
	gen gic = 100*((welfare`yearb'/welfare`yeara')^(1/(`yearb'-`yeara'))-1)
	gen gicp = 100*((welfare`=`yearc'+1'/welfare`yearc')-1)

	*contribution
	replace cont = 100*cont

	*label variables
	label var welfare`yeara' "welfare `yeara' (real)"
	label var welfare`yearb' "welfare `yearb' (real)"
	label var welfare`yearc' "welfare `yearc' (real)"

	foreach y of numlist 1/`n' {
		label var welfare`=`yearc'+`y'' "welfare `=`yearc'+`y'' (projected)"
	}
	label var cont "% Quantile contribution to growth"
	label var gic    "% GIC (real `yeara'-`yearb')"
	label var gicp  "% GIC (projected `yearc'-`=`yearc'+1')"

	** Display graphs
	if (regexm("`graph'", "gic")) {
		tempname grgicname
		twoway (line gic gicp qtl), ///
			title("Annualized GIC for `country'") name(`grgicname') legend(size(small))
		local grnames "`grnames' `grgicname' "
	}
	if (regexm("`graph'", "cont")) {
		tempname grgcontname
		twoway (line cont qtl), ///
			title("Quantile Contribution to Growth using the `contribution' for `country'") ///
			name(`grgcontname') legend(size(small))
		local grnames "`grnames' `grgcontname' "
	}
}	// end of GIC and Contribution estimations. 

if (wordcount("`grnames'")>1) graph combine `grnames' 

order qtl welfare*
/*=====================================================================================
                              7: Organizing Results
=====================================================================================*/

tempname GIC_wide GIC_long

*------------- matrices 
*GIC

if (inlist("`graph'", "gic", "cont")) {
	mkmat _all, mat(`GIC_wide')
	return matrix GIC_wide = `GIC_wide'

	reshape long welfare, i(qtl) j(year)
	mkmat _all, mat(`GIC_long')
	return matrix GIC_long = `GIC_long'
}

* growth per capita, Total growth, and population

mat colnames `GDP'   = year gdp grwoth gr_pass-thr cumulative_gr
mat colnames `GDPpc' = year gdppc grwoth gr_pass-thr cumulative_gr
mat colnames `POP'   = year pop growth cumulative_gr 
return matrix GDP    = `GDP'
return matrix GDPpc  = `GDPpc'
return matrix POP    = `POP'

 
* Poverty
mat colnames `PovGQC' = year povline rate method
return matrix Pov = `PovGQC'

* Elasticities

mat colnames `E' = povline elasticity
return matrix Elasticity = `E'

restore
}	// end qui

end

/*=====================================================================================
         8: Program to get last available year for specified country in GPWG portal
=====================================================================================*/


program define datalib2_years, rclass
syntax  anything(name=countrycode)

qui {
local countrycode  = upper("`countrycode'")

local a1 "ASM AUS BRN CHN FJI FSM GUM HKG IDN JPN KHM KIR KOR LAO MAC MHL MMR MNG MNP MYS NCL NZL PHL PLW PNG PRK PYF SGP SLB THA TLS TON TUV VNM VUT WSM"
lstrfun b, regexms("`a1'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "EAP"

local a2 "ALB AND ARM AUT AZE BEL BGR BIH BLR CHE CHI CYP CZE DEU DNK ESP EST FIN FRA FRO GBR GEO GRC GRL HRV HUN IMN IRL ISL ITA KAZ KGZ KSV LIE LTU LUX LVA MCO MDA MKD MLT MNE NLD NOR POL PRT ROU RUS SMR SRB SVK SVN SWE TJK TKM TUR UKR UZB"
lstrfun b, regexms("`a2'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "ECA"

   	local a3 "ABW ARG ATG BHS BLZ BOL BRA BRB CHL COL CRI CUB CUW CYM DMA DOM ECU GRD GTM GUY HND HTI JAM KNA LCA MEX NIC PAN PER PRI PRY SLV SUR TCA TTO URY VCT VEN VIR SXM MAF"
lstrfun b, regexms("`a3'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "LAC"

local a4 "ARE BHR DJI DZA EGY IRN IRQ ISR JOR KWT LBN LBY MAR OMN PSE QAT SAU SYR TUN YEM"
lstrfun b, regexms("`a4'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "MNA"

local a5 "AFG BGD BTN IND LKA MDV NPL PAK"
lstrfun b, regexms("`a5'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "SAR"

local a6 "AGO BDI BEN BFA BWA CAF CIV CMR COD COG COM CPV ERI ETH GAB GHA GIN GMB GNB GNQ KEN LBR LSO MDG MLI MOZ MRT MUS MWI NAM NER NGA RWA SDN SEN SLE SOM SSD STP SWZ SYC TCD TGO TZA UGA ZAF ZMB ZWE"
lstrfun b, regexms("`a6'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "SSA"

local a7 "BMU CAN USA"
lstrfun b, regexms("`a7'", "^.*([ \t]?)(`countrycode')(.*)$",2)
if ("`b'" == "`countrycode'") local reg "NAC"


local folders: dir "\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib/`reg'/`countrycode'" dirs "*"
disp `"`folders'"'

local years ""
foreach folder of local folders {
	if regexm("`folder'", "^([a-z]+_)([0-9]+)_*") local year  = regexs(2)
	local years "`years' `year'"
}

return local years "`years'"
}
end

/*=====================================================================================
         9: Program to retrieve Macro data
=====================================================================================*/



program define propov_macrodata, rclass
syntax  anything(name=countrycode),		///
				datain(string)			///
				[ indicator(string) ]

qui {
*Drop pre-existing data

drop _all

*Set Indicator Local
if ("`indicator'" == "") local indicator="gdp" 

/*=======================================================================================
                         Section 1: Open and organize the data    
========================================================================================*/

*1.1 Open GDP

if "`indicator'"=="gdp"{
	import delimited "`datain'/`countrycode'.csv", clear //Extract the GDP data base
	keep if indicatorcode=="NYGDPMKTPKN"           //I only keep the GDP 
	
	destring yr1960- yr2025, replace force         //Destring the data (everything was sent as string by MFM)
	gen country=lower(countrycode)                 // Generate the country code
	keep country yr2000- yr2016                    // Keep only the country code and the estimations for all the period that could be of interest (andres si queres esto reducilo a menos anos)
	reshape long yr, i( country ) j(year)          //Make the data in long style
	rename yr `indicator'                          // rename the variable names
	sort country year                              // rename the variable names
	
	tempfile gdp                                   // set temporary file name
	save `gdp', replace                            // save data
}

if "`indicator'"=="consumption"{
	import delimited "`datain'/`countrycode'.csv", clear //Extract the GDP data base
	
	keep if indicatorcode=="NECONPRVTKN"           //I only keep the Consumption 
	gen country=lower(countrycode)                 // Generate the country code
	aorder                                         //order variables in data
	keep country yr2000- yr2016	                   // Keep only the country code and the estimations for all the period that could be of interest (andres si queres esto reducilo a menos anos)
	destring yr2000- yr2016, replace force         //Destring the data (everything was sent as string by MFM)
	reshape long yr, i( country ) j(year)          //Make the data in long style
	rename yr `indicator'                          // change the variable names
	sort country year                              // change the variable names
	
	tempfile gdp                                   // set temporary file name
	save `gdp', replace                            // save data
}

/*
else{
	noi disp as err "`indicator' is not available in the MFM dataset"
	error 197
}
*/

*1.2 Open Population

import excel using "`datain'/HNPS_all_countries.xlsx", sheet("Data")   ///  Health Nutrition and Population Statistics All countrycode
	firstrow clear 

gen country=lower(CountryCode)                     // Gen the country code 
keep if country=="`countrycode'"                   // Keep the country of interest
aorder                                             //order variables in data
keep country YR2000- YR2016                        // Keep the variables of interest
destring YR2000- YR2016, replace force             //Destring the data (everything was sent as string by MFM)
reshape long YR, i( country ) j(year)              // Make the data in long style
keep country year YR                               // Keep the variables of interest
rename YR pop                                      // change the variable names
sort country year                                  // sort data

tempfile population                                // set temporary file name
save `population', replace                         // save data

*1.3 Merge and organize
merge 1:1 country year using `gdp', nogen

gen gdppc = `indicator'/pop
label var `indicator'pc "GDP per capita"
}
end




exit 
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1. History of the file 

v BETA: 2.1.1	<02Mar2015>		
	add missing "else" in elasticity section
	change all [fw = weight] for [fw = int(weight)]
v BETA: 2.1.0	<24Feb2015>		<Andres Castaneda>
	Add contribution option to choose between mean and sum
v BETA: 2.0.3	<24Feb2015>		<Andres Castaneda>
	Add distribution type option- democratic or plutocratic
	change to Mean of quantiles rather than sum of quantiles
	Fix some graphs
	Change option lac for option region for future additions
	Add option grpah and remove grgic, grden, and grcont 
	Fix bugs
v 1.0.2	<12Feb2015>		<Andres Castaneda>
	! Fix bug on annualized calculations. 
v 1.0.1	<11Feb2015>		<Andres Castaneda>

**************************************************************************
2.

3.

exit 
discard
propov, countr(pry) period(2005 2011)  grden nq(20)  dist(democratic) povdata(arg05-11)


if (lower("`region'") != "lac") net from "\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\_ado"
		else net from "S:\Datalib\_ado"
		net install propov, replace force 
