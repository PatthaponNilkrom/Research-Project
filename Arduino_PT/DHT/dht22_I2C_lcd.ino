// include the library code:
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "DHT.h"
#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

LiquidCrystal_I2C lcd(0x27,20,4);// set the LCD address to 0x27 for a 20 chars and 4 line display
void setup() {
    dht.begin();
    lcd.init();
    lcd.backlight();
 }
void loop() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  lcd.setCursor(0, 0);
  lcd.print("Temperature:");
  lcd.setCursor(13, 0);
    lcd.print(t);
  lcd.setCursor(19, 0);
  lcd.print("C");
  lcd.setCursor(0, 2);
  lcd.print("Humidity   :");
  lcd.setCursor(13, 2);
  lcd.print(h);
  lcd.setCursor(19, 2);
  lcd.print("%");
}
