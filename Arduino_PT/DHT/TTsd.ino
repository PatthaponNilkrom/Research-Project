#include <SD.h>
#include <SPI.h>
#include "PMS.h"
PMS pms(Serial);
PMS::DATA data;

long seconds=00;
long minutes=00;
long hours=00;

int CS_pin = 10;

File sd_file;

void setup()  {
  Serial.begin(9600);
  pinMode(CS_pin, OUTPUT);

  // SD Card Initialization
  if (SD.begin())  {
    Serial.println("SD card is initialized. Ready to go");
  } 
  else  {
    Serial.println("Failed");
    return;
  }

  sd_file = SD.open("data.txt", FILE_WRITE);

  if (sd_file)  {
   Serial.print("PM 1.0 (ug/m3): ");
    Serial.print(",");
    Serial.print("PM 2.5 (ug/m3): ");
    Serial.print(",");
    Serial.print("PM 10.0 (ug/m3): ");
    Serial.print(",");

 

    Serial.println();
    sd_file.print("PM 1.0 (ug/m3): ");
    sd_file.print(",");
    sd_file.print("PM 2.5 (ug/m3): ");
    sd_file.print(",");
    sd_file.print("PM 10.0 (ug/m3): ");
    sd_file.print(",");

  }
  sd_file.close(); //closing the file
} 

void loop()  {
  sd_file = SD.open("data.txt", FILE_WRITE);
  if (sd_file)  {
    senddata();
  }
  // if the file didn't open, print an error:
  else  {
    Serial.println("error opening file");
  }
  delay(1000);
}

void senddata()  {
  for(long seconds = 00; seconds < 60; seconds=seconds+2)  {

    float temp = pms.read(data); //Reading the temperature as Celsius and storing in temp
    float hum = data.PM_AE_UG_2_5;     //Reading the humidity and storing in hum
    float fah = data.PM_AE_UG_10_0;

    sd_file.print(hours);
    sd_file.print(":");
    sd_file.print(minutes);
    sd_file.print(":");
    sd_file.print(seconds);
    sd_file.print(",  ");
 
    sd_file.print(temp);
    sd_file.print(",       ");

    Serial.print(hours);
    Serial.print(":");
    Serial.print(minutes);
    Serial.print(":");
    Serial.print(seconds);
    Serial.print(",  ");

    Serial.print(temp);
    Serial.print(",       ");


    if(seconds>=58)  {
      minutes= minutes + 1;
    }

    if (minutes>59)  {
      hours = hours + 1;
      minutes = 0;
    }

    sd_file.flush(); //saving the file

    delay(2000);
  }
  sd_file.close();   //closing the file
}
