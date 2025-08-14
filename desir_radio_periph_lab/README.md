# radio_periph_lab
Lab 11 is the final lab and extends lab 10 (which was the completed radio_periphal).
This lab takes the radio periphal and adds the following capabilities:
    - PS to retrieve output data from the radio peripheral, and stream that data via. Gbit Ethernet to a connected computer. (PS -> UDP) 
    - Command and control of the radio via a web-browser, rather than via serial commands

The web.tgz file includes the following content:
    a. Configure_codec.sh
    b. Lab 11 .bit.bin file
    c. UDP streamer program
        i.  A callable C program in C which runs continuously, monitoring the contents of the FIFO,
            and, if UDP streaming enabled, sending data from the FIFO via UDP to a provided configurable IP address. 
    d. Scripts/Programs necessary for enabling the web interface to:
        i. Intialize the setup (load your .bit.bin, configure the codec, and start the udp streamer software)
        ii. Configure the Radio Periphal settings: Fake ADC & Tune Frequencies, and enabling/disabling UDP stream feature (enabling/disabling FIFO from receiving data)
        iii. Run milestones 1 & 2 - testing fifo and UDP streaming components only
        iv. Run test_radio.c (from lab 10) 

To run index.html and access web-browser, do the following:
1) Download the web.tgz and copy it to your board via linux. (/home/student, /home/root, or SD card location)
2) Unzip the archive with the following command: “tar -xvf web.tgz”.
3) Within the "web" folder, run this command: “sudo httpd -p 8080 .” This will allow the index.html to be accessible in browser at “your_zybo_ip:8080”
