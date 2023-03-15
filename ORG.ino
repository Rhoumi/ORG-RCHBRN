/*---------------------------------------------------------------------------------------------

  Open Sound Control (OSC) library for the ESP8266/ESP32

  Example for sending messages from the ESP8266/ESP32 to a remote computer
  The example is sending "hello, osc." to the address "/test".

  This example code is in the public domain.
--------------------------------------------------------------------------------------------- */
//#if defined(ESP8266)
//#include <ESP8266WiFi.h>
//#else
#include <WiFi.h>
//#endif
#include <WiFiUdp.h>
#include <ETH.h>
#include <OSCMessage.h>
#include <HCSR04.h>
char ssid[] = "rem";          // your network SSID (name)
char pass[] = "remiremi";// your network password
//char ssid[] = "ORGRCHBRN";          // your network SSID (name)
//char pass[] = "ORGRCHBRN";// your network password
WiFiUDP Udp;  // A UDP instance to let us send and receive packets over UDP
const IPAddress outIp(192,168,43,164);  // remote IP of your computer
const unsigned int outPort = 9033;  // remote port to receive OSC
const unsigned int localPort = 8888;  // local port to listen for OSC packets (actually not used for sending)
//const int trigPin = D4;
//const int echoPin = D3;
//UltraSonicDistanceSensor distanceSensor(trigPin, echoPin);
void setup(){
  Serial.begin(115200);
  // Connect to WiFi network
  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  Serial.println("Starting UDP");
  Udp.begin(localPort);
  Serial.print("Local port: ");
  #ifdef ESP32
  Serial.println(localPort);
  #else
  Serial.println(Udp.localPort());
  #endif
}

void loop() {
  int sensorValue = analogRead(IO39);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
  float voltage = sensorValue * (5.0 / 1024.0);
  Serial.println(voltage);
  // int sensorValue = distanceSensor.measureDistanceCm();
  OSCMessage msg("/capteur");
  msg.add(sensorValue);
  Udp.beginPacket(outIp, outPort);
  msg.send(Udp);
  Udp.endPacket();
  msg.empty();
  delay(10);
// Serial.println(distanceSensor.measureDistanceCm());
}
