onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 15 -radix hexadecimal /rab_tb/DUT/axi_rab_top_i/Clk_CI
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_araddr
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_arvalid
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_awaddr
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_awvalid
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_wdata
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_wlast
add wave -noupdate -height 15 /rab_tb/DUT/s_axi_wvalid
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
quietly WaveActivateNextPane
add wave -noupdate -height 15 /rab_tb/DUT/intr_miss_o
add wave -noupdate -height 15 /rab_tb/DUT/intr_prot_o
add wave -noupdate -height 15 /rab_tb/DUT/intr_rab_multi
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_araddr
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_arvalid
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_awaddr
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_awvalid
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_wdata
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_wlast
add wave -noupdate -height 15 /rab_tb/DUT/m_axi_wvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {88947739 ps} 0}
configure wave -namecolwidth 483
configure wave -valuecolwidth 118
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {88873103 ps} {89042886 ps}
