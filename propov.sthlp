{smcl}
{* *! version 1.0 25 Feb 2015}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install datalib2" "net install datalib2, from("\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\_ado""}{...}
{vieweralsosee "Help datalib2 (if installed)" "help datalib2"}{...}
{viewerjumpto "Syntax" "propov##syntax"}{...}
{viewerjumpto "Description" "propov##description"}{...}
{viewerjumpto "Options" "propov##options"}{...}
{viewerjumpto "Remarks" "propov##remarks"}{...}
{viewerjumpto "Examples" "propov##examples"}{...}
{title:Title}
{phang}
{bf:propov} {hline 2} Poverty Projections

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:propov}
{cmd:,} {ul:coun}try({it:country code}) {ul:per}iod({it:numlist min=2 max=2})
[
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt coun:try(string)}} Acronym of the country composed of three letters. Only one country allowed per command line.{p_end}
{synopt:{opt per:iod(min=2  max=2)}} Period of reference that would replicates the future changes in the income distribution. {p_end}
{synopt:{opt nq(#)}} Number of quantiles. {p_end}

{syntab:Flexibility}
{synopt:{opt pov:lines(string)}} International Daily Poverty lines.{p_end}
{synopt:{opt last:year(max=1  int)}} Data year used as baseline to project poverty. Default last data year available.  {p_end}
{synopt:{opt pass:through(real)}} Real value to adjust GDP growth. Default value is 1{p_end}
{synopt:{opt dist:ribution(real)}} Distribution within quantile. Either {it:democratic} or {it:plutocratic}{p_end}
{synopt:{opt cont:ribution(real)}} Contribution method of each quantile. Either {it:sum} or {it:mean}{p_end}
{synopt:{opt month:ly(exp)}} Monthly factor daily poverty day. Default is 30.42 {p_end}

{syntab:Graphs}
{synopt:{opt gr:aph(string)}} Displays analytic graphics. {it:den|gic|cont} {p_end}

{syntab:Additional}
{synopt:{opt povdata(string)}} Save dta file with poverty rates (real and projected){p_end}
{synopt:{opt welfaredata(string)}} Save dta file with welfare aggregates and weights (real and projected) {p_end}
{synopt:{opt macro:data(string)}} Specifies the root where the macro data projections is stored. MFM data stored in the GPWG portal is the default. {p_end}
{synopt:{opt region(string)}} Specifies the dataset source from which the data will be retrieved. GPWG portal is the default.{p_end}
{synopt:{opt replace}} Specifies that it is okay to replace the data in memory.{p_end}
{synopt:{opt clear}} Specifies that it is okay to clear the data in memory.{p_end}
{synopt:{opt annualized}} Uses annualized growth for Elasticity method. Default is point-to-point growth{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{p 4 6 2}{cmd:propov} calculates three types of projection of poverty: Quantile to Growth 
Contribution (QGC), Elasticity, and Neutral Distribution. {cmd:propov} displays two main 
outputs. A table with the cumulative and annual growth and another table with the poverty
 projections. Let's explain each method:
 
{p 4 6 2}{cmd:Elasticity:} In this method, {cmd:propov} calculates the ratio between the GDP 
{it:{ul:per capita}} growth and the poverty rate change between the two years of the period 
of reference. By default, {cmd:propov} uses point-to-point growth to construct the elasticity.
If option {it:annualized} is specified, elasticities are calculated using annualized growth
of GDP per capita and poverty change. 

{p 4 6 2}{cmd:Neutral Distribution:} In this method, {cmd:propov} adjusts the welfare distribution 
of the last year of data available (or of the year specified in the {it:lastyear()} option)
by the projected GDP {it:{ul:per capita}} growth. 

{p 4 6 2}{cmd:Quantile Contribution to Growth (QCG):} In this method, {cmd:propov} calculates the 
relative contribution of each quantile to the change of welfare in the economy between the 
two years of the period of reference. This is a two-stage process:

{p 6 9 2}1. {ul:Distribution of Growth among quantiles:} using the years of the period of reference,
the contribution of each quantile is calculated as the relative contribution of the...

{p 10 13 2}A. {opt cont:ribution(sum)}...difference in the {cmd:sum} of the income (expenditure) of each 
quantile over the difference of the total income. Since the total income of the economy is 
used, the {ul:total} GDP growth projections is used as well. {err: this is the default option}

{p 10 13 2}B. {opt cont:ribution(mean)}...difference in the {cmd:mean} of the income (expenditure)
of each quantile over the {cmd:sum} of the differences.Note that this is NOT the same as the
ratio of difference of the mean of each quantile over the difference in the total mean. However, 
by normalizing for the number of quantiles, this contribution is understood as 
{it:the relative contribution of each quantile to the change in the total mean}. Finally, since the 
mean income of the quantile is used, GPD {ul:per capita} projections are used as well. 

{p 6 9 2}2. {ul:Distribution of income within each quantile:} Once the change of income has been
distributed among quantiles, {cmd:propov} offers two ways for distributing income among individuals
(or households depending of the level of the survey) within the same quantile: 

{p 10 13 2}A. {opt dist:ribution(plutocratic)} Income is distributed according to the relative
participation of the income of each individual over the total income of the quantile. That is, 
the income to be allocated to each individual is based on the income distribution within the
quantile: the wealthiest get more the poorest get less. {err: this is the default option}

{p 10 13 2}B. {opt dist:ribution(democratic)} Income is distributed equally among all the individuals
of the same quantile. 
 
{p 6 6 2} Therefore, the user have four different combinations to calculate the new distribution 
of welfare. By default, {cmd:propov} calculates the {cmd:sum} of income of each quantile 
for the contribution and the {cmd:plutocratic} distribution among the individuals of the same
quantile. 
 
{marker options}{...}
{title:Options}
{dlgtab:Basics}
{phang}
{opt coun:try(string)} (["]acronym["]) Specifies the acronym of the country.  This is composed by three letters. For now propov only allows one country per command line.

{phang}
{opt per:iod(numlist min=2  max=2  sort)} Period to calculate the contribution of each quantile of the income distribution in the total country growth and also to calculate the elasticity of poverty to growth.

{dlgtab:Flexibility}

{phang}
{opt nq(#)} Number of quantiles. Default value is 20.

{phang}
{opt pov:lines(string)} International Daily Poverty lines. If not defined, the international daily poverty lines of $1.5, $2.5 and $4 will be used as default.

{phang}
{opt last:year(numlist max=1  integer)} Data year used as baseline to project poverty.
 If not defined, {cmd:propov} projects poverty from the last year of survey available. 
 For instance, if the period of reference is 2005-2009, last year available with data
 is 2012, and option {cmd: lastyear} is not specified,  {cmd:propov} will estimate poverty 
 for 2013 onwards based on 2012 data. Nonetheless, if lastyear(2010) is specified, 
 {cmd:propov} will project poverty from 2010 data onwards. 

{phang}
{opt pass:through(numlist max=1 >0 <=1)} factor of adjustment of GDP growth. For instance, 
if the GDP growth were 5% and the pass-through option is set at 0.8, the effective 
GDP growth would be 4%. Default value is 1. Take in account that the pass-through is applied 
to the GDP per capita growth for the Elasticity and the Neutral Distribution methods. If option
{cmd:{ul:cont}ribution(}{it:sum}{cmd:)} is specified (which is the default option), the pass-trough
will adjust {ul:only} the total GDP growth. That is, the population growth is NOT affected by
the pass-through. 

{phang}
{opt month:ly(exp)} Specifies the monthly factor for the poverty line. As the poverty line 
entered in option {opt pov:lines(string)} is the amount of dollars per day, the user can 
specify the average number of days per month a year. For instance, the user could specify 
that the 12 months of the year have 30 days, or 31 days, or 365/12 days. By default {cmd:propov}
assumes months of 30.42 days. 
 
{dlgtab:Graphs}

{phang}
{opt gr:aph(string)}} Displays analytic graphics. {it:den|gic|cont} 

{p 8 10 10} {it:den}: displays Kernel density of welfare distribution for base year and {cmd:first} 
year projected. {cmd:propov} displays welfare less than $16 USD PPP a day {p_end}

{p 8 10 10} {it:gic}: displays Growth Incidence Curve for base year and {cmd:first} year projected.  {p_end}

{p 8 10 10} {it:cont}: displays quantile contribution to  growth in the mean {p_end}
 
{dlgtab:Additional}

{phang}
{opt povdata(string)} Save dta file with poverty rates (real and projected)

{phang}
{opt welfaredata(string)} Save dta file with welfare aggregates and weights (real and projected)

{phang}
{opt macro:data(string)} Specifies the root where the macro data have been stored. For example, 
if the data is stored in the C:\mydata directory the path should be "C:\mydata\file_name.dta", 
 where 'file_name.dta'  must be in Stata format (dta) and contain the following variables in numeric and lowercase format: 
 
 
{center:{bf:country}{dup 5: }{bf:year}{dup 5: }{bf:pop }{dup 5: }{bf:gdp}{dup 5: }{bf:gdppc}}
{center:   ccc   {dup 3: }yyy1{dup 5: }ppp1{dup 5: }gdp1{dup 4: }gdppc1} 
{center:   ...   {dup 3: }... {dup 5: }... {dup 5: }...{dup 5: }...}
{center:   ccc   {dup 3: }yyyn{dup 5: }pppn{dup 5: }gdpn{dup 4: }gdppcn}

{p 4 6 2} where, 

{p 12 14 10}{bf:country} indicates the code of the country of each observation using the 
International Standards Organization (ISO) 3-digit alphabetic code. For example, arg 
for Argentina (ccc) 

{p 12 14 10}{bf:year} indicates the year of each observation from year 1 to year n (yyy[1...n])

{p 12 14 10}{bf:pop} population of the country of interest (ppp[1...n]) 

{p 12 14 10}{bf:gdp} GDP of the country of interest (gdp[1...n]) 

{p 12 14 10}{bf:gdp} GDP per capita of the country of interest (gdppc[1...n])
 
{phang}
{opt replace}  Specifies that it is okay to replace the data in memory, even though the current data have not been saved to disk. 

{phang}
{opt clear} Specifies that it is okay to clear the data in memory, even though the current data have not been saved to disk. 

{phang}
{opt annualized}  uses annualized growth for Elasticity method. Default is point-to-point growth

{phang}
{opt region(string)}  Specify the dataset source from which the data will be retrieved. 
By default {cmd:propov} loads data from the GPWG portal. For now, only the LAC region
is able to load micro-data from its own dataset. In further versions, other regions would 
be available to use their data as well. 
In case you want to request access to LAC Datalib, please send an email to 
{browse "lac_stats@worldbank.org":lac_stats@worldbank.org} providing the following 
information:

{p 10 10 10} 1. Brief description of each project that will utilize the LAC Datalib microdata. {p_end}
{p 10 10 10} 2. The staff that will be involved in each project, including TTLs.           {p_end}
{p 10 10 10} 3. The name and UPI of each member of the team who needs access to Datalib    {p_end}


{marker examples}{...}
{title:Examples}

{dlgtab:Basic}

{phang}
Projecting poverty for Panama from the last data set available using as period of 
reference is 2007-2010.

{phang} 
{stata propov, country(pan) period(2007 2010)}

{dlgtab:select last year}

{phang}
Although the last year available with data is 2012, you could project poverty for Argentina 
from 2011 using as period of reference is 2007-2010.

{phang} 
{stata propov, country(arg) period(2007 2010) lastyear(2011)}

{dlgtab:grphas, # of quantiles, and Poverty lines}

{phang}
Projecting poverty for Costa Rica from 2010 using as period of reference is 2011-2012 
with the international daily poverty lines of $1.25 $3 and $5. The program will use 50 
quantiles and will generate the graph with the Kernel density of welfare distribution.

{phang}
{stata propov, country(cri) period(2011 2012) graph(den) nq(50) povlines(1.25 3 5)}

{dlgtab:pass-through}

{phang}
Adjust GDP per capita growth by a factor of 0.6 for Honduras. 

{phang}
{stata propov, country(hnd) period(2007 2011) pass(0.6)}


{dlgtab:contribution and distribution}

{phang}
Project poverty using mean-income quantile contribution and democratic distribution
within quantiles for Argentina between 2008 and 2012.

{phang}
{stata propov, countr(arg) period(2008 2012) cont(mean) dist(democratic)}


{dlgtab:Macro Data}

{phang}
Project poverty for Argentina between 2008 and 2012 using a particular database of the 
macro data called My_GDP_Data and stored in a folder called Data.


{phang}
{stata propov, countr(arg) period(2008 2012) macrodata(C\Data\My_GDP_Data.dta)}


{title:Developer}

{p 4 4 4}R. Andres Castaneda, The World Bank{p_end}
{p 4 4 4}Email {browse "acastanedaa@worldbank.org":acastanedaa@worldbank.org}{p_end}


{title:Administrator}

{p 4 4 4}German Caruso, The World Bank{p_end}
{p 4 4 4}Email {browse "gcaruso@worldbank.org":gcaruso@worldbank.org}{p_end}


{title:Acknowledgments:}

{phang}
This program is the result of a joint work. Special thanks to Leonardo Lucchetti, 
German Caruso, Liliana D. Sousa, Minh Nguyen, Joao Pedro Azevedo, and Monica Yanez 
for their valuable suggestions. 

{phang}
{cmd:propov} Uses the following user-written Stata commands:

{p 8 12 8} 1.{cmd: renvars} developed by Jeroen Weesie and Nicholas J. Cox{p_end}
{p 8 12 8} 2.{cmd: quantiles} developed by Rafael Guerreiro Osorio{p_end}
{p 8 12 8} 3.{cmd: apoverty} developed by Joao Pedro Azevedo{p_end}
{p 8 12 8} 4.{cmd: datalib} developed by R.Andres Castaneda and Joao Pedro Azevedo {p_end}
{p 8 12 8} 5.{cmd: datalib2} developed by Joao Cesar A. Cancho, Andres Castaneda, and Joao Pedro Azevedo{p_end}
{p 8 12 8} 6.{cmd: scheme-burd} developed by François Briatte{p_end}

{title:Related commands:}

{help datalib2} to install this command {stata net install datalib2, from("\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\_ado"):clik here} 
