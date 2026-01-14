
//******************************************************************************************************************************************************************************
// 1) Request Flow : always goes from Port to export to import for both PUT or GET interface
// 2) Data Flow :
// 				a) Put Interface -> Request Starts from port to export(tx-> rx). Data flows from Port to export(tx->rx)
//				b) Get interface -> Request starts from port to export(rx->tx). Data flows from export to port(tx->rx)
//3) HOW TO RUN :: this file is standalone executable on EDA tool
// run Put Port Demo test (elgantUVM_tlmPutPortBasicDemoTest) or Get Port Demo test (elgantUVM_tlmGetPortBasicDemoTest) 
//by commenting/uncommenting run_test() initial blocks tbTop module at bottom of this file 
//******************************************************************************************************************************************************************************

  
`include "uvm_macros.svh";

package basicItemPackage;

	import uvm_pkg ::*;

	//basic uvm transaction item class
	class item extends uvm_sequence_item;
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
		endfunction : new
		
		virtual function string convert2string();
			string s = "";
			$sformat(s, "a is : %d\n b is : %d\n, c is : %d", a, b, c);
          return s;
		endfunction
		
	endclass : item
		
endpackage : basicItemPackage

package elgantUVM_tlmPutGetPortDemoPackage1;
	import uvm_pkg ::*;
	import basicItemPackage::*;
	int i=0;
	// txmodule is Producing a transaction 
	// txModule :: get port :: Req : port(rx) -> imp(tx); data : imp(tx) -> port(rx)
	// implement putCaller task which calls put interface method
	// implements  tlm get() interface task
	class txModule extends uvm_component;
		`uvm_component_utils(txModule)
		item txPutItem;
		item txGetItem;
		uvm_blocking_put_port #(item) txPutPort;
		uvm_blocking_get_imp #(item, txModule) txGetImp;
		bit putCall;

		function new(string name = "txModule", uvm_component parent);
			super.new(name, parent);
			txPutPort = new("txPutPort", this);
			txGetImp = new("txGetImp", this);
		endfunction : new
		//---------------------------------------------------------------------------------------------
		virtual task putCaller();
			if(putCall)begin
				repeat(5)begin
					i+=1;
					void'(txPutItem.randomize());
					`uvm_info(get_full_name(), $sformatf("------------ Sending Tx packet id : %d ------------",i), UVM_NONE);
					txPutItem.print();
					txPutPort.put(txPutItem);
					`uvm_info(get_full_name(), $sformatf("------------ Done Tx packet id : %d ------------",i), UVM_NONE);
				end
			end
		endtask : putCaller
		//---------------------------------------------------------------------------------------------
		virtual task get(output item txGetItem);
			`uvm_info(get_full_name(), $sformatf("------------ started Tx get() tlm interface method call, packet id : %d ------------",i), UVM_NONE);
        	txGetItem = item :: type_id :: create ("txGetItem");
        	void'(txGetItem.randomize());
        	void'(txGetItem.convert2string());
          	txGetItem.print();
        	`uvm_info(get_full_name(), $sformatf("------------ done Tx get() tlm interface methods call, packet id : %d",i), UVM_NONE);
			
          	
		endtask
		//---------------------------------------------------------------------------------------------
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			txPutItem = item :: type_id :: create("txPutItem");
			txGetItem = item :: type_id :: create ("txGetItem");
          	void'(uvm_config_db #(bit) :: get(this, "", "putCall", putCall));
		endfunction
		//---------------------------------------------------------------------------------------------
		task run_phase(uvm_phase phase);
			phase.raise_objection(this);
				super.run_phase(phase);
          		putCaller();
			phase.drop_objection(this);
		endtask : run_phase
		//---------------------------------------------------------------------------------------------
	endclass : txModule
	
	//rxModule
	class rxModule extends uvm_component;
		`uvm_component_utils(rxModule)
		
		uvm_blocking_put_imp #(item, rxModule) rxPutImp;
		uvm_blocking_get_port #(item) rxGetPort;
		item rxPutItem;
		item rxGetItem;
		bit getCall;
		//---------------------------------------------------------------------------------------------
		function new(string name = "rxModule", uvm_component parent);
			super.new(name, parent);
			rxPutImp = new("rxPutImp", this);
			rxGetPort = new("rxGetPort", this);
		endfunction
		//---------------------------------------------------------------------------------------------
		//implement TLM Interface task :: put();
		virtual task put(item rxItem);
			i+=1;
			`uvm_info(get_full_name(), $sformatf("*************** Received Rx packet id : %d *************",i), UVM_NONE);
			rxItem.print();
			`uvm_info(get_full_name(),$sformatf("*************** Finished Rx packet id : %d ***************",i), UVM_NONE);
		endtask
		//---------------------------------------------------------------------------------------------
		virtual task getCaller();
			if(getCall)begin
				repeat(5) begin
					i+=1;
					`uvm_info(get_full_name(), $sformatf("********** started get() method call at rxModule , packet id : %d", i), UVM_NONE);
					rxGetPort.get(rxGetItem);
                  	rxGetItem.print();
					`uvm_info(get_full_name(), $sformatf("********** finished get() method call at rxModule , packet id : %d", i), UVM_NONE);
                  	`uvm_info(get_full_name(), $sformatf("***********done transaction************\n\n\n\n"), UVM_NONE);
				end
			end
		endtask : getCaller
		//---------------------------------------------------------------------------------------------
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			rxPutItem = item :: type_id :: create("rxPutItem");
			rxGetItem = item :: type_id :: create("rxGetItem");
          	void'(uvm_config_db #(bit) :: get(this, "", "getCall", getCall));
		endfunction
		//---------------------------------------------------------------------------------------------
		virtual task run_phase(uvm_phase phase);
			phase.raise_objection(this);
				super.run_phase(phase);
				getCaller;
			phase.drop_objection(this);
		endtask

	endclass : rxModule
	

endpackage : elgantUVM_tlmPutGetPortDemoPackage1


package elgantUVM_tmlPortDemoTestPackage;
	import uvm_pkg ::*;
	import elgantUVM_tlmPutGetPortDemoPackage1 ::*;
	
	class elgantUVM_tlmPortTxRxBaseTest extends uvm_test;
		`uvm_component_utils(elgantUVM_tlmPortTxRxBaseTest)
	
		txModule txMod;
		rxModule rxMod;
		bit getCall;
		bit putCall;
		
		function new(string name = "elgantUVM_tlmPortTxRxBaseTest", uvm_component parent);
			super.new(name, parent);
		endfunction
	
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			txMod = txModule :: type_id :: create("txMod", this);
			rxMod = rxModule :: type_id :: create("rxMod", this);
		endfunction
		
		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			txMod.txPutPort.connect(rxMod.rxPutImp);
			rxMod.rxGetPort.connect(txMod.txGetImp);
		endfunction : connect_phase
		
	endclass : elgantUVM_tlmPortTxRxBaseTest
	
	//Test Get Port Demo;
	class elgantUVM_tlmGetPortBasicDemoTest extends elgantUVM_tlmPortTxRxBaseTest;
		`uvm_component_utils(elgantUVM_tlmGetPortBasicDemoTest)
		
		function new(string name = "elgantUVM_tlmGetPortBasicDemoTest", uvm_component parent);
			super.new(name, parent);
		endfunction
		
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			getCall=1;
			putCall=0;
          uvm_config_db #(bit) :: set(null, "*", "getCall", getCall);
          uvm_config_db #(bit) :: set(null, "", "putCall", putCall);
		endfunction

	endclass : elgantUVM_tlmGetPortBasicDemoTest
	
	class elgantUVM_tlmPutPortBasicDemoTest extends elgantUVM_tlmPortTxRxBaseTest;
		`uvm_component_utils(elgantUVM_tlmPutPortBasicDemoTest)
		
		function new(string name = "elgantUVM_tlmPutPortBasicDemoTest", uvm_component parent);
			super.new(name, parent);
		endfunction
		
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			getCall=0;
			putCall=1;
          uvm_config_db #(bit) :: set(null, "*", "getCall", getCall);
          uvm_config_db #(bit) :: set(null, "", "putCall", putCall);
		endfunction

	endclass : elgantUVM_tlmPutPortBasicDemoTest 
	
endpackage : elgantUVM_tmlPortDemoTestPackage

//tbTop module

module tbTop;
  `include "uvm_macros.svh"
  import uvm_pkg ::*;
  import elgantUVM_tmlPortDemoTestPackage::*;
  
  // run a Get Port Demo test
  //initial run_test("elgantUVM_tlmGetPortBasicDemoTest");

  // run a Put port Demo Test
  initial run_test("elgantUVM_tlmPutPortBasicDemoTest");
  
endmodule
