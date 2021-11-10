# TestFifo
* ModeSim
This is a test scenarios for Inter/Altera SCFIFO behavior.
For the details go [HERE](http://blogs.plymouth.ac.uk/embedded-systems/fpga-and-vhdl/testing-understanding-the-scfifo-megafunction/).
* Vivado
This is a test scenarios for VIVADO xpm_fifo_sync behavior.


Xilinx: Normal FIFO

asserting empty from rdreq and deasserting it from wrreq has a latency of 1 clock cycle.

asserting full from wrreq and deasserting it from rereq has a latency of 1 clock cycle.

usedw or rd/wr_data_count updates after 2 clock cycle after rdreq or wrreq 

when usedw=7 it means that there are 8 words writen in the memory

when usedw=6 it means that there are 7 words writen in the memory

when usedw=5 it means that there are 6 words writen in the memory

when usedw=4 it means that there are 5 words writen in the memory

*when almost_full value=7, usedw=7, almost_full=1 it means that there are 8 words available in the memory

when almost_full value=7, usedw=6, almost_full=0 it means that there are 5 words available in the memory

when almost_empty value=6, usedw=7, almost_empty=0 it means that there are 8 words available in the memory

*when almost_empty value=6, usedw=6, almost_empty=1 it means that there are 5 words available in the memory




Intel: Normal FIFO

asserting empty from rdreq and deasserting it from wrreq has a latency of 1 clock cycle.

asserting full from wrreq and deasserting it from rereq has a latency of 1 clock cycle.

usedw or rd/wr_data_count updates after 2 clock cycle after rdreq or wrreq 

when usedw=6 it means that there are 6 words writen in the memory

when usedw=7 it means that there are 7 words writen in the memory

*when almost_full value=7, usedw=7, almost_full=1 it means that there are 7 words available in the memory

when almost_full value=7, usedw=6, almost_full=0 it means that there are 6 words available in the memory

when almost_empty value=6, usedw=6, almost_empty=0 it means that there are 6 words available in the memory

*when almost_empty value=6, usedw=5, almost_empty=1 it means that there are 5 words available in the memory
