module kuznechik_cipher(
    input               clk_i,      // Тактовый сигнал
                        resetn_i,   // Синхронный сигнал сброса с активным уровнем LOW
                        request_i,  // Сигнал запроса на начало шифрования
                        ack_i,      // Сигнал подтверждения приема зашифрованных данных
                [127:0] data_i,     // Шифруемые данные

    output              busy_o,     // Сигнал, сообщающий о невозможности приёма
                                    // очередного запроса на шифрование, поскольку
                                    // модуль в процессе шифрования предыдущего
                                    // запроса
           reg          valid_o,    // Сигнал готовности зашифрованных данных
           reg  [127:0] data_o      // Зашифрованные данные
);

reg [127:0] key_mem [0:9];

reg [7:0] S_box_mem [0:255];

reg [7:0] L_mul_16_mem  [0:255];
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


  logic [3:0]   trial_num_ff;
  logic [127:0] trial_input_mux;

  logic [127:0] trial_output;

  assign trial_num_ff = '0;

  assign trial_input_mux = (trial_num_ff == 0) ? data_i
                         :                       trial_output ;

  // Key overlay
  logic [127:0] round_key;
  assign round_key = key_mem[trial_num_ff];

  logic [127:0] data_key_result;

  assign data_key_result = trial_input_mux ^ round_key;

  // Linear overlay
  logic [7:0] data_key_result_bytes [15:0];
  logic [7:0] data_linear_result    [15:0];

  generate;
    for (genvar i=0; i<16; i++) begin
      assign data_key_result_bytes[i] = data_key_result[((i+1)*8)-1:(i*8)];
      assign data_linear_result   [i] = S_box_mem[data_key_result_bytes[i]];
    end
  endgenerate


  // Galua overlay

  logic [7:0] data_galua_in [15:0];
  logic       data_galua_sel;


  // Stub! Shift register should be added here
  assign data_galua_in = data_linear_result;

  logic [7:0] data_galua_result [15:0];

  // 148, 32, 133, 16, 194, 192, 1, 251, 1, 192, 194, 16, 133, 32, 148, 1
  assign data_galua_result[15] = L_mul_148_mem [data_galua_in[0]];
  assign data_galua_result[14] = L_mul_32_mem  [data_galua_in[1]]; 
  assign data_galua_result[13] = L_mul_133_mem [data_galua_in[2]]; 
  assign data_galua_result[12] = L_mul_16_mem  [data_galua_in[3]]; 
  assign data_galua_result[11] = L_mul_194_mem [data_galua_in[4]]; 
  assign data_galua_result[10] = L_mul_192_mem [data_galua_in[5]]; 
  assign data_galua_result[9]  =                data_galua_in[6] ;
  assign data_galua_result[8]  = L_mul_251_mem [data_galua_in[7]]; 
  assign data_galua_result[7]  =                data_galua_in[8] ;
  assign data_galua_result[6]  = L_mul_192_mem [data_galua_in[9]]; 
  assign data_galua_result[5]  = L_mul_194_mem [data_galua_in[10]]; 
  assign data_galua_result[4]  = L_mul_16_mem  [data_galua_in[11]]; 
  assign data_galua_result[3]  = L_mul_133_mem [data_galua_in[12]]; 
  assign data_galua_result[2]  = L_mul_32_mem  [data_galua_in[13]]; 
  assign data_galua_result[1]  = L_mul_148_mem [data_galua_in[14]]; 
  assign data_galua_result[0]  =                data_galua_in[15] ;

  logic [7:0] galua_summ;

  logic [7:0] data_galua_shreg_ff   [15:0];
  logic [7:0] data_galua_shreg_next [15:0];
  logic       data_galua_shreg_en;

  generate;

    always_comb begin
      galua_summ = '0;
      for (int i = 0; i < 16; i++)
        galua_summ = galua_summ ^ data_galua_result[i];
    end


    always_comb begin
      data_galua_shreg_next[15] = galua_summ;
      for (int i = 14; i >= 0; i--)
        data_galua_shreg_next[i] = data_galua_shreg_ff[i+1];
    end


    for (genvar i = 0; i < 16; i++) begin
      always_ff @(posedge clk_i or negedge resetn_i) begin
        if (~resetn_i)
          data_galua_shreg_ff[i] = '0;
        else if (data_galua_shreg_en)
          data_galua_shreg_ff[i] = data_galua_shreg_next[i];
      end
    end

    for (genvar i = 0; i < 16; i++)
      assign trial_output[((i+1)*8)-1:(i*8)] = data_galua_shreg_ff[i];

  endgenerate




endmodule
