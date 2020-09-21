restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reseting and initializing
add_force reset 1
add_force start 0
run 10ns
add_force reset 0
add_force start 1
run 300us

#SIMULATION DEC2
#Module hanging because cycleCount overflowed, killing logic tree
#Also byteCount was compared to a 9-bit quantity, changed from 256 to 0

#Reached the finished state

#Writes settings correctly to VRAM
#Writes the sprite data correctly to VRAM
#Writes pointer data correctly to VRAM

#Byte counter stopping at 256, not at 2048 due to not enough bits
#Still not enough cycle bits, changed both byte and cycle to 16-bit numbers, let the complier take care of the extra
#Now it writes ALL the pointer data and reaches the finished state
