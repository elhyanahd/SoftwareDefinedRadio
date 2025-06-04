/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xgpio_l.h"


int main()
{
    init_platform();
    /*
    print("Hello World\n\r");
    // This line will write value 2 to DATA2 register in DIPS_AND_LEDS from Vivado IP
    XGpio_WriteReg(XPAR_DIPS_AND_LEDS_BASEADDR, XGPIO_DATA2_OFFSET,0x02);
    // This line reads current value of dip switched and prints in hex
    printf("DIPs read : %x\r\n", XGpio_ReadReg(XPAR_DIPS_AND_LEDS_BASEADDR,XGPIO_DATA_OFFSET));
    print("Successfully ran Hello World application");
    */ 
    sleep(10);
    print("\r\nName: Elhyanah Desir\n\r");   
    // This line reads starting switch value and prints in hex
    u32 switch_val = XGpio_ReadReg(XPAR_DIPS_AND_LEDS_BASEADDR,XGPIO_DATA_OFFSET);
    XGpio_WriteReg(XPAR_DIPS_AND_LEDS_BASEADDR, XGPIO_DATA2_OFFSET, switch_val);
    printf("Initial DIPs read : %x\r\n", switch_val);
    
    //In a loop, continously read the switch values
    //Print the new switch value whenever the switch 
    //value changes and set the leds high to match the
    //current switch value
    while(1)
    {
        u32 current_val = XGpio_ReadReg(XPAR_DIPS_AND_LEDS_BASEADDR,XGPIO_DATA_OFFSET);
        if (current_val != switch_val)
        {
            switch_val = current_val;
            XGpio_WriteReg(XPAR_DIPS_AND_LEDS_BASEADDR, XGPIO_DATA2_OFFSET, switch_val);
            printf("DIPs now reads : %x\r\n", switch_val);     
        }        
    }
    cleanup_platform();
    return 0;
}
