# linux_intro_lab
Starting with Lab 9 we will be moving to using Linux to boot and configure the FPGA.
The design flow of using Linux will be the following:
    1. Connect to TeraTerm (or other UART terminal)
    2. Establish Ethernet Connection
        a. Option 1: Connect Zybo ethernet port with home router
        b. Option 2 Connect Zybo ethernet port to PC
    3. Boot with provided Linux SD Image (content from vfat-image folder copied to an SD card)
    4. Post boot UART will auto login as root
    5. (If you chose step 2b) Establish ssh connection by doing the following:
        a. In UART terminal, run ip addr add 192.168.1.2/24 dev eth0        #This sets an ip address for the Zybo
        b. Run ifconfig to verify IP address added
        c. Set IP address of PC-Zybo ethernet connection to 192.168.1.3
        d. Run ipconfig on PC to verify connection
    6. Program the FPGA by doing the following:
        a. cd into SD card directory: cd /run/media/<hit tab>
        b. run: fpgautil -b design_1_wrapper.bit.bin

Important Mentions:
    You will not automatically hear sound from the codec since unlike Vitis C code the CODEC is not yet configured! Run ./configure_codec.sh (which is on the SD card) to configure the CODEC.

    Use devmem library to directly access peripherals such as GPIO.
    Use command " devmem [address] w [hex/int value] " to write to address
    Use command " devmem [address] w " to read from address

Getting started with making Vivado project and generating .bit.bin file

1. Run make_project.bat or make_project.sh (linux) to:
    • Construct the vivado project
    • Add sources to the project
    • Draw the block diagram and set all the IP settings
    • Synthesize, Place + Route the design
    • Generate a bitfile
    • Convert the bitfile to a .bit.bin for later use by fpgautil

2. Make any modifications to the project through the .xpr file in the generated vivado folder

3. Generate .bit.bin by running make_bitbin.bat or make_bitbin.sh (linux)

