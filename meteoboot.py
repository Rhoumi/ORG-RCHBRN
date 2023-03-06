#!/usr/bin/env python
#-*- coding: utf-8 -*-

from pyModbusTCP.client import ModbusClient
import time
from threading import Thread, Lock
from pythonosc.udp_client import SimpleUDPClient


#variables automate
SERVER_HOST = "10.10.10.3"
SERVER_PORT = 502
UNIT_ID = 255
regs_analog=[0,0,0,0,0,0]
regs_digital=[0,0,0,0]

# init a thread lock
regs_lock = Lock()
#analog pins IN
pinLight=0
pinWind=1
pinHygroExt=2
pinTempExt=3
pinTempInt=4
pinPotar=5
inputsNames=["/Novus/lightSensor","/Novus/windSensor","/Novus/hygroExtSensor","/Novus/tempExtSensor","/Novus/tempIntSensor","/Novus/potar","/Novus/rainSensor"]
#par defaut:inputsMinMax=[[0,1024],[0,1024],[0,1000],[-400,1000],[-200,850],[0,100]]
inputsMinMax=[[0,1024],[0,300],[0,1000],[-200,440],[-200,850],[0,100]]
#digital pins IN
pinSwitchOff=0
pinLightDC=1
pinRain=2
pinEndStopRegistre=3
#digital pins OUT
coilSound=0
coilLight=1
coilVmc=2
coilRegistre=3
#variables pour les lights
nbModules=8

# modbus polling thread
def polling_thread():
    #ip = "127.0.0.1"    #localhost
    ip = "10.10.10.255" #broadcasting
    port = 7400
    osc_Client = SimpleUDPClient(ip, port)  # Create osc client

    c = ModbusClient(host=SERVER_HOST, port=SERVER_PORT, unit_id=UNIT_ID, auto_open=True, auto_close=True)
    # polling loop
    
    while True:
        #open or reconnect TCP to server
        if not c.is_open():
            if not c.open():
                print("unable to connect to "+SERVER_HOST+":"+str(SERVER_PORT))
        if c.is_open():
            # do modbus reading on socket
            reg_list_analog = c.read_holding_registers(3, 6)
            reg_list_digital = c.read_holding_registers(18, 4)
            # if read is ok, store result in regs (with thread lock synchronization)
            if reg_list_analog:
                with regs_lock:
                    global regs_analog
                    new_regs_analog = list(reg_list_analog)         
                    for i in range(len(regs_analog)):
                        if new_regs_analog[i] != regs_analog[i]:
                            regs_analog[i] = new_regs_analog[i]
                            newValeur= 1/(inputsMinMax[i][1]-inputsMinMax[i][0])*(new_regs_analog[i]-1)
                            osc_Client.send_message(inputsNames[i], newValeur)
                    global regs_digital
                    new_regs_digital = list(reg_list_digital)
                    for i in range(len(regs_digital)):
                        if new_regs_digital[i] != regs_digital[i]:
                            regs_digital[i] = new_regs_digital[i]
                            if i == pinRain:
                                osc_Client.send_message(inputsNames[i+4], regs_digital[i])
                                
                
        # wait before next polling
        time.sleep(0.5)

#gestion de la temperature interne (registre/vmc)
def tempInt_thread():
    comptRegistreOn=0
    comptRegistreOff=0
    c = ModbusClient(host=SERVER_HOST, port=SERVER_PORT, unit_id=UNIT_ID, auto_open=True, auto_close=True)
    while True:
        #open or reconnect TCP to server
        if not c.is_open():
            if not c.open():
                print("unable to connect to "+SERVER_HOST+":"+str(SERVER_PORT))
        if c.is_open():
            #la temperature (avec la gestion du registre en temps de fonctionnement continu < 8 heures)
            if regs_analog[pinTempInt] > regs_analog[pinTempExt] >= 200 and comptRegistreOn < (60*60*8):
                c.write_single_coil(coilRegistre,1) #ouvrir registre
            else:
                c.write_single_coil(coilRegistre,0) #fermer registre
            if regs_analog[pinTempInt] > 250 and regs_digital[pinEndStopRegistre]:
                c.write_single_coil(coilVmc,1)   #allumer vmc
            else:
                c.write_single_coil(coilVmc,0)      #eteindre vmc
                
            if regs_digital[pinEndStopRegistre]:
                comptRegistreOn+=1
                comptRegistreOff=0
            else:
                comptRegistreOff+=1
                if comptRegistreOff > 60*60:
                    comptRegistreOn=0
        time.sleep(1)

#gestion du capteur de lumiere
def lumen_thread():
    memSeason=0
    memLight=0
    memDayTime=8
    c = ModbusClient(host=SERVER_HOST, port=SERVER_PORT, unit_id=UNIT_ID, auto_open=True, auto_close=True)
    
    while True:
        #open or reconnect TCP to server
        if not c.is_open():
            if not c.open():
                print("unable to connect to "+SERVER_HOST+":"+str(SERVER_PORT))
        if c.is_open():
            newLight=regs_analog[pinLight]
            

            #déterminer le moment de la journee
            
            if newLight != memLight:
                newDayTime=0
                newVecLight=0
                if (newLight-memLight) > 0:
                    newVecLight = 1
                else:
                    newVecLight = -1
                memLight=newLight
                if newLight < 17:                   #nuit
                    newDayTime=0
                #elif newLight > 17 and newLight < 27:
                elif 17 < newLight < 27:
                    if newVecLight > 0:                     #aurore
                        newDayTime=1
                    elif newVecLight < 0:                #crepuscule
                        newDayTime=3
                elif newLight > 27 :                     #jour
                    newDayTime=2
                    
                #allumage amplis/leds
                if newDayTime != memDayTime:
                    if newDayTime == 0:                  #nuit
                        print("eteindre amplis")
                        c.write_single_coil(coilSound,0)
                        print("allumer lumieres")
                        c.write_single_coil(coilLight,1)
                    elif newDayTime == 1:             #aurore
                        print("allumer amplis")
                        c.write_single_coil(coilSound,1)
                        print("allumer lumieres")
                        c.write_single_coil(coilLight,1)
                    elif newDayTime == 2:             #jour
                        print("eteindre lumieres")
                        c.write_single_coil(coilLight,0)
                        print("allumer amplis")
                        c.write_single_coil(coilSound,1)
                    elif newDayTime == 3:             #crepuscule
                        print("allumer lumieres")
                        c.write_single_coil(coilLight,1)
                        print("allumer amplis")
                        c.write_single_coil(coilSound,1)
                                                
                    memDayTime=newDayTime
        
        time.sleep(1)
     
    


#fonction envoyer ordres au Novus
def sendToNovus():
    c = ModbusClient(host=SERVER_HOST, port=SERVER_PORT, unit_id=UNIT_ID, auto_open=True, auto_close=True)

# fonction principale
def main():

    # start polling thread
    tp1 = Thread(target=polling_thread)
    tp2 = Thread(target=tempInt_thread)
    tp3 = Thread(target=lumen_thread)
    # set daemon: polling thread will exit if main thread exit
    tp1.daemon = True
    tp2.daemon = True
    tp3.daemon = True
    #start the threads
    tp1.start()
    tp2.start()
    tp3.start()

    while True:

        time.sleep(1)
    
#--- obligatoire pour rendre code exécutable ---
if __name__ == "__main__": # cette condition est vraie si le fichier est le programme exécuté
        main()# appelle la fonction principale
