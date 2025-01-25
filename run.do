vlib work

#compile design and tb
vlog fifo.sv tb_fifo.sv

#simulate tb
vsim tb_fifo

#add all waves
do wave.do

#run
run -all
