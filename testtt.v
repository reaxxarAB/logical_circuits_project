`timescale 1ns/1ps
`define HIT (1)
`define MISS (0)
`define NULL (32'b00000000000000000000000000000000)

module cache_handler(
        input clk_i,
        input [31:0] addr_i,
        input rst_i,
        input acc_i,
        input we_i,
        input [31:0] wdata_i,
        output reg [31:0] rdata_o,
        output reg hit_miss_o,
        output reg [31:0] accesses_o,
        output reg [31:0] misses_o);


    parameter NUM_LINES = 16;
    parameter NUM_LINES_BITS = 4;
    parameter WORD_PER_LINE = 4;
    parameter WORD_PER_LINE_BITS = 2;
    parameter MEM_SIZE = 1024;

    reg [31:0] line_store[0:NUM_LINES - 1][0:WORD_PER_LINE - 1];
    reg [17:0] line_tag[0:NUM_LINES - 1];
    reg line_valid[0:NUM_LINES - 1];
    reg [7:0] main_mem [0:MEM_SIZE - 1];
    integer idx;
    integer mem_addr_tmp;
    initial
        $readmemb("memory.list", main_mem);
  
  
  
    function is_cached(input [31:0] address);
        begin
            
            if (line_valid[address[7:4]] && (line_tag[address[7:4]] == address[24:8]))
                is_cached = 1;
            else
                is_cached = 0;
        end
    endfunction
   
   
   
    function [31:0] read_line_word(input [3:0]row, input [1:0]column);
        begin
            if (line_valid[row])
                read_line_word = line_store[row][column];
            else
                read_line_word = `NULL;
        end
    endfunction
   
   
   
    function [31:0] compose_mem_addr (input [WORD_PER_LINE_BITS - 1:0]n, input [NUM_LINES_BITS - 1:0]row);
        reg [31:0] addr;
        begin
            addr = line_tag[row];
            addr = addr << 17 | row;
            addr = addr << NUM_LINES_BITS | n;
            addr = addr << 2;
            compose_mem_addr = addr;
        end
    endfunction



    function [31:0] load_line(input [31:0] address);
        integer j;
        begin
            line_valid[address[7:4]] = 1;
            line_tag[address[7:4]] = address[24:8];
            
            for (j = 0; j < WORD_PER_LINE; j = j + 1) begin
                mem_addr_tmp = compose_mem_addr(j, address[7:4]);
                line_store[address[7:4]][j] =
                            {main_mem[mem_addr_tmp + 3], main_mem[mem_addr_tmp + 2], main_mem[mem_addr_tmp + 1], main_mem[mem_addr_tmp]}; //1 Word, 4 Bytes
            end
            load_line = read_line_word(address[7:4], address[3:2]);
        end
    endfunction
    always @(posedge clk_i) begin
        
        if (rst_i) begin
            accesses_o <= 0;
            misses_o <= 0;
            
            for (idx = 0; idx < NUM_LINES; idx = idx + 1)
                line_valid[idx] = 0;
        end
        else
            accesses_o <= accesses_o + 1;
        
        
        if (acc_i) begin
            if (~we_i) begin
                if (is_cached(addr_i)) begin
                    hit_miss_o <= `HIT;
                    rdata_o <= read_line_word(addr_i[7:4], addr_i[3:2]);
                end
                else begin
                    misses_o <= misses_o + 1;
                    hit_miss_o <= `MISS;
                    rdata_o <= load_line(addr_i);
                end
            end
          
          
            else begin
                if (is_cached(addr_i)) begin
                    
                    hit_miss_o <= `HIT;

                 
                    line_store[addr_i[9:5]][addr_i[4:2]] <= wdata_i;

               
                    mem_addr_tmp = compose_mem_addr(addr_i[4:2], addr_i[9:5]);
                    main_mem[mem_addr_tmp] <= wdata_i[7:0];
                    main_mem[mem_addr_tmp + 1] <= wdata_i[15:8];
                    main_mem[mem_addr_tmp + 2] <= wdata_i[23:16];
                    main_mem[mem_addr_tmp + 3] <= wdata_i[31:24];
                end
                else begin
                 
                    misses_o <= misses_o + 1;
                    hit_miss_o <= `MISS;

                 
                    line_valid[addr_i[9:5]] <= 1;
                    line_tag[addr_i[9:5]] <= addr_i[27:10];

                    for (idx = 0; idx < WORD_PER_LINE; idx = idx + 1) begin
                        mem_addr_tmp = compose_mem_addr(idx, addr_i[6:2]);
                        line_store[addr_i[9:5]][idx] <=
                                    {main_mem[mem_addr_tmp + 3], main_mem[mem_addr_tmp + 2],
                                     main_mem[mem_addr_tmp + 1], main_mem[mem_addr_tmp]};
                    end

                   
                    line_store[addr_i[9:5]][addr_i[4:2]] <= wdata_i;

                    mem_addr_tmp = compose_mem_addr(addr_i[4:2], addr_i[9:5]);
                    main_mem[mem_addr_tmp] <= wdata_i[7:0];
                    main_mem[mem_addr_tmp + 1] <= wdata_i[15:8];
                    main_mem[mem_addr_tmp + 2] <= wdata_i[23:16];
                    main_mem[mem_addr_tmp + 3] <= wdata_i[31:24];
                end
            end
        end
    end
endmodule



module Cache_tb;
    
    reg         clk_i;
    reg         rst_i;
    reg         acc_i;
    reg  [31:0] addr_i;
    reg  [31:0] wdata_i;
    reg         we_i;
    wire [31:0] rdata_o;
    wire        hit_miss_o;
    wire [31:0] accesses_o;
    wire [31:0] misses_o;

    
    cache_handler uut (
        .clk_i(clk_i),
        .addr_i(addr_i),
        .rst_i(rst_i),
        .acc_i(acc_i),
        .we_i(we_i),
        .wdata_i(wdata_i),
        .rdata_o(rdata_o),
        .hit_miss_o(hit_miss_o),
        .accesses_o(accesses_o),
        .misses_o(misses_o)
    );

    
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end


    
    task do_access;
        input [31:0] a_addr;
        input        a_we;
        input [31:0] a_wdata;
        begin
            addr_i      = a_addr;
            we_i        = a_we;
            wdata_i     = a_wdata;
            acc_i       = 1;
            @(posedge clk_i);
            acc_i       = 0;
        end
    endtask

    
    initial begin
        
        rst_i        = 1;
        acc_i        = 0;
        addr_i       = 0;
        we_i         = 0;
        wdata_i      = 0;
        
        repeat (2) @(posedge clk_i);
        rst_i = 0;

        
        do_access(32'd0, 1'b0, 32'd0);
        $display("Read Addr=0: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

        
        do_access(32'd0, 1'b0, 32'd0);
        $display("Read Addr=0 again: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

        
        do_access(32'd4, 1'b1, 32'hA5A5A5A5);
        $display("Write Addr=4: Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        do_access(32'd4, 1'b0, 32'd0);
        $display("Read Addr=4: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        do_access(32'd32, 1'b0, 32'd0);
        $display("Read Addr=32: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        do_access(32'd64, 1'b0, 32'd0);
        $display("Read Addr=64: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        do_access(32'd64, 1'b0, 32'd0);
        $display("Read Addr=64: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

        
        do_access(32'd64, 1'b1, 32'hACFD1214);
        $display("Write Addr=64: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        do_access(32'd128, 1'b0, 32'd0);
        $display("Read Addr=128: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);


        do_access(32'd128, 1'b0, 32'd0);
        $display("Read Addr=128: Data_Out=0x%h, Hit_Miss=%s, Acc=%0d, Miss=%0d", 
                rdata_o, hit_miss_o ? "HIT" : "MISS", accesses_o, misses_o);

       
        $display("Final: Accesses=%0d, Misses=%0d, HitRate=%.2f%%", 
                accesses_o, misses_o, ((accesses_o - misses_o) * 100.0) / accesses_o);
        $finish;

    end
endmodule
