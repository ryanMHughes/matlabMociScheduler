import os
from stkhelper import toolbox
import scheduler
from main import scheduleArray


scheduleName = 'testSchedule.csv'
newScheduleName = 'elevationTestSchedule.csv'

cwd = os.getcwd()

openFile = open('elevations.txt')
lines = openFile.readlines()
openFile.close()
lines.pop(0)

openSolarFile = open('solarElevations.txt')
solarLines = openSolarFile.readlines()
openSolarFile.close()
solarLines.pop(0)

elevations = []
for line in lines:
    line = line.replace('\n', '')
    elevations.append(line)

solarElevations = []
for line in solarLines:
    line = line.replace('\n','')
    solarElevations.append(line)

scheduleFile = open(cwd + '\\Schedule_Files\\' + newScheduleName, 'w')

scheduleFile.write('Start' + ',' + \
                   'End' + ',' + \
                   'Target' + ',' + \
                   'Mode' + ',' + \
                   'Max MOCI Elevation' + ',' + \
                   'Max Solar Elevation' + '\n')


counter = 0
for i in range(len(scheduleArray)):
    elevation = 'N/A'
    solarElevation = 'N/A'
    if scheduleArray[i][3] == 'imaging':
        elevation = elevations[counter]
        solarElevation = solarElevations[counter]
        counter = counter + 1        
    scheduleFile.write(scheduleArray[i][0] + "," + \
                       scheduleArray[i][1] + "," + \
                       scheduleArray[i][2] + "," + \
                       scheduleArray[i][3] + "," + \
                       str(elevation) + "," + \
                       str(solarElevation) + "\n")


