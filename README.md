# 💡 Hybrid Smart Home Control System (Bluetooth/Mobile & Manual)

## 1. Project Overview

This project develops a **hybrid control system** for household appliances (lights and fan) that can be operated seamlessly via a **Flutter mobile application** and **traditional manual wall switches**.

The system utilizes an **Arduino Nano** and an **HC-05 Bluetooth module** to establish wireless communication, allowing the mobile application to either directly control the appliance state (Mobile Override) or relinquish control back to the manual switch (Switch Control Release).

---

![Circuit Image](https://github.com/Deepakumar-Developer/bun_company_automation/tree/main/assets/image.jpg)

## 2. Key Features

* **Dual Control Interface:** Remote control via the custom Flutter app and local control via existing wall switches.
* **Mobile Override:** The app can lock the appliance state (ON or OFF), ignoring manual switch input.
* **Switch Control Release:** The app can return control to the manual wall switch for traditional operation.
* **Simple Command Protocol:** Uses a two-character serial string for reliable control.

---

## 3. Hardware Components

| Component | Quantity | Purpose |
| :--- | :--- | :--- |
| **Arduino Nano** | 1 | Microcontroller for running control logic and interfacing. |
| **HC-05 Bluetooth Module** | 1 | Provides wireless serial communication with the mobile app. |
| **2-Channel Relay Module** | 1 | Used to interface low-voltage Arduino signals with appliance control (simulated by LEDs). |
| **LEDs & Resistors** | 2 sets | Prototype loads simulating the Light and Fan. |
| **Power Supply** | 1 | Provides power to the Arduino and components. |

---

## 4. Arduino Pin Configuration

The firmware is configured to control the relays using the following digital pins:

| Appliance | Control Function | Arduino Pin |
| :--- | :--- | :--- |
| **Light** | ON Relay (Mobile Control) | D2 |
| **Light** | OFF Relay (Mobile Control) | D4 |
| **Fan** | ON Relay (Mobile Control) | D6 |
| **Fan** | OFF Relay (Mobile Control) | D8 |
| **HC-05 (TX)** | Software Serial RX | D12 |
| **HC-05 (RX)** | Software Serial TX | D13 |

---

## 5. Communication Protocol

Commands are sent from the Flutter app to the Arduino via Bluetooth as a two-character string, terminated by a newline character (`\n`).

### Command Set

| Command | Target Appliance | Action | Control State |
| :--- | :--- | :--- | :--- |
| **L1** | Light | ON | Mobile Override |
| **L0** | Light | OFF | Mobile Override |
| **LS** | Light | Switch Control | Release Control to Manual Switch |
| **R1** | Right/Fan | ON | Mobile Override |
| **R0** | Right/Fan | OFF | Mobile Override |
| **RS** | Right/Fan | Switch Control | Release Control to Manual Switch |

---

## 6. Arduino Code (`Arduino_Control_Code.ino`)

The firmware handles Bluetooth reception and executes the relay switching logic based on the received commands.

### Setup and Initialization
```cpp
#include <SoftwareSerial.h>

const int hc05Tx = 13; // TX pin of Arduino connected to RX of HC-05
const int lightOnRelay = 2;
const int lightOffRelay = 4;
const int fanOnRelay = 6;
const int fanOffRelay = 8;

SoftwareSerial BTSerial(12, hc05Tx); // RX, TX pins

String commend = "";
bool cmdComplete = false;

void setup() {
  // Initialize Serial for debugging
  Serial.begin(9600);
  Serial.println("The Circuit Start");
  
  // Initialize SoftwareSerial for HC-05 communication
  BTSerial.begin(9600);

  // Set relay pins as output
  pinMode(lightOnRelay, OUTPUT);
  pinMode(lightOffRelay, OUTPUT);
  pinMode(fanOnRelay, OUTPUT);
  pinMode(fanOffRelay, OUTPUT);
  
  // Default State: Release Control (Relays set for manual switch operation)
  // NOTE: Assuming active-LOW relays for ON state, and specific HIGH/LOW 
  // combinations for switch control release (e.g., LOff=LOW, LOn=HIGH)
  digitalWrite(lightOffRelay, LOW);
  digitalWrite(lightOnRelay, HIGH); 
  digitalWrite(fanOffRelay, LOW);
  digitalWrite(fanOnRelay, HIGH);
}
void loop() {
  // Read incoming data from HC-05
  while (BTSerial.available()) {
    char cmd = BTSerial.read();
    // Serial.println(cmd); // Debug received character
    if (cmd == '\n') {
      cmdComplete = true; // Command is terminated
    } else {
      commend += cmd; // Build the command string
    }
  }

  // Process the complete command
  if(cmdComplete) {
    Serial.println("Received Command: " + commend);

    if(commend[0] == 'L') { // Light Control
      if(commend[1] == '1') {
        // L1: Light ON (Mobile Override)
        digitalWrite(lightOnRelay, LOW); // ON
        digitalWrite(lightOffRelay, LOW); // Locked State
        Serial.println("-> Light ON.");
      } else if(commend[1] == '0') {
        // L0: Light OFF (Mobile Override)
        digitalWrite(lightOnRelay, HIGH); // OFF
        digitalWrite(lightOffRelay, HIGH); // Locked State
        Serial.println("-> Light OFF.");
      } else if(commend[1] == 'S') {
        // LS: Release Control to Switch
        digitalWrite(lightOffRelay, LOW); 
        digitalWrite(lightOnRelay, HIGH); 
        Serial.println("-> Light Switch Control.");
      }
    }
    
    if(commend[0] == 'R') { // Fan/Right Appliance Control
      if(commend[1] == '1') {
        // R1: Fan ON (Mobile Override)
        digitalWrite(fanOnRelay, LOW); 
        digitalWrite(fanOffRelay, LOW); 
        Serial.println("-> Fan ON.");
      } else if(commend[1] == '0') {
        // R0: Fan OFF (Mobile Override)
        digitalWrite(fanOnRelay, HIGH);
        digitalWrite(fanOffRelay, HIGH);
        Serial.println("-> Fan OFF.");
      } else if(commend[1] == 'S') {
        // RS: Release Control to Switch
        digitalWrite(fanOffRelay, LOW); 
        digitalWrite(fanOnRelay, HIGH); 
        Serial.println("-> Fan Switch Control.");
      }
    }

    // Reset for the next command
    commend = "";
    cmdComplete = false;
  }
}
```

---

## 7. Mobile Application (Flutter)
The mobile application is responsible for:

- Scanning and pairing with the HC-05 module.

- Establishing a reliable Bluetooth connection.

- Sending the defined command strings to the Arduino upon button press.

Required Packages:

- flutter_bluetooth_serial

- permission_handler (for managing Bluetooth permissions)

---