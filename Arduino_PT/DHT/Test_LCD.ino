#include <LiquidCrystal.h>
const int rs = 12, en = 11, d4 = 5,d5 = 4, d6 = 3, d7 = 2;
LiquidCrystal lcd(12, 11, 5, 6, 7, 8);

void setup() {
  
 lcd.begin(16, 2);
 lcd.print("Siriwan");
 lcd.setCursor(0,1);
 lcd.print("Patthapon");
 }

void loop() {
}
