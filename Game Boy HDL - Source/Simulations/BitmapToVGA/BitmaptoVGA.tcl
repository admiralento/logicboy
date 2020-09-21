restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
add_force clk_vga {0} {1 20} -repeat_every 40
add_force rd_data -radix hex 0
run 80ns

#Reseting and initializing
add_force reset 1
run 100ns
add_force reset 0
run 40ms

