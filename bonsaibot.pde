

// BonsaiBot 0.5
// Author:   James Carlson
// Email:   jxxcarlson@gmail.com
// Date:    Jan 2, 2016
// License: MIT

#include <Event.h>
#include <Timer.h>
#include <LiquidCrystal.h>

// http://playground.arduino.cc/Code/Timer

Timer t;
int wateringEvent; 
int waterDoseCount;
int waterDoseModulus = 20; // If it is N, water is on for 1 cycle out of N
#define OFF 0
#define ON 1
int wateringState = OFF ;

LiquidCrystal lcd(12, 11, 5, 4, 3, 2); 

const int wateringTime = 5; // seconds

const int warningLED = 7; 
const int relay = 8;
const int buzzer = 9;
const int sensor = A0;
const int pot = A1;

const int DELAY = 100;

const int veryWet = 90;
const int wet = 80;
const int moist = 70;
const int dry = 60;
const int veryDry = 50;
const int dangerouslyDry = 40;

int potReading;
int waterOnSetting = 0;
float sensorVoltage;
float soilResistance; 
float wetness;
unsigned long startTime;
unsigned long elapsedMilliseconds = 1000;
int elapsedSeconds;
int elapsedMinutes;
int elapsedHours;
int elapsedDays;

String message;



void setup() {  
  
  pinMode(warningLED, OUTPUT);
  pinMode(buzzer, OUTPUT);
  pinMode(relay, OUTPUT);
  Serial.begin(9600);
  lcd.begin(16, 2);
  lcd.print("hello, world!");
  startTime = millis();
  t.every(200,  getSensorReadings);
  t.every(1000, lcdMessage);
}

void loop() {
 computeTime();
 controlIndicators();
 controlRelay();
 t.update();
}

void getSensorReadings() {

  sensorVoltage = 5.0*analogRead(sensor)/1023;
  potReading = analogRead(pot);
  waterOnSetting = (int)round(100.0*potReading/1023.0);
  soilResistance = ((int)(10*(100.0*sensorVoltage/(5.0 - sensorVoltage))))/10.0;
  wetness = 100.0*(1.0 - sensorVoltage/5.0);
  if (wetness < 0.0) {
    wetness = 0.0;
  }

}

void controlIndicators() {

  if (wetness < dry) {
    digitalWrite(warningLED, HIGH);
    analogWrite(buzzer, 64);
  } else {
    digitalWrite(warningLED, LOW);
    analogWrite(buzzer, 0);
  } 
}


void controlRelay() {

   
   if (wetness < waterOnSetting && wateringState == OFF && elapsedMilliseconds > 1000) {
      Serial.println("Pulse relay, wateringState ON");
      wateringState = ON;
      waterDoseCount = 0;
      wateringEvent = t.every(1000, checkRelay);
      startTime = millis();
      digitalWrite(relay,HIGH);
      //t.pulse(relay, wateringTime * 1000, HIGH); // wateringTime seconds 
   } 

}

void checkRelay() {

  // Pulse water does -- emit water for one cycle
  // out of waterDoseModulus cycles to allow water
  // to soak in.
  Serial.println("checkRelay");
  if (waterDoseCount % waterDoseModulus == 0) {
    digitalWrite(relay, HIGH);
  } else {
    digitalWrite(relay, LOW);
  }
  waterDoseCount += 1;

  // Shut water valve if the soil is wet enough.
  if (wetness >= wet && wateringState == ON) {
    Serial.println("wateringState OFF");
    Serial.println("");
    wateringState = OFF;
    startTime = millis();
    digitalWrite(relay, LOW);
    t.stop(wateringEvent);
 
  }

  
  
}

void computeTime() {

  elapsedMilliseconds = millis() - startTime;
  elapsedSeconds = trunc(elapsedMilliseconds/1000.0);
  elapsedMinutes = trunc(elapsedMilliseconds/60000.0);
  elapsedHours = trunc(elapsedMilliseconds/3600000.0);
  elapsedDays = trunc(elapsedMilliseconds/86400000.0);
  
}

void serialMessage() {

  Serial.print(sensorVoltage);
  Serial.print(", ");
  Serial.print(soilResistance);
  Serial.print("    ");
  Serial.println(wetness);
}


void lcdMessage() {

  message = "";
 if (wetness > veryWet) {
    message = "very wet";
  } else if (wetness > wet) {
    message = "wet";
  } else if (wetness > moist) {
    message = "moist";
  } else if (wetness > dry) {
    message = "dry";
  } else if (wetness > veryDry) {
    message = "very dry";
  } else if (wetness > dangerouslyDry) {
    message = "DANGEROUSLY DRY";
  } else {
      message = "DANGEROUSLY DRY";
  }
  
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print(message);
  lcd.print(" ");
  lcd.print(sensorVoltage);
  lcd.print(" ");
  lcd.print((int)round(wetness));
  lcd.setCursor(0,1);
  
  
  if (wateringState == OFF) {
    lcd.print("");
  } else {
    lcd.print("ON: ");
  }

  if (wateringState == OFF) { 
    lcd.print(elapsedDays);
    lcd.print("d ");
    lcd.print(elapsedHours%24);
    lcd.print(":");
  }
  lcd.print(elapsedMinutes%60);
  lcd.print(":");
  lcd.print(elapsedSeconds%60);

  //lcd.print(" ");
  //lcd.print(potReading);
  lcd.print(" ");
  lcd.print(waterOnSetting);
  
  if (wateringState == ON) {
    lcd.print(" ");
    lcd.print(waterDoseCount);
  } 
  

}
