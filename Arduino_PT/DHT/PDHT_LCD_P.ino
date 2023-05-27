#include <LiquidCrystal_I2C.h>
// Set the pins on the I2C chip used for LCD connections:
//                    addr, en,rw,rs,d4,d5,d6,d7,bl,blpol
LiquidCrystal_I2C lcd(0x27,20,4); 
#include <Wire.h>
#include <dht.h>                 
dht DHT;    
#define dht_dpin 2  
#include <SoftwareSerial.h>
#define pinR 3
#define pinG 9
#define pinY 6
#define pinO 5
#include <DS1307RTC.h>
#include <TimeLib.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>

File myFile;
const int chipSelect = 10;

String time ;
tmElements_t tm;
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
    Serial.begin(9600);
  while (!Serial) ; // wait for serial
  delay(200);
  Serial.println("ArduinoAll DataLogger Shield Test");
  pinMode(SS, OUTPUT);

  if (!SD.begin(chipSelect)) {
    Serial.println("SD Card initialization failed!");
    return;  
  }
  Serial.println("SD Card OK.");
  ReadText();
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
  time = Now();
  Serial.println(time);
  WriteText(time);
  delay(1000);
}
void retrievepm25(){
DHT.read11(dht_dpin);   
//Serial.print("Humidity = ");  
//Serial.print(DHT.humidity);  
//Serial.print("% ");  
//Serial.print("temperature = ");  
//Serial.print(DHT.temperature);  
//Serial.println("C ");  
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
      //Serial.println("check failed");
      break;
    }
    if(count > 15){
      //Serial.println("complete");
      break;
    }
    else if(count == 4 || count == 6 || count == 8 || count == 10 || count == 12 || count == 14) {
      high = c;
    }
    else if(count == 5){
      pmcf10 = 256*high + c;
      //Serial.print("PM1.0=");
      //Serial.print(pmcf10);
      //Serial.println(" ug/m3");

    }
    else if(count == 7){
      pmcf25
      = 256*high + c;
      //Serial.print("PM2.5=");
      //Serial.print(pmcf25);
      //Serial.println(" ug/m3");
      lcd.setCursor(0,2);
      lcd.print ("PM2.5:");
      lcd.print (pmcf25);
      lcd.print (" ug/m3");
      if (pmcf25 < 37) {
       r=0;
       g=100;
       y=0;
       o=0;
       
      }
       else if (pmcf25 < 50){
       r=0;
       g=0;
       y=100;
       o=0;
       
        }
      else  if(pmcf25 < 90){
       r=0;
       g=0;
       y=0;
       o=100;
       
        }
       else  if(pmcf25 >90){
       r=100;
       g=0;
       y=0;
       o=0;
       
       }
      analogWrite (3 ,r);
      analogWrite (9 ,g);
      analogWrite (6 ,y);
      analogWrite (5 ,o);
    }
      else if(count == 9){
      pmcf100 = 256*high + c;
      //Serial.print("PM10 =");
      //Serial.print(pmcf100);
      //Serial.println(" ug/m3");
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
void ReadText(){
  // re-open the file for reading:
  myFile = SD.open("test.txt");
  if (myFile) {
    Serial.println("test.txt:");

    // read from the file until there's nothing else in it:
    while (myFile.available()) {
      Serial.write(myFile.read());
    }
    // close the file:
    myFile.close();
  } 
  else {
    // if the file didn't open, print an error:
    Serial.println("error opening test.txt");
  }
}

void WriteText(String txt){
  myFile = SD.open("test.txt", FILE_WRITE);
  if (myFile) {
    myFile.println(txt);
    myFile.close();
  } 
  else {
    // if the file didn't open, print an error:
    Serial.println("error opening test.txt");
  }
}


String Now(){
  String time = "";
  if (RTC.read(tm)) {
    
    time+="H: ";
    time+=DHT.humidity;
    time+=" T: ";
    time+=DHT.temperature;
    time+=" PM1.0: ";
    time+=pmcf10;
    time+=" PM2.5: ";
    time+=pmcf25;
    time+=" PM10: ";
    time+=pmcf100;
  } 
  else {
    time = "NO";
    if (RTC.chipPresent()) {
      Serial.println("The DS1307 is stopped.  Please run the SetTime");
      Serial.println("example to initialize the time and begin running.");
      Serial.println();
    } 
    else {
      Serial.println("DS1307 read error!  Please check the circuitry.");
      Serial.println();
    }
  }
  return time;
}
