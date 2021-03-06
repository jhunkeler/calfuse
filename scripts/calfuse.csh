#!/usr/bin/env tcsh -f
#******************************************************************************
#*              Johns Hopkins University 
#*              Center For Astrophysical Sciences
#*              FUSE
#******************************************************************************
#*
#* Synopsis:    calfuse.csh file_name 
#*
#* Description: Shell script for processing FUSE Ver 3.0 time-tagged exposures.
#*		All messages are written to stdout or stderr.
#*
#* Arguments:   char    file_name	File name to process is 1st command-
#*                                      line argument
#*
#* Returns:     Exit codes:
#*			0		Successful execution
#*			
#*
#* Environment variables:  CF_CALDIR    Path to directory which contains the
#*                                      calibration files.
#*                         CF_IDLDIR    Path to CalFUSE IDL directory
#*                         CF_PIPELINE  Flag to determine if CALFUSE
#*                                      is running as part of the JHU 
#*                                      pipeline.
#*
#* History:     02/26/03   1.1   peb    Begin work on V3.0
#*		03/19/03   1.2   wvd	Add IDL plots
#*              03/31/03   1.3   peb    Add cf_ttag_countmap/gainmap programs
#*                                      and changed the timestamp format to be
#*                                      similar to cf_timestamp
#*		05/16/03   1.4   wvd	Distinguish between TTAG and HIST files.
#*					Changed name to calfuse.csh
#*		05/22/03   1.5   wvd	Direct STDERR to trailer file.
#*              06/03/03   1.6   rdr    Incorporated bad pixel map
#*              06/09/03   1.7   rdr    Do not screen on timing flags for HIST
#*                                      data processed behind the firewall
#*		07/31/03   1.8   wvd	Check error status before exiting.
#*		09/15/03   1.9   wvd	Write BEGIN and END stmts to logfile.
#*		12/08/03   1.10  wvd	For HIST data, always call
#*					cf_extract_spectra and cf_bad_pixels
#*					with -s option.
#*		12/21/03   1.13  wvd	Remove underscore from idf and bpm
#*					filenames.
#*		04/22/04   1.12  wvd	Change name of trailer file to
#*					{$froot}.trl
#*		05/12/04   1.13  wvd	Remove cf_ttag_countmap and
#*					cf_ttag_gainmap from pipeline.
#*		06/01/04   1.14  wvd	For HIST data, no longer need to call
#*					cf_extract_spectra with -s option.
#*		06/03/04   1.15  wvd	Screening step now follows "Convert
#*					to FARF."
#*
#*****************************************************************************/

# Delete files after processing?  (Default is no.)
#set DELETE_IDF  		# Delete intermediate data file
#set DELETE_BPM			# Delete bad-pixel map

set idf     = ${1:s/raw/idf/}
set froot   = ${1:s/raw.fit//}
set logfile = {$froot}.trl
set ttag    = `echo $froot | grep -c ttag` 

# Put a timestamp in the log file (the OPUS trailer file).
if $ttag then
    echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Begin TTAG file $1"
    echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Begin TTAG file $1" >>& $logfile
else
    echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Begin HIST file $1"
    echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Begin HIST file $1" >>& $logfile
endif

set cfstat=0

# Step 1  --  Generate Intermediate Data File
if $ttag then
    cf_ttag_init            $1    $idf    >>& $logfile
    set cfstat=$status
else
    cf_hist_init            $1    $idf    >>& $logfile
    set cfstat=$status
endif

# Step 2  --  Convert to FARF
if ! $cfstat then
    cf_convert_to_farf        $idf    >>& $logfile
    set cfstat=$status
endif

# Step 3  --  Screen photons
if ! $cfstat then
    cf_screen_photons         $idf    >>& $logfile
    set cfstat=$status
endif

# Step 4  --  Remove motions
if ! $cfstat then
    cf_remove_motions         $idf    >>& $logfile
    set cfstat=$status
endif

if ! $cfstat then
	if ($?CF_IDLDIR) then
		idlplot_rate.pl {$froot}	>>& $logfile
                idlplot_spex.pl {$froot}        >>& $logfile
	endif
endif

# Step 5  --  Assign wavelength
if ! $cfstat then
    cf_assign_wavelength      $idf    >>& $logfile
    set cfstat=$status
endif

# Step 6  --  Flux calibrate
if ! $cfstat then
    cf_flux_calibrate         $idf    >>& $logfile
    set cfstat=$status
endif

# Step 7 -- Create a bad-pixel file
if ! $cfstat then
    cf_bad_pixels        $idf    >>& $logfile
    set cfstat=$status
endif

# Step 8  --  Extract spectra
if ! $cfstat then
    cf_extract_spectra        $idf    >>& $logfile
    set cfstat=$status  
endif

# Step 8a --  Delete _bursts.dat file
if ! $?CF_PIPELINE then
    rm -f ${1:r:s/ttagfraw/_bursts/}.dat
endif

# Step 8b --  Delete IDF file
if $?DELETE_IDF then
    echo "NOTE: Deleting intermediate data file."
    rm $idf
endif

# Step 8c --  Delete bad pixel map (bpm) file
if $?DELETE_BPM then
    echo "NOTE: Deleting bad pixel map (bpm) file."
    rm -f ${1:s/raw/bpm/}
endif

if ! $cfstat then
 if $ttag then
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: End   TTAG file $1"
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: End   TTAG file $1" >>& $logfile
 else
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: End   HIST file $1"
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: End   HIST file $1" >>& $logfile
 endif
else
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Error processing $1"
  echo `date '+%Y %b %e %T'` "calfuse.csh-1.15: Error processing $1" >>& $logfile
endif
exit($cfstat)

#******************************************************************************
