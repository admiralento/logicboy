restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

#Reseting and initializing
add_force reset 1
add_force window_x -radix dec 248
add_force window_y -radix dec 0
run 10ns
add_force reset 0
add_force start 1
run 10ns

#Simulting all data wiped to zeros
add_force -radix hex rd_data 00
run 1600ns

#PASSED TILE WAVEFORM - NOV 25, 2019
#WindowXY in origin, all read data 0's

run 30us

#X and Y wrapping correctly when hits end of screen
#draw turns off corretcly when out of frame
#tile data read address moves by 2 correctly
#when window is from tile grid lines, draw is moudlated correctly

#NOT CORRECT WRAPPING AROUND EDGES OF TILEMAP
