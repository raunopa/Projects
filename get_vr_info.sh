#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse
from difflib import get_close_matches
from urllib import request
from datetime import datetime
from dateutil import tz
import json


def searchFromListOfDicts(listOfDict, key, value):
    """
    Loop list of dicts and search dictionary which contains a supposed key-value pair
    Return the dctionary which includes the searched values
    list: list of dicts
    key: list of find key(s)
    value: list of assumed value(s)
    """
    for p in listOfDict:
        if [p[i] for i in key] == value:
                return p


def searchLatestStation(trainInfo, keyName):
    """
    Loop list of dicts and search dictionary which contains keyName value(s).
    Return the value before the value found
    list: list of dicts
    keyName: list of find key(s)
    """
    latestStation = None
    for idx, p in enumerate(trainInfo,1):
        if p.get('liveEstimateTime') != None and p.get('estimateSource') == 'COMBOCALC':
            latestStation = trainInfo[idx-2]
            break
    if latestStation == None:
        latestStation = trainInfo[-1]
    return latestStation


def getBasicInfo(trainInfo, keys):
    return {k: v for d in [{x:trainInfo.get(x)} for x in keys] for k, v in d.items()}


def getTimeInCurrentZone(timeString):
    fromZone = tz.gettz('UTC')
    toZone = tz.gettz()
    time = datetime.strptime(timeString, '%Y-%m-%dT%H:%M:%S.%fZ').replace(tzinfo=fromZone).astimezone(toZone).strftime('%Y-%m-%d %H:%M:%S')
    return time


def getInfoMessage(current_ts, trainBasicInfo, latestStation, latestStationInfo, targetStationInfo, targetStationMetaData):
    estimatedTime = targetStationInfo.get("liveEstimateTime")

    if estimatedTime != None:
        message =  {"updatedTime": current_ts.strftime('%Y-%m-%d %H:%M:%S'),
                    "trainType": trainBasicInfo['trainType'],
                    "trainNumber": trainBasicInfo['trainNumber'],
                    "latestStation": latestStationInfo['stationName'],
                    "actualDifferenceInMinutes": latestStation['differenceInMinutes'],
                    "targetStation": targetStationMetaData['stationName'],
                    "estimatedArrivalTime": getTimeInCurrentZone(targetStationInfo['liveEstimateTime']),
                    "estimatedDifferenceInMinutes": targetStationInfo['differenceInMinutes']}
    else:
        message = {"updatedTime": current_ts.strftime('%Y-%m-%d %H:%M:%S'),
                   "trainType": trainBasicInfo['trainType'],
                   "trainNumber": trainBasicInfo['trainNumber'],
                   "latestStation": latestStationInfo['stationName'],
                   "targetStation": targetStationMetaData['stationName'],
                   "targetStationArrivalTime": getTimeInCurrentZone(targetStationInfo['actualTime'])}
    return message

def getClosestMatchesSation(targetStation,stations):
    stationsList = [i['stationName'] for i in stations]
    station = get_close_matches(targetStation,stationsList,n=1,cutoff=0.6)
    if station[0] != targetStation:
        answer = input ("Cannot find station '%s' from the list of stations. Did you mean '%s' (y/n)?" % (targetStation,station[0]))
        if answer == 'y' or answer == 'Y':
            return station[0]
        else:
            stations = get_close_matches(targetStation,stationsList,n=5,cutoff=0.6)
            sys.exit("Try to use one of these station names: %s" % (", ".join(stations)))
    return station[0]



def main(train, targetStation):
    # load relevan train and stations information from rata.digitraffic
    trainInfo = json.loads(request.urlopen("https://rata.digitraffic.fi/api/v1/trains/latest/" + str(train)).read())[0]
    stations = json.loads(request.urlopen("https://rata.digitraffic.fi/api/v1/metadata/stations").read())
    
    # find target station and generate returned json based information
    latestStation = searchLatestStation(trainInfo=trainInfo["timeTableRows"],
                                        keyName='liveEstimateTime')

    targetStation = getClosestMatchesSation(targetStation, stations)

    targetStationMetaData = searchFromListOfDicts(listOfDict=stations,
                                                  key=['stationName'],
                                                  value=[targetStation])

    infoDict = getInfoMessage(current_ts = datetime.now(),
                              trainBasicInfo = getBasicInfo(trainInfo=trainInfo,
                                                            keys=['trainNumber','departureDate','trainType']),
                              latestStation = latestStation,
                              latestStationInfo = searchFromListOfDicts(listOfDict=stations,
                                                                        key=['stationShortCode'],
                                                                        value=[latestStation['stationShortCode']]),
                              targetStationInfo = searchFromListOfDicts(listOfDict=trainInfo["timeTableRows"],
                                                                        key=['stationShortCode','type'],
                                                                        value=[targetStationMetaData['stationShortCode'],
                                                                                                     'ARRIVAL']),
                              targetStationMetaData = targetStationMetaData)

    infoJson = json.dumps(infoDict,
                          indent=4,
                          sort_keys=True,
                          ensure_ascii=False)
    print(infoJson)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Prints train running data based on train number and name of destination station. \nData is read from rata.digitraffic.fi api.')
    parser.add_argument('-t', '--train',
                        metavar='',
                        default=45,
                        help='Default: 45. Train number')
    parser.add_argument('-d', '--destination', metavar='',
                        default="Tampere asema",
                        help='Default: "Tampere asema". Name of destination station')

    args = parser.parse_args()
    
    main(train=args.train, targetStation=args.destination)
