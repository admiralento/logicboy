restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reset
add_force reset 1
run 50ns
add_force reset 0
run 50ns

#Assign Inputs
add_force sw -radix hex FFFF
add_force buttons -radix hex CC

#Begin
add_force start 1
run 300ns

