/*---------------------------------------------------------------------------------------------
  Open Sound Control (OSC) library for the ESP8266/ESP32
  Example for sending messages from the ESP8266/ESP32 to a remote computer
  The example is sending "hello, osc." to the address "/test".
  This example code is in the public domain.
--------------------------------------------------------------------------------------------- */

#include <WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <HCSR04.h>

char ssid[] = "rem";            // your network SSID (name)
char pass[] = "remiremi";       // your network password

WiFiUDP Udp;                    // A UDP instance to let us send and receive packets over UDP

const IPAddress outIp(192,168,43,164); // remote IP of your computer
const unsigned int outPort = 9056;      // remote port to receive OSC
const unsigned int localPort = 8888;    // local port to listen for OSC packets (actually not used for sending)

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
  int sensorValue = analogRead(IO39); // using IO39 instead of D39
  // Convert the analog reading (which goes from 0 - 4095) to a voltage (0 - 5V):
  //float voltage = sensorValue * (5.0 / 4095.0);
  //Serial.println(voltage);

  OSCMessage msg("/capteur");
  msg.add(sensorValue);

  Udp.beginPacket(outIp, outPort);
  msg.send(Udp);
  Udp.endPacket();

  msg.empty();

  delay(10);
}
