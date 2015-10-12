//file: helloworld.c
//Authors: William Putnam, Jeff Falberg
//Last Updated: 10.9.2015

//Description: Flash LEDs based on DIP switch position.

#include <stdio.h>
#include <unistd.h>
#include "platform.h"
#include "xgpio_l.h"
#include "xparameters.h"
#include "xbasic_types.h"

u32 DIP_read, DIP_write;

int main()
{
	int sleepyTime = 0, DIP[4], LEDarr[6] = {0}, i;

    init_platform();

    for(;;){
    	DIP_read = XGpio_ReadReg(XPAR_DIP_SWITCHES_4BIT_BASEADDR,0);
    	XGpio_WriteReg(XPAR_LEDS_6BIT_BASEADDR, 0, DIP_read);
    	print(DIP_read);
    	if (DIP_read == 0) sleepyTime = 1000;

    	else if (DIP[1]) sleepyTime = 1000;

    	else if (DIP[2]) sleepyTime = 5000;

    	else if (DIP[3]) sleepyTime = 10000;

    	//implement when we can figure out what DIP_read is
    	/*DIP_write = 0;
    	XGpio_WriteReg(XPAR_LEDS_6BIT_BASEADDR, 0, DIP_write);
    	for (i=0; i < sleepyTime; ++i){}
    	DIP_write = 999;
    	XGpio_WriteReg(XPAR_LEDS_6BIT_BASEADDR, 0, DIP_write);*/
    }

    cleanup_platform();

    return 0;
}
