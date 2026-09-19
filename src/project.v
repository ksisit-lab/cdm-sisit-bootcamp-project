/*
 * Copyright (c) 2026 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_lfsr_cipher (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Prevent lint warnings for unused signals
    wire _unused = &{ena, uio_in, 1'b0};

    // Tie off bidirectional IOs to be inputs (0 = input, 1 = output)
    assign uio_oe  = 8'b0000_0000;
    assign uio_out = 8'b0000_0000;

    // 4-bit LFSR state register
    reg [3:0] lfsr_state;

    // Feedback polynomial for 4-bit LFSR: x^4 + x^3 + 1
    // Taps at bit 3 and bit 2 (0-indexed)
    wire feedback = lfsr_state[3] ^ lfsr_state[2];

    always @(posedge clk) begin
        if (!rst_n) begin
            // Seed the LFSR using the secret key (ui_in[7:4]) on reset.
            // An LFSR locks up if its state is all zeros. This ternary operator 
            // ensures that if the user inputs a key of 0000, it defaults to 0001.
            lfsr_state <= (ui_in[7:4] == 4'b0000) ? 4'b0001 : ui_in[7:4];
        end else begin
            // Shift left and insert feedback at the LSB
            lfsr_state <= {lfsr_state[2:0], feedback};
        end
    end

    // Stream cipher logic: XOR raw data (ui_in[3:0]) with the pseudorandom LFSR state
    wire [3:0] ciphertext = ui_in[3:0] ^ lfsr_state;

    // Route ciphertext to the lower 4 bits of the output (uo_out[3:0])
    // Route the current LFSR state to the upper 4 bits (uo_out[7:4]) for debugging/observability
    assign uo_out = {lfsr_state, ciphertext};

endmodule
