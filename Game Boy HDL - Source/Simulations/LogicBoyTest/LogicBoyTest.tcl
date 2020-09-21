restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reseting and initializing
add_force CPU_RESETN 0
run 100ns
add_force CPU_RESETN 1
add_force -radix hex sw AB35
add_force btnc 0
add_force btnd 1
add_force btnu 1
add_force btnl 0
add_force btnr 0
run 100us
add_force -radix hex sw 15F0
run 2ms

