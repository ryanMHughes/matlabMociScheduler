
% Reading in target list data to variable

targets = 'target_list.csv';
data = readcell(targets);
latandlong = data;

% Extracting latitude, longitude, and name of each ground target
lat = cell2mat(latandlong(:,2)');
long = cell2mat(latandlong(:,3)');
names = cellstr(latandlong(:,1)');

% Simulation parameters

startTime = datetime(2021,6,10,0,0,0);
stopTime = startTime + days(30);
sampleTime = 1; %seconds, aka timestep/data rate

% Creating scenario with parameters previously defined
sc = satelliteScenario(startTime,stopTime,sampleTime);

% Creating UGA Groundstation and defining minimum elevation angle to
% reflect hardware limitations of dish.
minElevationAngle = 25;
name = 'Ground_Station';
gs = groundStation(sc, lat(84), long(84), ...
    'Name', name, ...
    'minElevationAngle', minElevationAngle);
lat(84) = [];
long(84) = [];
names(84) = [];

gsList = [gs];
UGA = gs;

% Creating ground targets within simulation, using coordinates and 
% names from MOCI Target List. 
for i = 1:length(lat)
    name = names(i);
    gs = groundStation(sc,lat(i),long(i), ...
        'Name', name);
    gsList = [gsList, gs];
end

% Defining orbital parameters for MOCI orbit and placing satellite on orbit
semiMajorAxis = 6878000;
eccentricity = 0;
inclination = 97;
rightAscentionOfAscendingNode = 0;
argumentOfPeriapsis = 0;
trueAnomaly = 0;

moci = satellite(sc,semiMajorAxis,eccentricity,inclination, ... 
    rightAscentionOfAscendingNode, argumentOfPeriapsis, trueAnomaly, ...
    "Name", "MOCI"); 

% Creating moci camera wth FFOV of 4.8 degrees (HFOV +- 2.4 deg)
camName = moci.Name + " Camera";
cam = conicalSensor(moci, "Name" , camName, "MaxViewAngle", 4.8, ...
    "MountingAngles", [0; 0; 0]);

% Creating cell array where intervals are represented with datetime obects
% and paired with respective target. 

T = readtable('testIntervals.csv');

intervals = [];

for i = 1:height(T)
    
    splitOne = strsplit(string(T.(4)(i)),',');
    splitTwo = strsplit(string(T.(7)(i)),',');
    
    dayOne = string(T.(1)(i));
    monthOne = string(T.(2)(i));
    yearOne = string(T.(3)(i));
    timeOne = splitOne(1);
    
    dateOne = [dayOne, monthOne, yearOne];
    dateOneFinal = strjoin(dateOne, '-') + ' ' + timeOne;
    
    dayTwo = splitOne(2);
    monthTwo = string(T.(5)(i));
    yearTwo = string(T.(6)(i));
    timeTwo = splitTwo(1);
    
    dateTwo = [dayTwo, monthTwo, yearTwo];
    dateTwoFinal = strjoin(dateTwo, '-') + ' ' + timeTwo;
    
    dateTimeOne = datetime(dateOneFinal, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss.SSS');
    dateTimeTwo = datetime(dateTwoFinal, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss.SSS');
    
    toAdd{1} = dateTimeOne;
    toAdd{2} = dateTimeTwo;
    toAdd{3} = splitTwo(2);
    
    intervals = [intervals; toAdd];
end

%Computing max elevations during each imaging inteval

elevations = [];
solarElevations = [];

for i = 1:length(intervals)
    nameOfTarget = intervals{i,3};
    for j = 1:length(lat)
         if gsList(j).Name == nameOfTarget
            target = gsList(j);
         end
    end
    startTime = intervals{i,1}; %start of imaging interval
    
    timeOne = intervals{i,1};
    timeTwo = intervals{i,2};
    
    maxEl = 0;
    while timeOne < timeTwo
        [az, elev, r] = aer(target, moci, timeOne);
        if elev > maxEl
            maxEl = elev;
        end
        timeOne = timeOne + seconds(1);
    end
    elevations = [elevations; maxEl];
    
    timeOne = intervals{i,1};
    maxSolarElev = 0;
    
    while timeOne < timeTwo
        [az, elev] = SolarAzEl(timeOne, target.Latitude, ... 
            target.Longitude, target.Altitude);
        if elev > maxSolarElev
            maxSolarElev = elev;
        end
        timeOne = timeOne + seconds(1);
    end
    solarElevations = [solarElevations; maxSolarElev];
end
    
%Writing maximum elevations to a text file, to be fed into python
%scheduling script. 

T = array2table(elevations);

writetable(T, 'elevations.txt');

T2 = array2table(solarElevations);

writetable(T2, 'solarElevations.txt');





