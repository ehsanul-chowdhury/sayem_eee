#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "secrets.h"

#define MOISTURE_PIN 34
#define PH_PIN 35
#define PUMP_RELAY_PIN 26

#define MOISTURE_LOW_THRESHOLD 30
#define SENSOR_READ_INTERVAL_MS 5000

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastSensorRead = 0;

void connectWifi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected, IP: ");
  Serial.println(WiFi.localIP());
}

void connectFirebase() {
  config.api_key = FIREBASE_API_KEY;
  config.database_url = FIREBASE_DATABASE_URL;
  Firebase.signUp(&config, &auth, "", "");
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

int readMoisturePercent() {
  int raw = analogRead(MOISTURE_PIN);
  return constrain(map(raw, 4095, 0, 0, 100), 0, 100);
}

float readPh() {
  int raw = analogRead(PH_PIN);
  float voltage = raw * (3.3 / 4095.0);
  return 7.0 + ((2.5 - voltage) / 0.18);
}

void setPump(bool on) {
  digitalWrite(PUMP_RELAY_PIN, on ? HIGH : LOW);
  Firebase.RTDB.setString(&fbdo, "pump/status", on ? "ON" : "OFF");
}

void publishSensorReadings() {
  int moisture = readMoisturePercent();
  float ph = readPh();

  Firebase.RTDB.setInt(&fbdo, "moisture", moisture);
  Firebase.RTDB.setFloat(&fbdo, "ph", ph);
  Firebase.RTDB.setString(&fbdo, "tank", moisture > 0 ? "OK" : "LOW");
}

void applyMode() {
  if (!Firebase.RTDB.getString(&fbdo, "mode")) return;
  String mode = fbdo.stringData();

  if (mode == "AUTO") {
    bool shouldRun = readMoisturePercent() < MOISTURE_LOW_THRESHOLD;
    setPump(shouldRun);
    return;
  }

  if (!Firebase.RTDB.getString(&fbdo, "pump/command")) return;
  setPump(fbdo.stringData() == "ON");
}

void setup() {
  Serial.begin(115200);
  pinMode(PUMP_RELAY_PIN, OUTPUT);

  connectWifi();
  connectFirebase();
}

void loop() {
  if (millis() - lastSensorRead > SENSOR_READ_INTERVAL_MS) {
    lastSensorRead = millis();
    publishSensorReadings();
  }

  applyMode();
  delay(500);
}
