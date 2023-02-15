`timescale 1ns / 1ps
module top(
    input               clk_i,      // �������� ������
                        resetn_i,   // ���������� ������ ������ � �������� ������� LOW
                        request_i,  // ������ ������� �� ������ ����������
                        ack_i,      // ������ ������������� ������ ������������� ������
                [127:0] data_i,     // ��������� ������

    output              busy_o,     // ������, ���������� � ������������� �����
                                    // ���������� ������� �� ����������, ���������
                                    // ������ � �������� ���������� �����������
                                    // �������
           reg          valid_o,    // ������ ���������� ������������� ������
           reg  [127:0] data_o      // ������������� ������
);

reg [127:0] key_mem [0:9]; // ����� �� 10 ������ 

reg [7:0] S_box_mem [0:255]; // ������� ��� �����������

reg [7:0] L_mul_16_mem  [0:255]; // ������� ���������
reg [7:0] L_mul_32_mem  [0:255];
reg [7:0] L_mul_133_mem [0:255];
reg [7:0] L_mul_148_mem [0:255];
reg [7:0] L_mul_192_mem [0:255];
reg [7:0] L_mul_194_mem [0:255];
reg [7:0] L_mul_251_mem [0:255];

initial begin
    $readmemh("keys.mem",key_mem );
    $readmemh("S_box.mem",S_box_mem );

    $readmemh("L_16.mem", L_mul_16_mem );
    $readmemh("L_32.mem", L_mul_32_mem );
    $readmemh("L_133.mem",L_mul_133_mem);
    $readmemh("L_148.mem",L_mul_148_mem);
    $readmemh("L_192.mem",L_mul_192_mem);
    $readmemh("L_194.mem",L_mul_194_mem);
    $readmemh("L_251.mem",L_mul_251_mem);
end

logic [3:0] state;
parameter IDLE = 0, KEY = 1, S = 2, L = 3, FINISH = 4;

logic [3:0] round;
logic [127:0] temp_data;
logic [127:0] xored_data;

logic [7:0] data_key_result_bytes [15:0];
logic [7:0] data_linear_result    [15:0];

logic [4:0] counter;
logic [7:0] data_galua_result [15:0];
logic [7:0] galua_summ;

logic [7:0] data_galua_shifted  [15:0];
          
initial begin
    state <= IDLE;
    round <= 0;
    temp_data = 0;
    xored_data = 0;
    counter <= 0;
end

always_ff @(posedge clk_i or negedge resetn_i) begin
    if (~resetn_i) begin
        // temp_data = 0;
        state <= IDLE;
    end else begin
        case(state)
        IDLE: begin
            if (request_i) begin
                temp_data <= data_i;
                counter <= 0;
                state <= KEY;
            end
        end
        KEY: begin
            xored_data <= temp_data ^ key_mem[round];
            
            data_key_result_bytes[0] <= xored_data[7:0];
            data_key_result_bytes[1] <= xored_data[15:8];
            data_key_result_bytes[2] <= xored_data[23:16];
            data_key_result_bytes[3] <= xored_data[31:24];
            data_key_result_bytes[4] <= xored_data[39:32];
            data_key_result_bytes[5] <= xored_data[47:40];
            data_key_result_bytes[6] <= xored_data[55:48];
            data_key_result_bytes[7] <= xored_data[63:56];
            data_key_result_bytes[8] <= xored_data[71:64];
            data_key_result_bytes[9] <= xored_data[79:72];
            data_key_result_bytes[10] <= xored_data[87:80];
            data_key_result_bytes[11] <= xored_data[95:88];
            data_key_result_bytes[12] <= xored_data[103:0];
            data_key_result_bytes[13] <= xored_data[111:0];
            data_key_result_bytes[14] <= xored_data[119:0];
            data_key_result_bytes[15] <= xored_data[127:0];
            
            if (round == 8) begin
                state <= FINISH;
            end
        end
        S: begin
            data_linear_result[0] <= S_box_mem[data_key_result_bytes[0]];
            data_linear_result[1] <= S_box_mem[data_key_result_bytes[1]]; 
            data_linear_result[2] <= S_box_mem[data_key_result_bytes[2]]; 
            data_linear_result[3] <= S_box_mem[data_key_result_bytes[3]]; 
            data_linear_result[4] <= S_box_mem[data_key_result_bytes[4]]; 
            data_linear_result[5] <= S_box_mem[data_key_result_bytes[5]]; 
            data_linear_result[6] <= S_box_mem[data_key_result_bytes[6]]; 
            data_linear_result[7] <= S_box_mem[data_key_result_bytes[7]]; 
            data_linear_result[8] <= S_box_mem[data_key_result_bytes[8]]; 
            data_linear_result[9] <= S_box_mem[data_key_result_bytes[9]]; 
            data_linear_result[10] <= S_box_mem[data_key_result_bytes[10]]; 
            data_linear_result[11] <= S_box_mem[data_key_result_bytes[11]]; 
            data_linear_result[12] <= S_box_mem[data_key_result_bytes[12]]; 
            data_linear_result[13] <= S_box_mem[data_key_result_bytes[13]]; 
            data_linear_result[14] <= S_box_mem[data_key_result_bytes[14]];
            data_linear_result[15] <= S_box_mem[data_key_result_bytes[15]];
            
            state <= L;   
        end
        L: begin
            if (counter < 16) begin
                data_galua_result[15] = L_mul_148_mem [data_linear_result[0]];
                data_galua_result[14] = L_mul_32_mem  [data_linear_result[1]]; 
                data_galua_result[13] = L_mul_133_mem [data_linear_result[2]]; 
                data_galua_result[12] = L_mul_16_mem  [data_linear_result[3]]; 
                data_galua_result[11] = L_mul_194_mem [data_linear_result[4]]; 
                data_galua_result[10] = L_mul_192_mem [data_linear_result[5]]; 
                data_galua_result[9]  =                data_linear_result[6] ;
                data_galua_result[8]  = L_mul_251_mem [data_linear_result[7]]; 
                data_galua_result[7]  =                data_linear_result[8] ;
                data_galua_result[6]  = L_mul_192_mem [data_linear_result[9]]; 
                data_galua_result[5]  = L_mul_194_mem [data_linear_result[10]]; 
                data_galua_result[4]  = L_mul_16_mem  [data_linear_result[11]]; 
                data_galua_result[3]  = L_mul_133_mem [data_linear_result[12]]; 
                data_galua_result[2]  = L_mul_32_mem  [data_linear_result[13]]; 
                data_galua_result[1]  = L_mul_148_mem [data_linear_result[14]]; 
                data_galua_result[0]  =                data_linear_result[15] ;
                
                galua_summ <= data_galua_result[0] ^ data_galua_result[1] ^ data_galua_result[2] ^ data_galua_result[3] ^ data_galua_result[4] ^ data_galua_result[5] ^ data_galua_result[6] ^ data_galua_result[7] ^ data_galua_result[8] ^ data_galua_result[9] ^ data_galua_result[10] ^ data_galua_result[11] ^ data_galua_result[12] ^ data_galua_result[13] ^ data_galua_result[14] ^ data_galua_result[15];
                
                data_galua_shifted <= {galua_summ, data_galua_result[14:0]};
                
                counter <= counter + 1;
            end else begin
                state <= KEY;
            end
        end
        FINISH: begin
        
        end
        endcase
    end
end

















endmodule
