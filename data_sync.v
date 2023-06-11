module data_sync #(
    parameter NUM_STAGES=2,
    BUS_WIDTH = 8
) (
    input [BUS_WIDTH-1 : 0] Unsync_bus,
    input bus_enable,

    input clk, reset,

    output  [BUS_WIDTH-1 : 0] sync_bus,
    output  enable_pulse
);

integer i;

reg [NUM_STAGES-1 : 0] sync_flops;
reg pulse_flop;

wire [BUS_WIDTH-1 : 0] o_data;
wire enable_mux;

assign o_data = (enable_mux) ? Unsync_bus: sync_bus;
assign enable_mux = (~(pulse_flop)) & sync_flops[NUM_STAGES-1];

assign sync_bus     = o_data;
assign enable_pulse = enable_mux;

// always @(posedge clk or negedge reset) 
// begin
//     if(!reset)
//     begin
//         sync_bus <= 0;
//         enable_pulse <= 0;
//     end

//     else
//     begin
//         sync_bus <= o_data;
//         enable_pulse <= enable_mux;
//     end
// end

always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        for(i=0; i<NUM_STAGES ; i=i+1)
        begin
            sync_flops[i] <= 0;
        end
        pulse_flop <= 0;
    end

    else
    begin
        sync_flops[0] <= bus_enable;
        for(i=1; i<NUM_STAGES ; i=i+1)
        begin
            sync_flops[i] <= sync_flops[i-1];
        end

        pulse_flop <= sync_flops [NUM_STAGES-1] ;
    end
    
end

endmodule