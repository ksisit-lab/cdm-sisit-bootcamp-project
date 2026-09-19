`default_nettype none

module tt_um_crypto_cipher (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // We split the 8 input switches into two groups of 4:
    // Pins 1-4 (ui_in[3:0]) act as our secret encryption key.
    // Pins 5-8 (ui_in[7:4]) act as the raw data we want to encrypt.
    wire [3:0] secret_key = ui_in[3:0];
    wire [3:0] raw_data   = ui_in[7:4];
    
    // This is the hardware memory (Linear Feedback Shift Register)
    // that will generate our pseudo-random scrambling sequence.
    reg [3:0] keystream;
    
    // The hardware clock block. It triggers on every clock pulse.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // When the reset button is pushed, load the secret key into the memory
            keystream <= secret_key; 
        end else begin
            // On every clock pulse, mathematically shift and scramble the bits.
            // We use an XOR gate (^) on bits 3 and 2 to create continuous randomness.
            keystream <= {keystream[2:0], keystream[3] ^ keystream[2]};
        end
    end

    // The encryption engine: 
    // We XOR our raw data with the randomized keystream to create the ciphertext.
    wire [3:0] encrypted_data = raw_data ^ keystream;

    // We send our encrypted data to the lower 4 output pins.
    // We send the shifting keystream to the upper 4 pins so judges can see the math happening.
    assign uo_out = {keystream, encrypted_data};

    // We must tie off the unused bidirectional pins to zero so the factory doesn't throw an error.
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // We list unused mandatory pins here so the compiler ignores them safely.
    wire _unused = &{ena, 1'b0, uio_in};

endmodule
