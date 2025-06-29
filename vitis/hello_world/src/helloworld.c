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
#include "xil_printf.h"
#include <xil_types.h>
#include "platform.h"
#include "xuartps_hw.h"        // R byte from Ps7 UART
#include "xparameters.h"    // List of every peripheral in your system
#include "xllfifo_hw.h"        // W AXI4 Stream FIFO
#include "xgpio_l.h"        // R/W GPIO
#include "xiic_l.h"         // R/W I2C (IIC interface)
#include "sleep.h"

static int32_t increment = 0;
static int32_t frequency = 0; 
static const int MAX = 100000000;

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
 * @brief: Helper function which sends given data
 *         to FIFO and after there is available space
 */
void writeToFIFO()
{
    u32 vacancy = 0x0;
    
    //block until FIFO is free
    do  {   vacancy = XLlFifo_ReadReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFV_OFFSET); }
    while (vacancy < sizeof(increment));

    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TDFD_OFFSET, increment);
    XLlFifo_WriteReg(XPAR_AXI_FIFO_MM_S_0_BASEADDR, XLLF_TLF_OFFSET, sizeof(increment));
}

/*
 * @brief: Set 32-bit value phase increment for input to DDS
 *         based on current frequency. 
 */
void setPhaseIncrement() 
{   
    int64_t freqTemp = (int64_t)frequency;
    int64_t result = (freqTemp * 134217728) / 125000000; 
    increment = (int32_t)result; 
}

/*
 * @brief: Enable active-low reset. 
 */
void performReset() 
{    
    XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 0x0);
    usleep(1);
    XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 0x1);
    print("\tReseting DDS....\n\r"); 
}

/*
 *  @brief: Display new frequency and increment
 */
void displayValues()
{
    print("\n\r\tupdating frequency:\n\r");
    printf("\tfreq\t= %d\n\r", frequency); 
    printf("\tphase_inc = %d\n\r", increment);   
    print("\n\r\n\r");
}

/*
 *  @brief: Display audio system menu
 */
void displayMenu()
{
    print("\n\r\n\rName: Elhyanah Desir\n\r"); 
    print("Welcome to audio system.\n\r"); 
    print("\tPress 'f' to tune to a new frequency.\n\r");
    print("\tPress 'U/u' to increase frequency by 1000/100 Hz.\n\r");
    print("\tPress 'D/d' to decrease frequency by 1000/100 Hz.\n\r");
    print("\tPress 'r' to reset the phase.\n\r");
    print("\tPress [space] to repeat this menu.\n\r");    
}

/*
 *  @brief: Loops and collects all the numeric value inputs by user
 *          to store frequency, Prints error messange if input is 
 *          not numeric else prints updated phase and frequency.
 *          If given frequency exceeds max 
 */
void getFrequency()
{
    frequency = 0;
    size_t lengthMax = 9;
    size_t wordLength = 0;
    char *word = (char *)malloc(lengthMax);

    //loop and store numeric frequency values
    //until the [enter/return] is pressed
    while(1)
    {
       if (XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR)) 
        {   
            char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR); 

            //Check that all inputs are numeric, if
            //not output error message and exit function
            if(c >= '0' && c <= '9')
            {   word[wordLength++] = c; }
            else if(c == 0x0D)
            {   break;  }
            else 
            {
                print("\n\r\tNot a valid character, no frequency loaded\n\r");
                return;
            }

            // Expand maxmimum length if needed
            if (wordLength + 1 >= lengthMax) 
            {
                lengthMax *= 2;
                char *newWord = (char *)realloc(word, lengthMax);
                word = newWord;
            }              
        }
    }

    print("\n\r\tReturn received, done reading frequency\n\r");
    word[wordLength] = '\0';
    long long newFrequency = atoll(word); 
    free(word);   

    if(newFrequency > 100000000 || wordLength > 9)
    {   print("\n\r\tFrequency can't be larger than 100000000.\n\r");   }
    else 
    {   frequency = (int32_t)newFrequency;  }

    setPhaseIncrement();
    displayValues();
}

int main()
{
    init_platform();
    print("Calling configureCodec()...\n\r");  
    configureCodec(); 

    displayMenu(); 

    frequency = 1000;
    setPhaseIncrement();
    performReset(); 

    //Loop through and perform whatever specified actions
    //based on the character that was sent over UART    
    while(1)
    {
        if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
        {
            char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
        
            switch(c)
            {
                // Set frequency based on given user input
                case 'f':
                    print("\n\r\tEnter a frequency in Hz: ");
                    getFrequency();                
                    break;

                // When 'D' decrease by 1000 Hz
                case 'D':
                    if (frequency >= 1000)
                    {   frequency -= 1000;  }
                    else 
                    {   
                        frequency = 0;  
                        print("\n\r\tMinimum frequency is 0 Hz.\n\r"); 
                    } 

                    setPhaseIncrement();
                    displayValues();               
                    break;
                
                // When 'd' decrease by 100 Hz
                case 'd':
                    if (frequency >= 100)
                    {   frequency -= 100;   }  
                    else
                    {   
                        frequency = 0;  
                        print("\n\r\tMinimum frequency is 0 Hz.\n\r"); 
                    }

                    setPhaseIncrement();
                    displayValues(); 
                    break;

                // When 'U' increase by 1000 Hz
                case 'U':
                    if(frequency <= (MAX - 1000))
                    {   frequency += 1000;  }
                    else 
                    {   
                        frequency = (int32_t)MAX;  
                        printf("\n\r\tMaximum frequency is %d Hz.\n\r", MAX);   
                    }

                    setPhaseIncrement();
                    displayValues();               
                    break;
                
                // When 'u' increase by 100 Hz
                case 'u':
                    if(frequency <= (MAX - 100))
                    {   frequency += 100;  }
                    else 
                    {   
                        frequency = (int32_t)MAX;  
                        printf("\n\r\tMaximum frequency is %d Hz.\n\r", MAX);  
                    }

                    setPhaseIncrement();
                    displayValues(); 
                    break;

                // When 'r' pressed redisplay menu
                case 'r':
                    performReset(); 
                    break;

                // When [space] pressed redisplay menu
                case 0x20:               
                    displayMenu(); 
                    break;
            }
        }   

        writeToFIFO();
    }

    cleanup_platform();
    return 0;
}
