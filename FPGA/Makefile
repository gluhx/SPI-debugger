IVERILOG := iverilog
VVP      := vvp
SRC_DIR  := src
TEST_DIR := test
SIM_DIR  := simulation/files

.PHONY: all blink_led uart_baud_generator uart uart_demo uart_demo_phrase uart_demo_leds uart_demo_echo uart_tx uart_rx clean

all: blink_led uart_baud_generator uart uart_demo

$(SIM_DIR):
	mkdir -p $@

blink_led: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/blink_led_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_blink_led.v ./$(SRC_DIR)/blink_led.v
	$(VVP) $(SIM_DIR)/blink_led_dsn
	mv -f ./$(TEST_DIR)/tb_blink_led.vcd $(SIM_DIR)/blink_led_simulation.vcd

uart_baud_generator: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_baud_generator_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_baud_generator.v ./$(SRC_DIR)/uart_baud_generator.v
	$(VVP) $(SIM_DIR)/uart_baud_generator_dsn
	mv -f ./$(TEST_DIR)/tb_uart_baud_generator.vcd $(SIM_DIR)/uart_baud_generator_simulation.vcd

uart: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_UART.v ./$(SRC_DIR)/UART.v ./$(SRC_DIR)/UART_TX.v ./$(SRC_DIR)/uart_baud_generator.v
	$(VVP) $(SIM_DIR)/uart_dsn
	mv -f ./$(TEST_DIR)/tb_UART.vcd $(SIM_DIR)/uart_simulation.vcd

uart_demo: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_demo_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_UART_demo.v ./$(SRC_DIR)/UART_demo.v ./$(SRC_DIR)/UART.v ./$(SRC_DIR)/UART_TX.v ./$(SRC_DIR)/uart_baud_generator.v
	$(VVP) $(SIM_DIR)/uart_demo_dsn
	mv -f ./$(TEST_DIR)/tb_UART_demo.vcd $(SIM_DIR)/uart_demo_simulation.vcd

uart_demo_phrase: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_demo_phrase_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_demo_phrase.v ./$(SRC_DIR)/UART_demo.v ./$(SRC_DIR)/uart_tx.v
	$(VVP) $(SIM_DIR)/uart_demo_phrase_dsn
	mv -f ./test/tb_uart_demo_phrase.vcd $(SIM_DIR)/uart_demo_phrase_simulation.vcd

uart_demo_leds: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_demo_leds_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_demo_leds.v ./$(SRC_DIR)/UART_demo.v ./$(SRC_DIR)/uart_rx.v
	$(VVP) $(SIM_DIR)/uart_demo_leds_dsn
	mv -f ./$(TEST_DIR)/tb_uart_demo_leds.vcd $(SIM_DIR)/uart_demo_leds_simulation.vcd

uart_demo_echo: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_demo_echo_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_demo_echo.v ./$(SRC_DIR)/UART_demo.v ./$(SRC_DIR)/uart_rx.v ./$(SRC_DIR)/uart_tx.v
	$(VVP) $(SIM_DIR)/uart_demo_echo_dsn
	mv -f ./$(TEST_DIR)/tb_uart_demo_echo.vcd $(SIM_DIR)/uart_demo_echo_simulation.vcd

uart_tx: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_tx_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_tx.v ./$(SRC_DIR)/uart_tx.v
	$(VVP) $(SIM_DIR)/uart_tx_dsn
	mv -f ./$(TEST_DIR)/tb_uart_tx.vcd $(SIM_DIR)/uart_tx_simulation.vcd

uart_rx: | $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(SIM_DIR)/uart_rx_dsn -I ./$(SRC_DIR) \
		./$(TEST_DIR)/tb_uart_rx.v ./$(SRC_DIR)/uart_rx.v
	$(VVP) $(SIM_DIR)/uart_rx_dsn
	mv -f ./$(TEST_DIR)/tb_uart_rx.vcd $(SIM_DIR)/uart_rx_simulation.vcd

clean:
	rm -f $(SIM_DIR)/*
