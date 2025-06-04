Engineer: E. Desir
University: JHU EP
Semester: Summer 2025

Overview:    This git project stores the files and logs of a Software Defined Radio VHDL project 
             which is implemented using the Zybo Z7 (Zynq 7020) development board. This radio will 
             be designed following a System on a Chip (SoC) process, pulling elements such as a                 processor, UART, Xilinx IPs, and FPGA I/O ports to design a system. The top level  
             diagram for this system is shown below.

![image](https://github.com/user-attachments/assets/decf0037-e2b3-411b-95ae-14422c09a018)

This READ ME file will contain in depth information of how the system was developed throughout the semester. The following descriptions provide details on each component for the system, their purpose, and the design method. 

- The Zynq PS7 allows us to implement I/O and Xilinx IP components using C. It contains a dual-core ARM Cortex-A9 CPU which will allow for our communication with AXI. 
- The DAC Interface allows for connections to Digital Signal Processing (DSP) components 
