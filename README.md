seneye_mon
==========

Python code for Monitoring the statistics from a Seneye (www.seneye.com) Aquarium Unit via the Seneye API.

The plan is to have code for:

Initial/Legacy:
* Providing alerting to an OMD/Check_MK Instance written in Perl
 
Moving Forward:
* Providing a joint codebase for alerting to an OMD/Check_MK OR Nagios Instance (without Passive results!) written in Python



API Example Output:
===================
This is some output from the API, for my tank called "Roma 125" - I've formatted this for easier reading, but the real output has no spacing/returns/indentations!

```
<?xml version="1.0"?>
<response>
    <id>4487</id>
    <description>Roma 125</description>
    <type>3</type>
    <time_diff>0</time_diff>
    <status>
        <disconnected>0</disconnected>
        <slide_serial>j82su790hs6</slide_serial>
        <slide_expires>1381379977</slide_expires>
        <out_of_water>0</out_of_water>
        <wrong_slide>0</wrong_slide>
        <last_experiment>1387363740</last_experiment>
    </status>
    <exps>
        <temperature>
            <trend>0</trend>
            <critical_in>-1</critical_in>
            <avg>25.4</avg>
            <status>0</status>
            <curr>25.2</curr>
            <advises/>
        </temperature>
        <ph>
            <trend>0</trend>
            <critical_in>-1</critical_in>
            <avg>7.96</avg>
            <status>0</status>
            <curr>8.08</curr>
            <advises/>
        </ph>
        <nh3>
            <trend>0</trend>
            <critical_in>-1</critical_in>
            <avg>0.001</avg>
            <status>0</status>
            <curr>0.001</curr>
            <advises/>
        </nh3>
        <nh4>
            <trend>1</trend>
            <critical_in>-1</critical_in>
            <avg>21.28</avg>
            <status>0</status>
            <curr>15.52</curr>
            <advises/>
        </nh4>
        <o2>
            <trend>0</trend>
            <critical_in>-1</critical_in>
            <avg>8.1</avg>
            <status>0</status>
            <curr>8.2</curr>
            <advises/>
        </o2>
        <lux>
            <status/>
            <curr>0</curr>
            <advises/>
        </lux>
        <par>
            <curr>0</curr>
            <advises/>
        </par>
        <kelvin>
            <curr>0</curr>
            <advises/>
        </kelvin>
    </exps>
</response>
```


Script Example Output:
======================
```
$ ./get_seneye.pl 
0 Seneye_API_Conn time=5;;;0; OK - The last Seneye API Call was Completed in 5 seconds.
0 Seneye_pH ph=8.08;7.9;8.4;0; OK - pH at 8.08
0 Seneye_NH3 nh3=0.001;;0.01;0; OK - NH3 Ammonia at 0.001
0 Seneye_Temp temp=25.2;24.8;26.2;0; OK - Temperature at 25.2.C
0 Seneye_Light_Level lux=0;3.0;0;0; OK - LIGHTS OFF
0 Seneye_Last_Reading mins=38;;180;0; OK - Last Seneye Reading 38 Minutes ago
0 Seneye_In_Water water=1;;0;0; OK - Seneye unit is in the water
1 Seneye_Slide_Expiry time=-1662.78416666667;4320;;0; WARNING - Seneye Slide due to expire in -1662.78416666667
```
