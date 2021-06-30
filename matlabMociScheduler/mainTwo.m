% Author: Richard Hoepfinger, Ryan Hughes.
% Emails: richhoepfinger@gmail.com, rh39658@uga.edu
% FOR: UGA Small Satellite Research Lab.
% WORKS: Reads an excel file containing the locations of targets and a tle for a
% specified satellite. Makes a scheduler for when the satellite is above
% the UGA ground station and is avaliable for data downlink/uplink.
% FUTURE: Does the same for the rest of the targets on when it is able to
% take pictures and returns the angle of elevation of the sun for optimal
% picture taking. Returns a whole schedule for the satellite to follow
% provided it does not have an emergency.

tic

targets = 'target_list.csv';

% Reads the excel file
data = readcell(targets);

% Makes a new variable
latandlong = data;

% seperates the latitudes, longitudes, and names for each target
lat = cell2mat(latandlong(:,2)');
long = cell2mat(latandlong(:,3)');
names = cellstr(latandlong(:,1)');

% sets up the specified datetime range

startTime = datetime(2021,6,10,0,0,0);
stopTime = startTime + days(7);
sampleTime = 3; %seconds

% adds the specified datetime range to a new satelliteScenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% makes the UGA groundstation for data uplink and downlink from MOCI
minElevationAngle = 25;
name = 'Ground_Station';
UGA = groundStation(sc, lat(84), long(84), ...
    'Name', name, "MinElevationAngle", minElevationAngle);

lat(84) = [];
long(84) = [];
names(84) = [];

gsList = [UGA];

% Parses through the targets giving each of them a name and
% location, adds them all to a new groundstations row vecor
for i = 1:length(lat)
    name = names(i);
    gs = groundStation(sc,lat(i),long(i), ...
        'Name', name);
    gsList = [gsList, gs];
end

% adding moci satellite into simulation using 97 inclination and 500 km
% circular orbit
%semiMajorAxis = 6878000;
%eccentricity = 0;
%inclination = 97;
%rightAscentionOfAscendingNode = 0;
%argumentOfPeriapsis = 0;
%trueAnomaly = 0;

%moci = satellite(sc,semiMajorAxis,eccentricity,inclination, ... 
%    rightAscentionOfAscendingNode, argumentOfPeriapsis, trueAnomaly, ...
%    "Name", "MOCI"); 
moci = satellite(sc, 'TLE.txt', "Name", "MOCI");

% adds a new camera to the stellite with a field of view of 4.8 degrees
camName = moci.Name + " Camera";
cam = conicalSensor(moci, "Name" , camName, "MaxViewAngle", 4.8, ...
    "MountingAngles", [0; 0; 0]);

UGAaccess = access(moci, UGA);
acs = [UGAaccess];

% Creating table of access intervals (targets and GS) and writing to a text file
% To get the correct intervals, this should be between the camera and the
% list of ground stations, however due to the small FOV of the camera I get
% no access intervals when computing between the camera and the GS list over
% one day, which aleady takes about 15 min and I am not willing to wait
% hours to get a access file while problem shooting. Just computed LOS
% access between MOCI and GS list to have sample text file for scheduler. 

for i = 1:86 
     event = access(cam, gsList(i));
     acs = [acs, event];
end

intvls = accessIntervals(acs);
intervals = intvls;

% Formatting table in order to write to text file of raw data 

T1 = array2table(intervals)

T2 = splitvars(T1)

writetable(T2, 'access.txt');

% Visualizing the scenario and making the MOCI Cameras FOV visible

% v = satelliteScenarioViewer(sc);
% fov = fieldOfView(cam([cam.Name] == "MOCI Camera"));

toc
