module instruction_memory #(
    parameter XLEN       = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 1024,
    parameter INIT_FILE  = ""
  ) (
    input wire [ADDR_WIDTH-1:0] addr,
    output wire [XLEN-1:0]      instr
  );

  localparam INDEX_WIDTH = $clog2(MEM_DEPTH);

  reg [XLEN-1:0] mem [0:MEM_DEPTH-1];

  initial
  begin
    if (INIT_FILE != "")
    begin
      $readmemh(INIT_FILE, mem);
    end
    else
    begin
      integer i;
      for (i = 0; i < MEM_DEPTH; i = i + 1)
      begin
        mem[i] = {XLEN{1'b0}};
      end
      $display("Instruction Memory initialized with default values (no INIT_FILE specified).");
    end
  end

  wire [INDEX_WIDTH-1:0] word_index;

  if (ADDR_WIDTH < 2)
  begin
    assign word_index = 0;
    initial
      $display("Warning: ADDR_WIDTH < 2 in instruction_memory");
  end
  else
  begin
    assign word_index = addr[INDEX_WIDTH+1:2];
  end

  assign instr = mem[word_index];

endmodule
