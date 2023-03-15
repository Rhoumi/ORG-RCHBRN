
#include <SPI.h>
//#include <Ethernet.h>
//#include <EthernetUdp.h>
#include <OSCMessage.h>

#define DEBUG_ETHERNET_WEBSERVER_PORT       Serial

// Debug Level from 0 to 4
#define _ETHERNET_WEBSERVER_LOGLEVEL_       3

#include <WebServer_WT32_ETH01.h>

// Define the IP address and port of the receiving computer
IPAddress ip(192, 168, 1, 150);  // Change this to the IP address of the receiving computer
const int port = 9056;  // Change this to the port number used by the receiving computer

// Select the IP address according to your local network
IPAddress myIP(192, 168, 1, 177);
IPAddress myGW(192, 168, 1, 1);
IPAddress mySN(255, 255, 255, 0);

// Google DNS Server IP
IPAddress myDNS(8, 8, 8, 8);

unsigned int localPort = 8888;    //10002;  // local port to listen on

char packetBuffer[255];          // buffer to hold incoming packet
byte ReplyBuffer[] = "ACK";      // a string to send back

// A UDP instance to let us send and receive packets over UDP
WiFiUDP Udp;

// Define the number of readings to average
const int numReadings = 100;

// Define an array to store the readings
int readings[numReadings];

// Define a variable to keep track of the index of the next reading
int lindex = 0;

void setup()
{
  Serial.begin(115200);

  // To be called before ETH.begin()
  WT32_ETH01_onEvent();

  //bool begin(uint8_t phy_addr=ETH_PHY_ADDR, int power=ETH_PHY_POWER, int mdc=ETH_PHY_MDC, int mdio=ETH_PHY_MDIO,
  //           eth_phy_type_t type=ETH_PHY_TYPE, eth_clock_mode_t clk_mode=ETH_CLK_MODE);
  //ETH.begin(ETH_PHY_ADDR, ETH_PHY_POWER, ETH_PHY_MDC, ETH_PHY_MDIO, ETH_PHY_TYPE, ETH_CLK_MODE);
  ETH.begin(ETH_PHY_ADDR, ETH_PHY_POWER);

  // Static IP, leave without this line to get IP via DHCP
  //bool config(IPAddress local_ip, IPAddress gateway, IPAddress subnet, IPAddress dns1 = 0, IPAddress dns2 = 0);
  ETH.config(myIP, myGW, mySN, myDNS);

  WT32_ETH01_waitForConnect();

  Serial.println(F("\nStarting connection to server..."));
  // if you get a connection, report back via serial:
  Udp.begin(localPort);

  Serial.print(F("Listening on port "));
  Serial.println(localPort);
}

void loop()
{
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
  //msg.add("Hello, world!");

  // send a reply, to the IP address and port that sent us the packet we received
  Udp.beginPacket(ip, port);
  msg.send(Udp);
  Udp.endPacket();

  msg.empty();
  delay(100);

}
