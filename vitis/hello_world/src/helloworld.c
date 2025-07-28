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
#include <xil_printf.h>
#include <xil_types.h>
#include "platform.h"
#include "xuartps_hw.h"        // R byte from Ps7 UART
#include "xparameters.h"    // List of every peripheral in your system
#include "xgpio_l.h"        // R/W GPIO
#include "xiic_l.h"         // R/W I2C (IIC interface)
#include "sleep.h"

static int32_t frequency = 0; 
static int32_t tune = 0; 
static const u16 volume_table[] = {0x49, 0x4F, 0x55, 0x5B, 0x61, 0x67, 0x6D, 0x73, 0x79, 0x7F};
static int volume_index = 8;  // start at 0x79
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
    writeCodecReg(2,volume_table[volume_index]);
    writeCodecReg(3,volume_table[volume_index]);
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
 */
void setVolume()
{
    writeCodecReg(2, volume_table[volume_index]);
    writeCodecReg(3, volume_table[volume_index]);
}

/*
 * @brief: Return 32-bit value phase increment for input to DDS
 *         based on given frequency. 
 */
int32_t getIncrement(int32_t freq) 
{   
    int64_t freqTemp = (int64_t)freq;
    int64_t result = (freqTemp * 134217728) / 125000000; 
    return (int32_t)result; 
}

/*
 * @brief: Enable active-low reset. 
 */
void performReset() 
{    
    XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 0x0);
    usleep(1);
    XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA_OFFSET, 0x1);
}

/*
 *  @brief: Display new frequency
 */
void displayValues()
{   printf("\n\r\tCurrent Frequency is %d Hz\n\r", frequency);  }

/*
 *  @brief: Display audio system menu
 */
void displayMenu()
{
    print("\n\r\n\rName: Elhyanah Desir\n\r"); 
    print("Welcome to audio system.\n\r"); 
    print("\tPress 't' to tune radio to a new frequency.\n\r");
    print("\tPress 'f' to set the fake ADC to a new frequency.\n\r");
    print("\tPress 'U/u' to increase fake ADC frequency by 1000/100 Hz.\n\r");
    print("\tPress 'D/d' to decrease fake ADC frequency by 1000/100 Hz.\n\r");
    print("\tPress +/- to increase/decrease volume.\n\r");
    print("\tPress [space] to repeat this menu.\n\r");    
}

/*
 *  @brief: Loops and collects all the numeric value inputs by user
 *          to store frequency, Prints error messange if input is 
 *          not numeric else prints updated phase and frequency.
 *          If given frequency exceeds max 
 */
int32_t getFrequency()
{
    print("\n\r\tEnter a frequency in Hz: ");
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
                return -1;
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
    {   
        print("\n\r\tFrequency can't be larger than 100000000.\n\r");   
        return -1;
    }
    else if (wordLength == 0)
    {
        print("\n\r\tNo value provided, no frequency loaded\n\r");
        return -1;
    }
    else 
    {   return (int32_t)newFrequency;  }
}

int main()
{
    init_platform();
    print("Calling configureCodec()...\n\r");  
    configureCodec(); 

    displayMenu(); 

    frequency = 3001000;
    tune = 3000000;
    XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));
    XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, getIncrement(tune));
    printf("\n\r\n\r\tCurrent frequency set to %d Hz\n\r", frequency);
    performReset(); 

    //Loop through and perform whatever specified actions
    //based on the character that was sent over UART    
    int32_t temp = 0;
    while(1)
    {
        if(XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR))  
        {
            char c = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
        
            switch(c)
            {
                // Set frequency based on given user input
                case 'f':
                    temp = getFrequency(); 
                    if(temp != -1)  
                    {
                        frequency = temp;
                        XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));                        
                        displayValues(); 
                    }            
                    break;

                case 't':
                    temp = getFrequency(); 
                    if(temp != -1)  
                    {  
                        tune = temp;
                        XGpio_WriteReg(XPAR_AXI_GPIO_0_BASEADDR, XGPIO_DATA2_OFFSET, getIncrement(tune));
                        printf("\n\r\tTuned radio to %d Hz\n\r", tune);
                    } 
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

                    XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));
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

                    XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));
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

                    XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));
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

                    XGpio_WriteReg(XPAR_AXI_GPIO_1_BASEADDR, XGPIO_DATA_OFFSET, getIncrement(frequency));
                    displayValues(); 
                    break;
                
                //Increase Volume of Audio Signal
                case '+':
                    if(volume_index < 9)
                    {   
                        volume_index++;   
                        setVolume();
                        printf("\n\rSetting volume to %d.", volume_index);
                    }
                    else 
                    {   printf("\n\rVolume already at Max (%d).", volume_index);  }
                    break;

                case '-':
                    if (volume_index > 0)
                    {
                        volume_index--;
                        setVolume();
                        printf("\n\rSetting volume to %d.", volume_index);
                    }
                    else 
                    {   printf("\n\rVolume already at Min (%d).", volume_index);    }
                    break;

                // When 'r' pressed reset DDS
                case 'r':
                    performReset(); 
                    break;

                // When [space] pressed redisplay menu
                case 0x20:               
                    displayMenu(); 
                    break;
            }
        }   
    }

    cleanup_platform();
    return 0;
}
