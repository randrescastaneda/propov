/*===========================================================================
project:       update propov
Author:        Andres Castaneda 
Dependencies:  The World Bank
---------------------------------------------------------------------------
Creation Date:     March 24, 2015 
Modification Date: 
Do-file version:    01
References:          
Output:             
===========================================================================*/

/*=======================================================================================
                                  0: Program set up            
=======================================================================================*/

version 12
program define propov_update

syntax , [region(string)]

if ("`region'" == "") local propovdir "\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\_ado\propov"
if (lower("`region'") == "lac") local propovdir "S:\Datalib\_ado\propov"

qui {
	adoupdate propov_update, update
	discard
	noi disp in y _n "{cmd:propov} has been updated." _n 
	noi type "`propovdir'/propov_version.smcl"
}
end

exit 

