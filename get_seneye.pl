#!/usr/bin/perl -w
#
# Check_MK Local Check for Seneye Reef Devices
#
#        Written by:	Darren Gibbard
#        Website:	dgunix.com
#        Date Edited:	16/04/2013
#
#  Feel free to edit as you please :) My perl isn't great
#  at the time of writing! All i ask is that you please visit
#  www.dgunix.com and provide feedback!
#
#  *** NOTE: Please change the "USER SPECIFIED VARIABLES" to suit your needs.
#            SEE BELOW :)
#
# Future Plans:
# -------------
#   * Add in detection of whether ambient LUX levels have been acceptable
#       within a given time limit. Should help to watch for failed lights.
#
# Changelog:
# ----------
#   * v0.1 - Created script.
#   * v0.2 - Added lux level + lighting detection.
#
# How to use:
# -----------
# I assume you already have a Check_MK or OMD monitoring instance...
#                       ----   omdistro.org  ----
# Once you have that, and have added a host, place this script onto
# the monitored host, into /usr/lib/check_mk/local/ (name it whatever
# you like) - make sure it's executable, and then reinventorise the host
# in CheckMK :
# 
#  ## SSH on to the CMK server
#  $ sudo su - <omduser>
#  $ cmk -I host-with-script.com
#  $ cmk -O
#
# Done!

#########
# INITIAL DEFINITIONS
#########
use warnings;
use strict;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use POSIX;

############################
# USER SPECIFIED VARIABLES #
############################
#\/\/\/\/\/\/\/\/\/\/\/\/\/#

# Your email + pass used to access seneye.com
my $user = 'youremail@here.com';
my $pass = 'passwordhere';
# UnitID = Device ID in Seneye Connect Application.
my $unitid = '1234';

# Temporary Storage - location where we can freely store info. Somewhere
# *more permanent* than "/tmp" (Linux) | "C:\Windows\Temp" (Windows) is
# recommended for information storage across reboots.
## By the way - Use forward slashes instead of back slashes for Windows.
my $storedir = '/tmp';
my $storefile = 'seneye.tmp';

# Set mins and max values
## Min and Max pH Values to alert at.
my $ph_min = "7.9" ;
my $ph_max = "8.4";
## Maximum Ammonia Value to alert at.
my $nh3_max = "0.01";
## Min and Max Temperature to alert at.
my $temp_min = "24.8";
my $temp_max = "26.2";
# Ambient Lux Level to expect.
# Check on seneye.me to see what sort of ambient readings you
# get normally, and then set this slightly *lower*.
my $min_lux = "3.0";

### Differential Time Periods
# HOURS remaining till Seneye Slide expiry to alert at.
my $slide_expiry_differential = "72";

# HOURS to monitor for lights on- ie. Should come on once within X hours.
## Be leniant to avoid false warnings! eg. If there's 14 hours between
## cycles, set this to 15hrs min. Allows for clock changes/gaps in API access etc.
my $lights_on_diff = "24";

# HOURS since last Seneye Reading.
# ie. Complain loudly if we haven't had an updated reading
# from the Seneye device in X hrs.
my $last_read_diff = "3";

#/\/\/\/\/\/\/\/\/\/\/\/\/#
###########################
# END USER VARIABLES      #
###########################
##########
## START CODE
##########
# Define our file handle for later, else i'll forget.
my $MYFILE;
### Get full result including unit state, and latest readings.
# Set the API URL using user variables from above.
my $url = 'https://api.seneye.com/v1/devices/' . "$unitid" . '?IncludeState=1&user=' . "$user" . '&pwd=' . "$pass";
# Set User Agent
my $browser = LWP::UserAgent->new;
## Do Get request with XML Headers
# Time at the start
my $start_run = time();
# Do the API call
my $res = $browser->get( $url, 'Accept' => 'application/xml', );
# Time at the end
my $end_run = time();
# Work out time it took to complete the call.
my $get_complete_time = $end_run - $start_run;

###### DEBUG OPTION: Enable for RAW print of API Result
#print $response->as_string( );

## Error checking on API Call result
# If succesful, API is OK, and run Analysis on other items
if ($res->is_success) {
	my $get_complete_time_rnd = floor($get_complete_time);
	print "0 Seneye_API_Conn time=$get_complete_time;;;0; OK - The last Seneye API Call was Completed in $get_complete_time_rnd seconds.\n";

	# Pull just the content from the Returned XML from the Get - Scraps the returned headers and status codes etc.
	my $xml = $res->content;

	# Parse the remaining XML to produce Perl Array/Variable stuff
	my $data = XMLin($xml);

	###### DEBUG OPTION: Enable dumping of the Parsed XML
	#print Dumper( $data );

	# Set pH Value from Array
	my $ph_value = $data->{exps}->{ph}->{curr};
	# Set NH3 Value from Array
	my $nh3_value = $data->{exps}->{nh3}->{curr};
	# Set Temp Value from Array
	my $temp_value = $data->{exps}->{temperature}->{curr};
	# Set light level (LUX) from Array
	my $lux_level = $data->{exps}->{lux}->{curr};
	# Set Last Reading Value from Array
	my $last_read_value = $data->{status}->{last_experiment};
	# Set Out of Water Value from Array
	my $out_of_water_value = $data->{status}->{out_of_water};
	# Set Slide Expiry from Array
	my $slide_expiry_value = $data->{status}->{slide_expires};

	###### DEBUG OPTION: Output individual Check Values
	#print "pH: $ph_value\nNH3: $nh3_value\nTemp: $temp_value\nLUX Level: $lux_level\nLast Reading: $last_experiment_value\nOut of Water: $out_of_water_value\nSlide Expiry: $slide_expiry_value\n";

	### pH Analysis
	# If the last reading is greater than allowed maximum - Critical
	if ( $ph_value > $ph_max ){
		print "2 Seneye_pH ph=$ph_value;$ph_min;$ph_max;0; CRITICAL - pH at $ph_value - too high\n";
	# If last read is less than allowed minimum - Critical
	} elsif ( $ph_value < $ph_min ){
		print "2 Seneye_pH ph=$ph_value;$ph_min;$ph_max;0; CRITICAL - pH at $ph_value - too low\n";
	# Otherwise, all is good.
	} else {
		print "0 Seneye_pH ph=$ph_value;$ph_min;$ph_max;0; OK - pH at $ph_value\n";
	}

	### NH3 Analysis
	# If the last reading is larger than allowed maximum - Critical
	if ( $nh3_value > $nh3_max ){
		print "2 Seneye_NH3 nh3=$nh3_value;;$nh3_max;0; CRITICAL - NH3 Ammonia at $nh3_value - too high\n";
	# Otherwise, all good.
	} else {
		print "0 Seneye_NH3 nh3=$nh3_value;;$nh3_max;0; OK - NH3 Ammonia at $nh3_value\n";
	}
	
	### Temperature Analysis
	# If the last reading is greater than the allowed maximum - Critical
	if ( $temp_value > $temp_max ){
		print "2 Seneye_Temp temp=$temp_value;$temp_min;$temp_max;0; CRITICAL - Temperature at $temp_value.C - too high\n";
	# If last read is less than allowed minimum - Critical
	} elsif ( $temp_value < $temp_min ){
		print "2 Seneye_Temp temp=$temp_value;$temp_min;$temp_max;0; CRITICAL - Temperature at $temp_value.C - too low\n";
	# Otherwise, all good
	} else {
		print "0 Seneye_Temp temp=$temp_value;$temp_min;$temp_max;0; OK - Temperature at $temp_value.C\n";
	}

	### Light Level Analysis
	# Ensure directory we want to write in exists.
	if ( -d $storedir or mkdir $storedir ){
		# If light level is greater than or equal to expected, then display OK - lights on, and record date to file
		if ( $lux_level >= $min_lux ){
			# Open file, within an if to trap errors easily
			if ( open MYFILE, ">", $storedir . "/" . $storefile){
				# Print the current EPOCH time into file.
				print MYFILE time() . "\n";
				print "0 Seneye_Light_Level lux=$lux_level;$min_lux;0;0; OK - LIGHTS ON - LUX at $lux_level. Min_Thres = $min_lux\n";
				# Close filehandle
				close (MYFILE);
			# Else, we failed to open file handle - Unknown
			} else {
				print "3 Seneye_Light_Level lux=$lux_level;$min_lux;0;0; UNKNOWN - Failed to write to file $storedir/$storefile\n";
			}		
		# If light level is not greater than or equal to expected...
		# Check if our storage directory/file exist
		} elsif ( -s $storedir . "/" . $storefile ){
			# If the lux is low, and a datefile exists; read in the datefile.
			# Open filehandle
			if ( open MYFILE, "<", $storedir . "/" . $storefile){
				# Set oldread value from firstline of file (date)
				my $oldread = <MYFILE>;
				# Close filehandle
				close (MYFILE);
				# Calc difference between now and last on time from file.
				my $lux_difference = time() - $oldread;
				# Provide a human readable number for output
				my $lux_diff_human = floor($lux_difference / 60 / 60);
				# Take user var for allowed diff, and convert to EPOCH / seconds.
				my $lights_on_diff_epoch = $lights_on_diff * 60 * 60;
				# If our allowed time diff is larger than the actual, then all is OK.
				if ( $lights_on_diff_epoch > $lux_difference){
					print "0 Seneye_Light_Level lux=$lux_level;$min_lux;0;0; OK - LIGHTS OFF\n";
				# If the actual time difference exceeds our threshold - CRITICAL
				} else {
					print "0 Seneye_Light_Level lux=$lux_level;$min_lux;0;0; CRITIAL - Lights on not detected for $lux_diff_human Hours\n";
				}
			# From above- here's what to do if we fail to read file for reason other than it not existing/zero etc.
			} else {
				print "3 Seneye_Light_Level lux=$lux_level;$min_lux;0;0; UNKNOWN - Failed to read file $storedir/$storefile\n";
			}
		} else {
		# If file doesn't exist or is empty, return Unknown.
			print "3 Seneye_Light_Level - UNKNOWN - Date file $storedir/$storefile not yet created. Waiting for next lights on\n";
		}	
	# And if we can't make the directory the user requested...
	} else {
		print "3 Seneye_Light_Level - UNKNOWN - Failed to create directory $storedir\n";
	}


	### Last Reading Analysist
	# If last reading value + differential (2hrs) < current date = ERROR
	my $last_read_diff_epoch = $last_read_diff * 60 * 60;
	my $last_read_diff_mins = $last_read_diff * 60;
	my $last_time = time() - $last_read_value;
	my $last_time_mins = $last_time / 60;
	my $last_time_rnd = ceil($last_time_mins);
	if ( $last_time > $last_read_diff_epoch ){
		print "2 Seneye_Last_Reading mins=$last_time_rnd;;$last_read_diff_mins;0; CRITICAL - Last Seneye Reading Received $last_time_rnd minutes ago\n";
	# Else OK
	} else {
		print "0 Seneye_Last_Reading mins=$last_time_rnd;;$last_read_diff_mins;0; OK - Last Seneye Reading $last_time_rnd Minutes ago\n";
	# End
	}

	### Out of Water Analysis
	if ( $out_of_water_value == 1 ){
		print "2 Seneye_In_Water water=0;;0;0; CRITICAL - Seneye unit is out of the water\n";
	} else {
		print "0 Seneye_In_Water water=1;;0;0; OK - Seneye unit is in the water\n";
	}
	
	### Slide Expiry Analysis
	# Calculate diff in EPOCH
	my $slide_diff_epoch = $slide_expiry_differential * 60 * 60;
	my $slide_diff_hours = $slide_expiry_differential * 60;
	my $remaining_time = $slide_expiry_value - time();
	# Convert remaining time to hours:
	my $remaining_hours = $remaining_time / 60 / 60;
	# If expiry date + differential (72hrs) > current date = WARN SLIDE DUE FOR REPLACEMENT
	if ( $remaining_time < $slide_diff_epoch ){
		print "1 Seneye_Slide_Expiry time=$remaining_hours;$slide_diff_hours;;0; WARNING - Seneye Slide due to expire in $remaining_hours\n";
	# Else OK
	} else {
		my $remaining_days_raw = $remaining_hours / 24;
		my $remaining_days = ceil($remaining_days_raw);
		print "0 Seneye_Slide_Expiry hours_remaining=$remaining_hours;$slide_diff_hours;;0; OK - Seneye Slide expiry in $remaining_days day(s)\n";
	# End
	}

### End analysis
# If API Call failed
} else {
	print "2 Seneye_API_Conn - CRITICAL - The last Seneye API Call Failed.\n";
	
	# For each service (manually defined :( ) Return an UNKNOWN
	my @servicenames = ("Seneye_pH","Seneye_NH3","Seneye_Temp","Seneye_Light_Level","Seneye_Last_Reading","Seneye_In_Water","Seneye_Slide_Expiry");
	foreach my $service (@servicenames){
		print "3 $service - UNKNOWN - Unable to get value due to API Fault.\n";
	}
	die;


# End everything in the world, ever.
}

