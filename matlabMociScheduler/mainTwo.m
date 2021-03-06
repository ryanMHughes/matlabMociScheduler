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
timezone = 'UTC';
startTime = datetime(2021,6,10,0,0,0, ...
    'TimeZone', timezone);
stopTime = startTime + hours(6);
sampleTime = 10; %seconds

% adds the specified datetime range to a new satelliteScenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% makes the UGA groundstation for data uplink and downlink from MOCI
minElevationAngle = 25;
name = 'Ground_Station';
gs = groundStation(sc, lat(84), long(84), ...
    'Name', name, ...
    'minElevationAngle', minElevationAngle);
lat(84) = [];
long(84) = [];
names(84) = [];

gsList = [gs];

% Parses through the ground stations giving each of them a name and
% location, adds them all to a new groundstations row vecor
for i = 1:length(lat)
    name = names(i);
    gs = groundStation(sc,lat(i),long(i), ...
        'Name', name);
    gsList = [gsList, gs];
end

% adding moci satellite into simulation using 97 inclination and 500 km
% circular orbit

moci = satellite(sc, 'TLE.txt', "Name", "MOCI");

% adds a new camera to the stellite with a field of view of 4.8 degrees
camName = moci.Name + " Camera";
cam = conicalSensor(moci, "Name" , camName, "MaxViewAngle", 4.8, ...
    "MountingAngles", [0; 0; 0]);
    
% Creating table of access intervals (targets and GS) and writing to a text file
% To get the correct intervals, this should be between the camera and the
% list of ground stations, however due to the small FOV of the camera I get
% no access intervals when computing between the camera and the GS list over
% one day, which aleady takes about 15 min and I am not willing to wait
% hours to get a access file while problem shooting. Just computed LOS
% access between MOCI and GS list to have sample text file for scheduler. 
acs = [];

for i = 1:86 
    event = access(moci, gsList(i));
    acs = [acs, event];
end

acs = [acs,access(gsList(1), moci)];

T2 = accessIntervals(acs);

% sorts the table by the start time of each interval
sortedArray = sortrows(T2,4);

% gets rid of the last row if it is at the stop time
if sortedArray{height(sortedArray),5} + minutes(30) >= stopTime
    sortedArray(height(sortedArray),:) = [];
end

% gets rid of any times that conflict, while prioritizing data downlink
i = 2;
while i <= height(sortedArray)
    tupper = sortedArray{i - 1,5} + minutes(30);
    tlower = sortedArray{i - 1,4};
    t = sortedArray{i,4};
    tf = isbetween(t,tlower,tupper);
    if tf == 1 && sortedArray{i,1} ~= "Ground_Station"
        sortedArray(i,:) = [];
        i = i - 1;
    elseif tf == 1
        sortedArray(i - 1,:) = [];
        i = i - 1;
    end
    i = i + 1;
end

% sorts the table by the start time of each interval
sortedArray = sortrows(sortedArray,4);

i = 1;
while i <= height(sortedArray)
    if sortedArray{i,1} == "MOCI" && sortedArray{i,6} ~= 1800
        newRow = sortedArray(i,:);
        newRow{1,1} = "Data Processing";
        newRow{1,2} = "Data Processing";
        newRow{1,4} = sortedArray{i,5};
        newRow{1,5} = sortedArray{i,5} + minutes(30);
        newRow{1,6} = 1800;
        sortedArray = [sortedArray; newRow];
    end
    i = i + 1;
end

% sorts the table by the start time of each interval
sortedArray = sortrows(sortedArray,4);

if sortedArray{1,4} > startTime
    newRow = sortedArray(1,:);
    newRow{1,1} = "Cruise";
    newRow{1,2} = "Cruise";
    newRow{1,4} = startTime;
    newRow{1,5} = sortedArray{1,4};
    newRow{1,6} = seconds(newRow{1,5} - newRow{1,4});
    sortedArray = [sortedArray; newRow];
end

i = 1;
while i <= height(sortedArray)
    if sortedArray{i,1} ~= "Cruise" && sortedArray{i+1,1} ~= "Cruise" && ... 
        sortedArray{i,1} ~= "MOCI"
        newRow = sortedArray(i,:);
        newRow{1,1} = "Cruise";
        newRow{1,2} = "Cruise";
        newRow{1,4} = sortedArray{i,5};
        newRow{1,5} = sortedArray{i+1,4};
        newRow{1,6} = seconds(newRow{1,5} - newRow{1,4});
        sortedArray = [sortedArray; newRow];      
        
    end
    i = i + 1;
end

% sorts the table by the start time of each interval
sortedArray = sortrows(sortedArray,4);

if sortedArray{height(sortedArray),5} < stopTime
    newRow = sortedArray(height(sortedArray),:);
    newRow{1,1} = "Cruise";
    newRow{1,2} = "Cruise";
    newRow{1,4} = sortedArray{height(sortedArray),5};
    newRow{1,5} = stopTime;
    newRow{1,6} = seconds(newRow{1,5} - newRow{1,4});
    sortedArray = [sortedArray; newRow];
end
 

% Visualizing the scenario and making the MOCI Cameras FOV visible

%v = satelliteScenarioViewer(sc);
%fov = fieldOfView(cam([cam.Name] == "MOCI Camera"));

toc

    
