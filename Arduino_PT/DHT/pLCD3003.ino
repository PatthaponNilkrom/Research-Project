#include <LiquidCrystal_I2C.h>
#include <stdio.h>
#define N 23
 
char line1[16], line2[16];
unsigned char buffer [N];
int PM25 = 0, PM10 = 0;
LiquidCrystal_I2C lcd(0x27, 20, 4); 
 
bool checkValue(unsigned char *buf, int length)
{  
  bool flag=0;
  int sum=0;
 
  for(int i=0; i<(length-2); i++)
  {
    sum+=buf[i];
  }
  sum=sum + 0x42;
  
  if(sum == ((buf[length-2]<<8)+buf[length-1]))  
  {
    sum = 0;
    flag = 1;
  }
  return flag;
}
 
void setup() {
   Serial.begin(9600);
   lcd.backlight();
   lcd.begin();          
   lcd.setCursor(0,0);  
}
 
void loop() {
   
  char fel = 0x42;
  if(Serial.find(&fel, 1)) {
    Serial.readBytes(buffer,N);
  }  
 
  if(buffer[0] == 0x4d)
  {
    if(checkValue(buffer,N))
    {
        PM25=((buffer[5]<<8) + buffer[6]);
        PM10=((buffer[7]<<8) + buffer[8]);
         
        // rest of values (if you want to use it)
        //PM1=((buffer[3]<<8) + buffer[4]);
        //PM1a=((buffer[9]<<8) + buffer[10]);
        //PM25a=((buffer[11]<<8) + buffer[12]);
        //PM10a=((buffer[13]<<8) + buffer[14]);
    }
  }
   
  lcd.clear();
  lcd.setCursor(0,0); 
   
  sprintf(line1,"PM2.5=%d ug/m3",PM25);
  lcd.print(line1);
  lcd.setCursor(0,1);
   
  sprintf(line2,"PM10=%d ug/m3",PM10);
  lcd.print(line2);
   
}
