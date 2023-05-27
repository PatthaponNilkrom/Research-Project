#include <LiquidCrystal_I2C.h>
// Set the pins on the I2C chip used for LCD connections:
//                    addr, en,rw,rs,d4,d5,d6,d7,bl,blpol
LiquidCrystal_I2C lcd(0x27,20,4); // 設定 LCD I2C 位址

#include <Wire.h>
#include <dht.h>                 //使用DHT11 LibraryLiquidCrystal_I2C lcd(0x27,16,2);
dht DHT;    
#define dht_dpin 2  
#include <SoftwareSerial.h>
#define pinR 9
#define pinG 10
#define pinY 11
#define pinO 6
SoftwareSerial mySerial(7, 1); // RX, TX
long pmcf10=0;
long pmcf25=0;
long pmcf100=0;
long pmat10=0;
long pmat25=0;
long pmat100=0;
char buf[50];
  int r = 0;
  int g = 0;
  int y = 0;
  int o = 0;
  
void setup() {
  lcd.begin();
  pinMode(pinR, OUTPUT);
  pinMode(pinG, OUTPUT);
  pinMode(pinY, OUTPUT);
  pinMode(pinO, OUTPUT);
  Serial.begin(9600);
  mySerial.begin(9600);
  delay(300);             //Let system settle
}
void loop() {
 retrievepm25();
}
void retrievepm25(){
DHT.read11(dht_dpin);   
Serial.print("Humidity = ");  
Serial.print(DHT.humidity);  
Serial.print("% ");  
Serial.print("temperature = ");  
Serial.print(DHT.temperature);  
Serial.println("C ");  
lcd.clear(); 
lcd.setCursor(0, 0);
lcd.print("Humidity:");  
lcd.print(DHT.humidity);  
lcd.print(" %");
lcd.setCursor(0,1);  
lcd.print("Temperature:");  
lcd.print(DHT.temperature);
lcd.print((char)223);
lcd.println("C ");

  int count = 0;
  unsigned char c;
  unsigned char high;
  while (mySerial.available()) {
    c = mySerial.read();
    if((count==0 && c!=0x42) || (count==1 && c!=0x4d)){
      Serial.println("check failed");
      break;
    }
    if(count > 15){
      Serial.println("complete");
      break;
    }
    else if(count == 4 || count == 6 || count == 8 || count == 10 || count == 12 || count == 14) {
      high = c;
    }
    else if(count == 5){
      pmcf10 = 256*high + c;
      Serial.print("PM1.0=");
      Serial.print(pmcf10);
      Serial.println(" ug/m3");

    }
    else if(count == 7){
      pmcf25
      = 256*high + c;
      Serial.print("PM2.5=");
      Serial.print(pmcf25);
      Serial.println(" ug/m3");
      lcd.setCursor(0,2);
      lcd.print ("PM2.5:");
      lcd.print (pmcf25);
      lcd.print (" ug/m3");
      if (pmcf25 < 15.4) {
       r=0;
       g=100;
       y=0;
       o=0;
         
      }
       else if (pmcf25 < 35.4){
          r=0;
          g=0;
          y=100;
          o=0;
        }
      else  if(pmcf25<55.4){
          r=0;
          g=0;
          y=0;
          o=100;//40
        }
      else  if(pmcf25 <150.4){
          r=100;//80
          g=0;
          y=0;
          o=0;
        }
      else if(pmcf25 >150.4){
          r=162;
          g=0;
          y=0;
          o=0;
          
        }

      analogWrite (9 ,r);
      analogWrite (10 ,g);
      analogWrite (11 ,y);
      analogWrite (6 ,o);
    }
    else if(count == 9){
      pmcf100 = 256*high + c;
      Serial.print("PM10 =");
      Serial.print(pmcf100);
      Serial.println(" ug/m3");
      lcd.setCursor(0,3);
      lcd.print ("PM10 :");
      lcd.print (pmcf100);
      lcd.print (" ug/m3");
    }
    count++;
  }
  while(mySerial.available()) mySerial.read();  
  Serial.println();
  delay(1000);
}
