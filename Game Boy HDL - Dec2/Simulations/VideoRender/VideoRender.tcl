restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reseting and initializing
add_force CPU_RESETN 0
run 10ns
add_force CPU_RESETN 1
run 500us