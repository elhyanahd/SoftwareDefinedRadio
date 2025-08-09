#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <arpa/inet.h>
#include <sys/socket.h>
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

#define DEST_PORT 25344           // Target port
#define PACKET_MAX 1028
#define SAMPLE_MAX 256

// the below code uses a device called /dev/mem to get a pointer to a physical
// address.  We will use this pointer to read/write the custom peripheral
volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{

	int mem_fd = open("/dev/mem", O_RDWR | O_SYNC); 
	void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr); 
	volatile unsigned int *radio_base = (volatile unsigned int *)map_base; 
	return (radio_base);
}

void configureRadio()
{
    volatile unsigned int *radio_periph = get_a_pointer(RADIO_PERIPH_ADDRESS);	
    
    *(radio_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 0; // make sure radio isn't in reset
    *(radio_periph+RADIO_TUNER_TUNER_PINC_OFFSET)= 0; //set tune to 0 Hz
    *(radio_periph+RADIO_TUNER_CONTROL_REG_OFFSET) = 1; // reset 
    *(radio_periph+RADIO_TUNER_FAKE_ADC_PINC_OFFSET) = 1073; //set fake adc to ~1000 Hz
}

void sendUDP(const struct in_addr *ip_addr, volatile unsigned int *my_periph, int packetAmount)
{
    // Set up UDP socket
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) 
    {
        perror("Socket creation failed");
        return;
    }

    // Set up destination address struct
    struct sockaddr_in dest_addr;
    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(DEST_PORT);
    dest_addr.sin_addr = *ip_addr;  

    uint32_t packetCounter = 0;
    uint8_t packet[PACKET_MAX];

    for (int p = 0; p < packetAmount; ++p)
    {
        // Write 32-bit counter (little-endian)
        packet[0] = (packetCounter >> 0) & 0xFF;
        packet[1] = (packetCounter >> 8) & 0xFF;
        packet[2] = (packetCounter >> 16) & 0xFF;
        packet[3] = (packetCounter >> 24) & 0xFF;

        int index = 4;
        int wordCount = 0;

        while (wordCount < SAMPLE_MAX)
        {
            int occupancy = *(my_periph + XLLF_RDFO_OFFSET);
            if (occupancy >= 4)
            {
                // get 32-bit FIFO word and seperate Real and Imag parts of Radio
                uint32_t dataWord = *(my_periph + XLLF_RDFD_OFFSET);
                int16_t Imag = (int16_t)(dataWord >> 16);
                int16_t Real = (int16_t)(dataWord & 0xFFFF);

                //seperate real and imaginary parts for little endian format (Imag, Real)
                packet[index++] = Imag & 0xFF;
                packet[index++] = (Imag >> 8) & 0xFF;
                packet[index++] = Real & 0xFF;
                packet[index++] = (Real >> 8) & 0xFF;

                wordCount++;
            }
        }

        ssize_t sent = sendto(sockfd, packet, PACKET_MAX, 0, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
        if (sent < 0)
        {
            perror("sendto failed");
            break;
        }

        printf("Sent packet %u (%ld bytes)\n", packetCounter, sent);
        packetCounter++;
    }

    close(sockfd);
}

int main(int argc, char *argv[])
{
    if (argc < 3) 
    {
        printf("Usage: %s <destination ip> <packet amount>\n", argv[0]);
        return 1;
    }

    // Store and verify input sample count
    int packets = atoi(argv[2]);
    if (packets <= 0)
    {   
        printf("Invalid packet amount.\n");
        return 1;   
    }

    //store and verify input ip address
    char* destIP = argv[1];
    struct in_addr ip_check;
    if (inet_pton(AF_INET, destIP, &ip_check) != 1) 
    {
        fprintf(stderr, "Invalid IP address: %s\n", destIP);
        return 1;
    }

    // first, get a pointer to the peripheral base address using /dev/mem and the function mmap
    volatile unsigned int *my_periph = get_a_pointer(FIFO_BASEADDR);

    configureRadio();
    sendUDP(&ip_check, my_periph, packets);

    return 0;
}
