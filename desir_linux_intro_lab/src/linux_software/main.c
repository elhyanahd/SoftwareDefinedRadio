#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#define _BSD_SOURCE

#define GPIO_2_OFFSET 2
#define GPIO_1_OFFSET 0
#define DIPS_AND_LEDS_BASEADDR 0x41200000
#define RGB_LED_BASEADDR 0x41210000

// Helper function to use /dev/mem device to get a pointer to given base address.  
// This pointer will allow read/write to GPIO
volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{

        int mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
        void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr);     
        volatile unsigned int *radio_base = (volatile unsigned int *)map_base;
        return (radio_base);
}

// Helper function which sets both RGBs to a certain value
// depending on the given GPIO pointer value 
void setRGB(volatile unsigned int *ptr, volatile unsigned int *rgb_led_ptr)
{
	switch (*(ptr))
	{
		case 0x0:		//RGB OFF
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x0;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x0;
			break;
		case 0x1:		//RGB Red
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x4;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x4;
			break;
		case 0x2:		//RGB Green
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x2;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x2;
			break;
		case 0x3:		//RGB Yellow (Red + Green)
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x6;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x6;
			break;
		case 0x4:		//RGB Blue
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x1;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x1;
			break;
		case 0x5:		//RGB Purple (Red + Blue)
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x5;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x5;
			break;
		case 0x6:		//RGB Cyan (Blue + Green)
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x3;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x3;
			break;
		case 0x7:		//RGB White (Red + Blue + Green)
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0xF;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0xF;
			break;
		default:
			*(rgb_led_ptr + GPIO_1_OFFSET) = 0x0;
			*(rgb_led_ptr + GPIO_2_OFFSET) = 0x0;
			break;
	}
}

void updateLEDs(volatile unsigned int *dipsandleds_ptr)
{
    
    static int LED_counter = 0;

    if(LED_counter == 15)
	{  	LED_counter = 0;   }                                                                          
    else
	{	LED_counter++;	}                                                                  
                                                                   
    *(dipsandleds_ptr+GPIO_1_OFFSET) = LED_counter;
}

int main()
{
	//Use helper function to get a pointer to the GPIOs    
    volatile unsigned int *dipsandleds_ptr = get_a_pointer(DIPS_AND_LEDS_BASEADDR);
    volatile unsigned int *rgb_led_ptr = get_a_pointer(RGB_LED_BASEADDR);

    printf("\n\r\n\rName: Elhyanah Desir\n\r");

    while (1)
    {
	    //update LEDs 2 increments per second
		updateLEDs(dipsandleds_ptr);
		usleep(500000); //500 ms

		//set RGB colors based on switches values
		setRGB(dipsandleds_ptr+GPIO_2_OFFSET, rgb_led_ptr);                                                               
    }
    return 0;
}