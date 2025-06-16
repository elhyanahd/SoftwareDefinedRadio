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
#include <ctype.h>
#include <xil_types.h>
#include "platform.h"
#include "xuartps_hw.h"        // R byte from Ps7 UART
#include "xllfifo_hw.h"        // W AXI4 Stream FIFO
#include "xil_printf.h"
#include "xparameters.h"    // List of every peripheral in your system
#include "xgpio_l.h"        // R/W GPIO
#include "xiic_l.h"         // R/W I2C (IIC interface)
#include "sleep.h"


static u32 sampleData [4096];
static u32 sampleSize;

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

/*
 * @brief: Function that is used to perform 
 *         initial configuration of CODEC.
 */
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
 * @brief: Cycle through 6.103 kHz sample points
 *         and send data to AXI FIFO. 
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

    //write word and word size to FIFO
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFD_OFFSET, word);
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TLF_OFFSET, sizeof(word));
    counter = (counter + 1) % 8;  // Ensures cycling without if statements
}


/*
 * @brief: 
 */
void writeToFIFO(int counter)
{
    u32 vacancy = 0x0;
    int32_t word = sampleData[counter];
    
    //block until FIFO is free
    do  {   vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFV_OFFSET); }
    while (vacancy < sizeof(word));

    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFD_OFFSET, word);
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TLF_OFFSET, sizeof(word));
}

/*
 * @brief: Loops through loaded file and stores 4 bytes
 *         in little edian format (first value LSB). Returns
 *         32-bit value. 
 */
u32 receiveFileData() 
{
    u32 data = 0;

    for(int i = 0; i < 4; i++)
    {
        while (!XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR)) {}  // Wait until a byte is received

        if (XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR)) 
        {   
            u8 byte = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);   
            data = (byte << 24) | (data >> 8); 
        }
    }

    return data;
}

/*
 * @brief: Once 'L' is pressed, loop until all file 
 *         samples are received based on the first 
 *         32-bit number read.
 */
void loadFile()
{
    int loaded = 0;
    u32 size = 0;

    int i = 0;
    while (loaded == 0)
    {
        //retrieve 32 bit word
        u32 byte = receiveFileData();   

        //If the word is the first 32-bit value
        //then store as size, else add to global 
        //array until sample size reached.
        if (size == 0)
        {   
            size = byte;
            continue;    
        }
        else 
        {
            sampleData[i] = byte;
            i++;
        }

        //End loop once sample size reached.
        if((u32)i == size)
        {   loaded = 1; }
    }

    sampleSize = size;
    printf("Successfully loaded %d audio samples!\n\r", size);
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
    print("\n\rName: Elhyanah Desir\n\r"); 
    print("Calling configureCodec()...\n\r");  
    configureCodec(); 
    print("Playing ~6kHz tone for 5 seconds...\n\r");
    for(int i = 0; i < 200000; i++)
    {   waveGenerator();    }
    
    print("Welcome to audio playback system.\n\r"); 
    print("\tpress L to load a file.\n\r");
    print("\tpress C to playback continously followed by any key to stop.\n\r");
    print("\tpress S to play the sound once.\n\r");
    print("\tpress B to play a piercing beep for 2 seconds.\n\r");

    while(1)
    {
        if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
        {
            char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
            c = toupper(c);
        
            switch(c)
            {
                case 'L':
                    print("Please load/send file through terminal client.\n\r");
                    loadFile();                
                    break;

                case 'C':
                    print("Playing sound continously. Press any key to stop.\n\r");
                    int stopped = 0;
                    int count = 0;
                    while(stopped == 0)
                    {   
                        writeToFIFO(count);  
                        count = (count + 1) % (int)sampleSize;    

                        if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
                        { 
                            stopped = 1; 
                            print("Sound stopped.\n\r");                            
                            (void) XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR); 
                        }                    
                    }
                    break;
                
                case 'S':
                    print("Playing sound once.\n\r");
                    for(int i = 0; i < (int)sampleSize; i++)
                    {   writeToFIFO(i);  }
                    break;

                case 'B':
                    print("Playing beep ....");                    
                    for(int i = 0; i < 50000; i++)
                    {   waveGenerator();    }
                    print("Done.\n\r");
                    break;

                case 'P':
                    for(int i = 0; i < (int)sampleSize; i++)
                    {   printf("%08x\n", sampleData[i]); }
                    break;

                default:
                    break;
            }
        }
    }

    cleanup_platform();
    return 0;
}
