restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reseting
add_force reset 1
add_force wr_en 0
run 10ns
add_force reset 0
run 10ns

#adding testAddress
add_force -radix hex test_addr 242B

#Latching in write address
add_force -radix hex wr_addr 5F
run 10ns
add_force -radix hex wr_addr 27
run 10ns

#Write to write address
add_force -radix hex wr_data 7E
add_force wr_en 1
run 10ns
add_force wr_en 0

#Latching in write address
add_force -radix hex wr_addr 24
run 10ns
add_force -radix hex wr_addr 2B
run 10ns

#Write to write address
add_force -radix hex wr_data 3A
add_force wr_en 1
run 10ns
add_force wr_en 0

#Latching in both read addresses
add_force -radix hex rd_addr1 5F
add_force -radix hex rd_addr2 24
run 10ns
add_force -radix hex rd_addr1 27
add_force -radix hex rd_addr2 2B
run 10ns

#Should see written values at both read address

#PASSED SIMULATION - NOV 25 2019