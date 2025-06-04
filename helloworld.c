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
#include "platform.h"
#include "xuartps_hw.h"        // R byte from Ps7 UART
#include "xil_printf.h"
#include "xparameters.h"    // List of every peripheral in your system
#include "xgpio_l.h"        // R/W GPIO
#include "xiic_l.h"         // R/W I2C (IIC interface)
#include "sleep.h"


// /*
//  * @brief: Helper function used to write specific
//  *         values to given CODEC registers.
//  */
void writeCodecReg(u8 regnum, u16 regval)
{
    u8 buffer[2];    
    buffer[0] = (regnum << 1) | ((regval >> 8) & 0x01);  // 7-bit reg address + 8th bit of register value
    buffer[1] = regval & 0xFF;                           // lower 8 bits
    unsigned result = XIic_Send(XPAR_AXI_IIC_0_BASEADDR, 0x1A, buffer, 2, XIIC_STOP);

    if (result != 2) 
    {   printf("\r\nwriteCodecReg(%u,%u) failed\r\n", regnum, regval);  }
}

// /*
//  * @brief: Function that is used to perform 
//  *         initial configuration of CODEC.
//  */
void configureCodec()
{
    writeCodecReg(15,0x00);
    usleep(1000);
    writeCodecReg(6,0x37);
    writeCodecReg(0,0x80);
    writeCodecReg(1,0x80);
    writeCodecReg(2,0x79);
    writeCodecReg(3,0x79);
    writeCodecReg(4,0x10);
    writeCodecReg(5,0x00);
    writeCodecReg(7,0x02);
    writeCodecReg(8,0x00);
    usleep(75000);
    writeCodecReg(6,0x27);
    usleep(75000);
    writeCodecReg(9,0x01);
    print("CODEC configured now, press +/- to increase/decrease volume\n\r");
    print("Remember to include shift for +\n\r");
}

/*
 * @brief: Write given volume to CODEC
 */
void setVolume(u16 volume)
{
    writeCodecReg(2, volume);
    writeCodecReg(3, volume);
    printf("Volume set to: 0x%04x\r\n", volume);
}

/*
 * @brief: Read switch values and write switch hex 
 *         value to the leds.
 */
void setLeds()
{
    u32 switch_val = XGpio_ReadReg(XPAR_DIPS_AND_LEDS_BASEADDR,XGPIO_DATA_OFFSET);
    XGpio_WriteReg(XPAR_DIPS_AND_LEDS_BASEADDR, XGPIO_DATA2_OFFSET, switch_val);  
}

int main()
{
    init_platform();

    print("\r\nCalling configureCodec()...\n\r");  
    configureCodec(); 

    //In a loop, continously read the switch values
    //and set the leds high based on the current
    //switch value
    u16 volume = 0x79;
    while(1)
    {
        //setLeds();   //for Debugging   
        if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
        {
            char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
            
            if (c == '+' && volume < 0x7F) 
            {   
                volume++;   
                setVolume(volume);
            } 
            else if (c == '-' && volume > 0x00) 
            {   
                volume--;  
                setVolume(volume); 
            }
        }
    }
    cleanup_platform();
    return 0;
}
