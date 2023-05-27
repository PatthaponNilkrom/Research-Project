#include <Wire.h>
#include <LiquidCrystal_I2C.h>
 
// Set the LCD address to 0x27 or 0x3F for a 16 chars and 2 line display
LiquidCrystal_I2C lcd(0x27, 16, 2);
 
void setup()
{
// initialize the LCD
lcd.begin();
 
// Turn on the blacklight and print a message.
lcd.backlight();
lcd.setCursor(0, 0); // ไปที่ตัวอักษรที่ 0 แถวที่ 1
lcd.print("Welcome To");
 
lcd.setCursor(6, 1); // ไปที่ตัวอักษรที่ 6 แถวที่ 2
lcd.print("My arduino");
 
}
void loop() {
 
}
