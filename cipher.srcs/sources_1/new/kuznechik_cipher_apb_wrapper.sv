module kuznechik_cipher_apb_wrapper(

    // Clock
    input  logic            pclk_i,

    // Reset
    input  logic            presetn_i,

    // Address
    input  logic     [31:0] paddr_i,

    // Control-status
    input  logic            psel_i,
    input  logic            penable_i,
    input  logic            pwrite_i,

    // Write
    input  logic [3:0][7:0] pwdata_i,
    input  logic      [3:0] pstrb_i,

    // Slave
    output logic            pready_o,
    output logic     [31:0] prdata_o,
    output logic            pslverr_o

);

    ////////////////////
    // Design package //
    ////////////////////

    import kuznechik_cipher_apb_wrapper_pkg::*;


    //////////////////////////
    // Cipher instantiation //
    //////////////////////////


    // Instantiation
    kuznechik_cipher cipher(
        .clk_i      (    ),
        .resetn_i   (    ),
        .request_i  (    ),
        .ack_i      (    ),
        .data_i     (    ),
        .busy_o     (    ),
        .valid_o    (    ),
        .data_o     (    )
    );




endmodule