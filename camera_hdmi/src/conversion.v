module RAW10_to_RGB565 (
    input wire clk,                 // Clock signal
    input wire rst,                 // Reset signal
    input wire [9:0] PIXDATA,       // RAW10 pixel data input
    input wire href,                // Horizontal reference signal (row validity)
    input wire vsync,               // Vertical sync signal (frame validity)
    output reg [15:0] RGB565,       // RGB565 output
    output reg valid_out,           // Output valid signal
    output reg href_out,            // Output href for 160x120
    output reg vsync_out            // Output vsync for 160x120
);

    // Parameters for input and output dimensions
    parameter IN_WIDTH = 800;       // Input resolution width
    parameter IN_HEIGHT = 600;      // Input resolution height
    parameter OUT_WIDTH = 160;      // Output resolution width
    parameter OUT_HEIGHT = 120;     // Output resolution height
    parameter DOWNSAMPLE_FACTOR = 5; // Downsampling factor (5x in both directions)

    // Counters for input resolution
    reg [10:0] h_count;             // Horizontal pixel counter
    reg [10:0] v_count;             // Vertical row counter

    // Line buffer for downsampling
    reg [9:0] curr_pixel;

    // Output pixel counters
    reg [7:0] out_col;              // Output column counter
    reg [7:0] out_row;              // Output row counter

    // Sync generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all counters and signals
            h_count <= 0;
            v_count <= 0;
            out_col <= 0;
            out_row <= 0;
            href_out <= 0;
            vsync_out <= 0;
            valid_out <= 0;
        end else begin
            if (vsync) begin
                // Reset counters at the start of a frame
                h_count <= 0;
                v_count <= 0;
                out_col <= 0;
                out_row <= 0;
                vsync_out <= 1;
            end else begin
                vsync_out <= 0;
                if (href) begin
                    // Increment horizontal counter during active row
                    h_count <= h_count + 1;

                    // Downsample horizontally
                    if (h_count % DOWNSAMPLE_FACTOR == 0) begin
                        curr_pixel <= PIXDATA; // Capture input pixel
                        valid_out <= 1;

                        // Update output column counter
                        if (out_col == OUT_WIDTH - 1) begin
                            out_col <= 0;
                        end else begin
                            out_col <= out_col + 1;
                        end
                    end else begin
                        valid_out <= 0;
                    end

                    // Regenerate href for output
                    if (h_count < (OUT_WIDTH * DOWNSAMPLE_FACTOR))
                        href_out <= 1;
                    else
                        href_out <= 0;

                end else begin
                    // Reset horizontal counter at the end of a row
                    h_count <= 0;
                    href_out <= 0;

                    // Increment vertical counter
                    if (v_count < IN_HEIGHT - 1) begin
                        v_count <= v_count + 1;
                    end else begin
                        v_count <= 0;
                    end

                    // Downsample vertically
                    if (v_count % DOWNSAMPLE_FACTOR == 0) begin
                        if (out_row == OUT_HEIGHT - 1) begin
                            out_row <= 0;
                        end else begin
                            out_row <= out_row + 1;
                        end
                    end
                end
            end
        end
    end

    // RGB Conversion (Directly output the current pixel as RGB565)
    always @(posedge clk) begin
        RGB565 <= {curr_pixel[9:5], curr_pixel[9:4], curr_pixel[9:5]}; // Scale to RGB565
    end
endmodule
