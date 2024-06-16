#include "ESP8266WiFi.h"

//#define LOG

const char* ssid = "SSID";
const char* password = "PASSWORD";
WiFiServer wifiServer(80);

int commitBytePin = 0;
int gatePin = 15;
int clockPin = 4;
int dataPin = 5;

char outbuf[1024];

void pinReset() {
  digitalWrite(clockPin, 0);
  pinMode(clockPin, OUTPUT);

  digitalWrite(dataPin, 0);
  pinMode(dataPin, OUTPUT);

  digitalWrite(gatePin, 1);
  pinMode(gatePin, OUTPUT);

  digitalWrite(commitBytePin, 0);
  pinMode(commitBytePin, OUTPUT);
}

void setup() {
  pinReset();

#ifdef LOG
  Serial.begin(115200);
  Serial.print("\n\nBooting");
#endif

  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
#ifdef LOG
    Serial.println("Connecting...");
#endif
  }
 
#ifdef LOG
  Serial.print("Connected to WiFi IP: ");
  Serial.println(WiFi.localIP());
#endif
 
  wifiServer.begin();
}

void commitBit(bool on) {
  digitalWrite(dataPin, on);
  delayMicroseconds(1);
  digitalWrite(clockPin, HIGH);
  delayMicroseconds(1);
  digitalWrite(clockPin, LOW);
}

void commitByte(uint8_t byte, uint16_t location, WiFiClient client) {
  if(location==0) {
    digitalWrite(gatePin, 0);
    delay(1);
  }

  sprintf(outbuf, "                :          | %04X: [%02X]\n", location, byte);

  for(int f=0;f<16;f++) {
    bool on = location & 0b1000000000000000;
    location <<= 1;
    outbuf[f] = on ? '1' : '0';
    commitBit(on);
  }

  for(int f=0;f<8;f++) {
    bool on = byte & 0b10000000;
    byte <<= 1;
    outbuf[f+18] = on ? '1' : '0';
    commitBit(on);
  }

  digitalWrite(commitBytePin, 1);
  client.print(outbuf);
  delayMicroseconds(100);
  digitalWrite(commitBytePin, 0);
  delayMicroseconds(100);
}

bool handleClientSession(WiFiClient client) {
  uint8_t currentByte = 0;
  uint16_t address = 0;
  bool nibbleCount = false;

  pinReset();
  client.print("\nREADY> ");

  while(client.connected()) {
    while(client.available() > 0) {
      uint8_t next = client.read();
      if (next >= '0' && next <= '9') {
        next -= 48;

      } else if (next >= 'A' && next <= 'F') {
        next -= 55;

      } else if (next >= 'a' && next <= 'f') {
        next -= 87;

      } else if(next=='\n') {
        return true;

      } else {
        continue;
      }
      
      if(nibbleCount == 0) {
        currentByte = next << 4;
        nibbleCount = 1;

      } else {
        currentByte |= next;
        nibbleCount = 0;
        commitByte(currentByte, address, client);
        address++;
      }
    }
  }
  client.stop();
  return false;
}

void loop() {
  if (WiFiClient client = wifiServer.available()) { 
#ifdef LOG
    Serial.println("Client connected");
#endif
    bool connected = true;
    while(connected) {
      connected = handleClientSession(client);
    }
#ifdef LOG
    Serial.println("Client disconnected");
#endif
  }
}
