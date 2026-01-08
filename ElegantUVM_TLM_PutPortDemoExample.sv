//*************************************************************************************************
//  BASIC PUT PORT-IMP Example Demo : BLOCKING PUT Interface Method "put()"
//*************************************************************************************************
// 1. This can be executed directly as a single file in EDA playground 
// 2. Demonstrates how calling a put() method on a component(txPacket) execute implementaion inside
//  another component (rxPacket)
//**************************************************************************************************
`include "uvm_macros.svh";

package tlmExamples;
    import uvm_pkg ::*;

class item extends uvm_object;
    `uvm_object_utils_begin(item)
    `uvm_field_int(a, UVM_ALL_ON)
    `uvm_field_int(b, UVM_ALL_ON)
    `uvm_field_int(c, UVM_ALL_ON)
    `uvm_object_utils_end

    rand int a;
    rand int b;
    rand int c;

    constraint ct{a<100; b<100; c<100;}

    function new(string name = "item");
        super.new(name);
    endfunction


endclass : item


//Transmitter component
class txPacket extends uvm_component;
    `uvm_component_utils(txPacket)

    //----------------------------------------
    uvm_blocking_put_port #(item) txPutPort;
    item txItem;
    //-----------------------------------------
    function new(string name = "txPacket", uvm_component parent);
        super.new(name, parent);
        txPutPort = new("txPutPort", this);
      txItem = item ::type_id :: create("txItem");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.run_phase(phase);
            repeat(5)begin
                void'(txItem.randomize());
                `uvm_info(get_full_name(), "------------ Tx packet init---------", UVM_NONE);
                txItem.print();
                txPutPort.put(txItem);
                `uvm_info(get_full_name(), "------------ Tx packet done---------", UVM_NONE);
            end
        phase.drop_objection(this);

    endtask : run_phase

endclass : txPacket


// Recevier compoent;

class rxPacket extends uvm_component;
    `uvm_component_utils(rxPacket)
    //----------------------------------------
  	uvm_blocking_put_imp #(item, rxPacket) rxPutImp;
    //-----------------------------------------
    function new(string name = "txPacket", uvm_component parent);
        super.new(name, parent);
        rxPutImp = new("rxPutImp", this);
    endfunction
	
  // implement TLM Interface task :: put();
    virtual task put(item rxItem);
        `uvm_info(get_full_name(), "********rxItem started******", UVM_NONE);
        rxItem.print();
        `uvm_info(get_full_name(), "********rxItem finished******", UVM_NONE);
    endtask

endclass : rxPacket

//base test 
class baseTest extends uvm_test;
    `uvm_component_utils(baseTest)

    txPacket txPac;
    rxPacket rxPac;

    function new(string name = "baseTest", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        txPac = txPacket :: type_id :: create("txPac", this);
        rxPac = rxPacket :: type_id :: create("rxPac", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        txPac.txPutPort.connect(rxPac.rxPutImp);
    endfunction

endclass : baseTest

class putPortTest extends baseTest;
  `uvm_component_utils(putPortTest)
      
  function new(string name = "putPortTest", uvm_component parent);
      super.new(name, parent);
 endfunction
  
endclass : putPortTest

endpackage : tlmExamples


module tbTop;
  
  import uvm_pkg ::*;
  import tlmExamples::*;
  
  initial run_test("putPortTest");
  
  
endmodule
