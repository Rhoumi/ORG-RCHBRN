#include <SPI.h>
#include <Ethernet.h>
#include <EthernetUdp.h>
#include <OSCMessage.h>

// Define the IP address and port of the receiving computer
IPAddress ip(192, 168, 43, 164);  // Change this to the IP address of the receiving computer
const int port = 9056;  // Change this to the port number used by the receiving computer

// Define the MAC address and IP address of the Arduino
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };  // Change this to the MAC address of your Ethernet shield
IPAddress arduinoIP(192, 168, 1, 177);  // Change this to the IP address you want to use for the Arduino

// Create an Ethernet object and a UDP object
EthernetUDP Udp;
EthernetClient client;

// Define the number of readings to average
const int numReadings = 10;

// Define an array to store the readings
int readings[numReadings];

// Define a variable to keep track of the index of the next reading
int lindex = 0;


void setup() {
  // Start the serial communication
  Serial.begin(115200);

  // Start the Ethernet connection
  Ethernet.begin(mac, arduinoIP);

  // Start the UDP communication
  Udp.begin(8888);

  // Initialize the readings array with zeros
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
}

void loop() {
  int sensorValue = analogRead(IO39); // using IO39 instead of D39
  // Create an OSC message and add some data to it
  readings[lindex] = sensorValue;
  lindex++;

  // If the lindex is equal to the number of readings, wrap around to the beginning
  if (lindex == numReadings) {
    lindex = 0;
  }

  // Calculate the average of the readings
  int total = 0;
  for (int i = 0; i < numReadings; i++) {
    total += readings[i];
  }
  int average = total / numReadings;
  
  OSCMessage msg("/test");
  msg.add(sensorValue);
  msg.add(average);
  msg.add("Hello, world!");

  // Send the OSC message over Ethernet
  Udp.beginPacket(ip, port);
  msg.send(Udp);
  Udp.endPacket();

  // Send the OSC message over TCP
  if (client.connect(ip, port)) {
    msg.send(client);
    client.stop();
  }

  // Print a message to the serial monitor
  Serial.println("Sent OSC message");

  // Wait for a short time
  delay(10);
}
