"""
Created on Mon May 25 15:28:53 2021 

@author: Ryan Hughes
@email: rh39658@uga.edu

"""

from stkhelper import toolbox, application, scenario
import os
import scheduler
import datetime

accessName = 'testAccess.csv'
scheduleName = 'testSchedule.csv'
elevationFileName = 'elevations.txt'
elevationIntervalFileName = 'testIntervals.csv'

cwd = os.getcwd()

#Opening access text file and reading lines into a variable

fileName = "access.txt"
openFile = open(fileName, "r")
lines = openFile.readlines()
openFile.close()

#Removing all data except target name, start time of interval, and end time of interval
cleanFile = []

for line in lines:
    splitLine = line.split(",")
    name = splitLine[1]
    startTime = splitLine[3]
    endTime = splitLine[4]
    newLine = [name, startTime, endTime]
    cleanFile.append(newLine)

cleanFile.pop(0) #Removing headers of columns

#Formatting as 'Start' 'End' 'Name'
access = []
for line in cleanFile:
    newLine = []
    lineOne = line[1].replace('-', ' ') + '.000'
    newLine.append(lineOne)
    lineTwo = line[2].replace('-', ' ') + '.000'
    newLine.append(lineTwo)
    newLine.append(line[0])
    
    access.append(newLine)

#Creating schedule from reformatted access file using Conors functions
access = toolbox.Toolbox.SortAllAccess(access)

accessFile = cwd + '\\Access_Files\\' + accessName
toolbox.Toolbox.AccessToCSV(access, accessFile)

scheduleArray = scheduler.generateSchedule(accessFile)

scheduleFile = open(cwd + '\\Schedule_Files\\' + scheduleName, 'w')
for i in range(len(scheduleArray)):          
    scheduleFile.write(scheduleArray[i][0] + "," + \
                       scheduleArray[i][1] + "," + \
                       scheduleArray[i][2] + "," + \
                       scheduleArray[i][3] + "\n")


#Gathering intervals to run elevation angles for
elevationIntervals = []
for i in range(len(scheduleArray)):
    if scheduleArray[i][3] == 'imaging':
        toAdd = []
        toAdd.append(scheduleArray[i][0])
        toAdd.append(scheduleArray[i][1])
        toAdd.append(scheduleArray[i][2])
        elevationIntervals.append(toAdd)

elevationIntervalFile = open(elevationIntervalFileName, 'w')

#Writing intervals to csv
for i in range(len(elevationIntervals)):
    elevationIntervalFile.write(elevationIntervals[i][0] + "," + \
                                elevationIntervals[i][1] + "," + \
                                elevationIntervals[i][2] + "\n")



    
































