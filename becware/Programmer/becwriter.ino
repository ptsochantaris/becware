#include "ESP8266WiFi.h"
 
const char* ssid = "SSID";
const char* password = "PASSWORD";
WiFiServer wifiServer(80);

int commitBytePin = 0;
int gatePin = 15;
int clockPin = 4;
int dataPin = 5;

bool nibbleCount = 0;
uint8_t currentByte = 0;
uint16_t address = 0;
char outbuf[1024];

void pinReset() {
  nibbleCount = 0;
  address = 0;

  digitalWrite(clockPin, 0);
  pinMode(clockPin, OUTPUT);

  digitalWrite(dataPin, 0);
  pinMode(dataPin, OUTPUT);

  digitalWrite(gatePin, 1);
  pinMode(gatePin, OUTPUT);

  digitalWrite(commitBytePin, 0);
  pinMode(commitBytePin, OUTPUT);
}


void reset(WiFiClient client) {
  pinReset();
  delay(100);
  client.print("\nREADY> ");
}

void wifiSetup() {
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting...");
  }
 
  Serial.print("Connected to WiFi IP: ");
  Serial.println(WiFi.localIP());
 
  wifiServer.begin();
}

void setup() {
  pinReset();

  Serial.begin(115200);
  Serial.print("\n\nBooting");

  wifiSetup();
}

uint8_t getNextNibble(WiFiClient client) {
  while(client.connected()) {
    if (client.available() > 0) {
      uint8_t next = client.read();
      if (next >= '0' && next <= '9') {
        return next - '0';
      }
      if (next >= 'A' && next <= 'F') {
        return 10 + next - 'A';
      }
      if (next >= 'a' && next <= 'f') {
        return 10 + next - 'a';
      }
      if (next == '\n') {
        return 0xFF;
      }
    }
  }
  return 0xFE;
}

void commitCurrentByte(WiFiClient client) {
  if(address==0) {
    digitalWrite(clockPin, 0);
    digitalWrite(dataPin, 0);
    digitalWrite(commitBytePin, 0);
    digitalWrite(gatePin, 0);

    client.println("----------------------------- Started");
    delay(100);
  }

  int byte = address;
  sprintf(outbuf, "                :          | %04X: [%02X]\n", address, currentByte);

  for(int f=0;f<16;f++) {
    bool on = byte & 0b1000000000000000;
    byte <<= 1;
    commitBit(on, client);
    outbuf[f] = on ? '1' : '0';
  }

  byte = currentByte;

  for(int f=0;f<8;f++) {
    bool on = byte & 0b10000000;
    byte <<= 1;
    commitBit(on, client);
    outbuf[f+18] = on ? '1' : '0';
  }

  client.print(outbuf);

  address++;

  delayMicroseconds(10);
  digitalWrite(commitBytePin, 1);
  delayMicroseconds(10);
  digitalWrite(commitBytePin, 0);
}

void commitBit(bool on, WiFiClient client) {
  digitalWrite(dataPin, on);
  digitalWrite(clockPin, 1);
  delayMicroseconds(1);
  digitalWrite(clockPin, 0);
}

void loop() {
  WiFiClient client = wifiServer.available();
 
  if (client) { 
    Serial.println("Client connected");
    reset(client);
    while(client.connected()) {
      uint8_t next = getNextNibble(client);

      if(next==0xFE) {
        client.stop();
        Serial.println("Client disconnected");
        reset(client);

      } else if(next==0xFF) {
        reset(client);

      } else if(nibbleCount == 0) {
        currentByte = next << 4;
        nibbleCount = 1;

      } else {
        currentByte |= next;
        nibbleCount = 0;
        commitCurrentByte(client);    
      }
    }
  }
}
