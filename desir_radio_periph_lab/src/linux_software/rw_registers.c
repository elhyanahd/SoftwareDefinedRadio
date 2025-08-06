#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h> 
#include <fcntl.h> 
#include <unistd.h>
#define _BSD_SOURCE

#define RADIO_TUNER_FAKE_ADC_PINC_OFFSET 0
#define RADIO_TUNER_TUNER_PINC_OFFSET 1
#define RADIO_TUNER_CONTROL_REG_OFFSET 2
#define RADIO_TUNER_TIMER_REG_OFFSET 3
#define RADIO_PERIPH_ADDRESS 0x43c00000

// the below code uses a device called /dev/mem to get a pointer to a physical
// address.  We will use this pointer to read/write the custom peripheral
volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{

	int mem_fd = open("/dev/mem", O_RDWR | O_SYNC); 
	void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr); 
	volatile unsigned int *radio_base = (volatile unsigned int *)map_base; 
	return (radio_base);
}

int32_t getIncrement(int32_t freq) 
{   
    int64_t freqTemp = (int64_t)freq;
    int64_t result = (freqTemp * 134217728) / 125000000; 
    return (int32_t)result; 
}

int main(int argc, char *argv[])
{
    if (argc < 3) 
    {
        printf("Usage: %s <adc_freq_hz> <tune_freq_hz>\n", argv[0]);
        return 1;
    }

    unsigned int adc_freq = (unsigned int)strtoul(argv[1], NULL, 10);
    unsigned int tune_freq = (unsigned int)strtoul(argv[2], NULL, 10);

    if(adc_freq > 100000000 || tune_freq > 100000000)
    {
        printf("Invalid frequencies: adc_freq = %d, tune_freq = %d\n", adc_freq, tune_freq);
        printf("The frequencies can't be larger than 100000000\n");
        return 1;
    }

    volatile unsigned int *my_periph = get_a_pointer(RADIO_PERIPH_ADDRESS);	
    *(my_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 0; // make sure radio isn't in reset
    *(my_periph+RADIO_TUNER_TUNER_PINC_OFFSET)= getIncrement((int32_t)tune_freq); //set tune
    *(my_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 1; // reset 
    *(my_periph+RADIO_TUNER_FAKE_ADC_PINC_OFFSET) = getIncrement((int32_t)adc_freq); //set fake adc
    return 0;
}
