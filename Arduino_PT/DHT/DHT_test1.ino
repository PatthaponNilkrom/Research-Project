#include <Wire.h>
#include "DHT.h"
#include <LiquidCrystal.h>
LiquidCrystal lcd(12, 11, 7, 6, 5, 4);
DHT dht;
void setup()
{
  Serial.begin(9600);
  Serial.println();
  Serial.println("Status\tHumidity (%)\tTemperature (C)\t(F)");
  dht.setup(8); // data pin 2
  lcd.begin(16,2);
}

void loop()
{
  delay(dht.getMinimumSamplingPeriod());
  float humidity = dht.getHumidity(); // ดึงค่าความชื้น
  float temperature = dht.getTemperature(); // ดึงค่าอุณหภูมิ
  Serial.print(dht.getStatusString());
  Serial.print("\t");
  Serial.print(humidity, 1);
  Serial.print("\t\t");
  Serial.print(temperature, 1);
  Serial.print("\t\t");
  Serial.println(dht.toFahrenheit(temperature), 1);
  
  lcd.setCursor(0, 0);
  lcd.print("humidity:     ");
  lcd.setCursor(10, 0);
  lcd.print(humidity);
  lcd.setCursor(14, 0);
  lcd.print("%");
  lcd.setCursor(0, 1);
  lcd.print("temp:     ");
  lcd.setCursor(5, 1);
  lcd.print(temperature);
  lcd.setCursor(9, 1);
  lcd.print("C");
  lcd.setCursor(11, 1);
  lcd.print(dht.toFahrenheit(temperature));
  lcd.setCursor(15, 1);
  lcd.print("F");
  delay(500);

}
