#include <stdio.h>
#include <sys/mman.h> 
#include <fcntl.h> 
#include <unistd.h>
#define _BSD_SOURCE

#define RADIO_TUNER_FAKE_ADC_PINC_OFFSET 0
#define RADIO_TUNER_TUNER_PINC_OFFSET 1
#define RADIO_TUNER_CONTROL_REG_OFFSET 2
#define RADIO_TUNER_TIMER_REG_OFFSET 3
#define RADIO_PERIPH_ADDRESS 0x43c00000

#define XLLF_RDFR_OFFSET 6  /**< Receive Reset */
#define XLLF_RDFO_OFFSET 7  /**< Receive Occupancy */
#define XLLF_RDFD_OFFSET 8  /**< Receive Data */

#define FIFO_BASEADDR 0x43c10000

// the below code uses a device called /dev/mem to get a pointer to a physical
// address.  We will use this pointer to read/write the custom peripheral
volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{

	int mem_fd = open("/dev/mem", O_RDWR | O_SYNC); 
	void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr); 
	volatile unsigned int *radio_base = (volatile unsigned int *)map_base; 
	return (radio_base);
}

int main()
{
    unsigned int occupancy = 0;
    unsigned int dataWord = 0;
    int wordCount = 0;

    // first, get a pointer to the peripheral base address using /dev/mem and the function mmap
    volatile unsigned int *my_periph = get_a_pointer(FIFO_BASEADDR);
    volatile unsigned int *radio_periph = get_a_pointer(RADIO_PERIPH_ADDRESS);	
    
    *(radio_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 0; // make sure radio isn't in reset
    *(radio_periph+RADIO_TUNER_TUNER_PINC_OFFSET)= 0; //set tune to 0 Hz
    *(radio_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 1; // reset 
    *(radio_periph+RADIO_TUNER_FAKE_ADC_PINC_OFFSET) = 1073; //set fake adc to ~1000 Hz
    
    printf("Going to read %d FIFO samples…\n", 480000);
    while (wordCount < 480000) 
    {
        // Check Receive FIFO Occupancy (in bytes)
        occupancy = *(my_periph+XLLF_RDFO_OFFSET);

        // While there is data to read
        if (occupancy >= 4) 
        {
            // Read one word from FIFO Data register
            dataWord = *(my_periph+XLLF_RDFD_OFFSET);
            //Uncomment this to see read words changing
            //Note this will distort sound since the print statement
            //add delays
            //printf("Word %d is %d.\n", wordCount, dataWord);
            wordCount++;
        }
    }

    printf("Finished reading %d FIFO samples.\n", 480000);

    return 0;
}
