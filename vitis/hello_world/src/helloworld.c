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
#include <xil_types.h>
#include "platform.h"
#include "xuartps_hw.h"        // R byte from Ps7 UART
#include "xllfifo_hw.h"        // W AXI4 Stream FIFO
#include "xil_printf.h"
#include "xparameters.h"    // List of every peripheral in your system
#include "xgpio_l.h"        // R/W GPIO
#include "xiic_l.h"         // R/W I2C (IIC interface)
#include "sleep.h"


/*
 * @brief: Helper function used to write specific
 *         values to given CODEC registers.
 * @param: regnum, regval
 */
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
 * @param: volume
 */
void setVolume(u16 volume)
{
    writeCodecReg(2, volume);
    writeCodecReg(3, volume);
    printf("Volume set to: 0x%04x\r\n", volume);
}

/*
 * @brief: Write given volume to CODEC
 * @param: volume 
 */
void modifyVolume(u16 *volume)
{
    if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
    {
        char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
    
        if (c == '+' && *volume < 0x7F) 
        {   
            (*volume)++;   
            setVolume(*volume);
        } 
        else if (c == '-' && *volume > 0x00) 
        {   
            (*volume)--;  
            setVolume(*volume); 
        }
    }
}

/*
 * @brief: Cycle through 6.103 kHz sample points
 *         and return that sample point based
 *         on the counter value.
 */
void waveGenerator()
{
    // static variable to maintain state across calls
    static int counter = 0;
    static const int32_t data_word[8] = {0, 7070, 10000, 7070, 0, -7070, -10000, -7070};

    u32 vacancy = 0x0;
    int32_t word = data_word[counter]; 

    //block until FIFO is free
    do  {   vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFV_OFFSET); }
    while (vacancy < sizeof(word));

    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFD_OFFSET, word);
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TLF_OFFSET, sizeof(word));
    counter = (counter + 1) % 8;  // Ensures cycling without if statements
}

/*
 * @brief: 
 */
void writeToFIFO()
{
    u32 vacancy = 0x0;
    
    //block until FIFO is free
    do  {   vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFV_OFFSET); }
    while (vacancy < sizeof(0x4010));

    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFD_OFFSET, 0x4010);
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TLF_OFFSET, sizeof(0x4010));
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
    print("\r\nName: Elhyanah Desir\n\r"); 
    print("\r\nCalling configureCodec()...\n\r");  
    configureCodec(); 
    
    //u16 volume = 0x79;
    while(1)
    {
        //setLeds();   //for Debugging 
        waveGenerator();  
        //modifyVolume(&volume);
    }

    cleanup_platform();
    return 0;
}
