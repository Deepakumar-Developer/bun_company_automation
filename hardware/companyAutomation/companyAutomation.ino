#include <SoftwareSerial.h>

const int hc05Tx = 13;
const int lightOnRelay = 2;
const int lightOffRelay = 4;
const int fanOnRelay = 6;
const int fanOffRelay = 8;

SoftwareSerial BTSerial(12,hc05Tx); //tr,rx

String commend = "";
bool cmdComplete = false;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Serial.println("The Circuit Start");
  BTSerial.begin(9600);

  pinMode(lightOnRelay, OUTPUT);
  pinMode(lightOffRelay, OUTPUT);
  pinMode(fanOnRelay, OUTPUT);
  pinMode(fanOffRelay, OUTPUT);
  
  digitalWrite(lightOffRelay, LOW);
  digitalWrite(lightOnRelay, HIGH);
  digitalWrite(fanOffRelay, LOW);
  digitalWrite(fanOnRelay, HIGH);
}

void loop() {
  // put your main code here, to run repeatedly:
  while (BTSerial.available()) {
    char cmd = BTSerial.read();
    Serial.println(cmd);
    if (cmd == '\n') {
      cmdComplete = true;
    } else {
      commend += cmd;
    }
  }

  if(cmdComplete) {
    Serial.println(commend);

    if(commend[0] == 'L') {
      if(commend[1] == '1') {
        digitalWrite(lightOnRelay, LOW);
        digitalWrite(lightOffRelay, LOW);
        Serial.println("Received '1'. Light ON. Sent confirmation.");

      } else if(commend[1] == '0') {
        digitalWrite(lightOnRelay, HIGH);
        digitalWrite(lightOffRelay, HIGH);
        Serial.println("Received '0'. Light OFF. Sent confirmation.");

      } else if(commend[1] == 'S') {
        digitalWrite(lightOffRelay, LOW);
        digitalWrite(lightOnRelay, HIGH);
        Serial.println("Received 'A'. Light Switch control. Sent confirmation.");

      }
    }
    if(commend[0] == 'R') {
      if(commend[1] == '1') {
        digitalWrite(fanOnRelay, LOW);
        digitalWrite(fanOffRelay, LOW);
        Serial.println("Received '1'. Fan ON. Sent confirmation.");
        
      } else if(commend[1] == '0') {
        digitalWrite(fanOnRelay, HIGH);
        digitalWrite(fanOffRelay, HIGH);
        Serial.println("Received '0'. Fan OFF. Sent confirmation.");

      } else if(commend[1] == 'S') {
        digitalWrite(fanOffRelay, LOW);
        digitalWrite(fanOnRelay, HIGH);
        Serial.println("Received 'A'. Fan Swith Control. Sent confirmation.");

      }
    }

    commend = "";
    cmdComplete = false;
  }
}
