GHDL=ghdl
GHDL_FLAGS=--std=08
GHDL_OPTIMIZE := -O3
GHDL_OPT := -frelaxed-rules --warn-no-vital-generic -frelaxed $(GHDL_OPTIMIZE)
GHDL_ELAB_OPTS := --mb-comments 
GHDL_WARNS := -Wbinding -Wreserved -Wlibrary -Wvital-generic -Wdelayed-checks -Wbody -Wspecs -Wunused --warn-no-runtime-error
MODULES_V1=\
	src_rtl/v1/LWC_config_32.o\
	src_rtl/v1/LWC_config_ascon.o\
	src_rtl/v1/LWC_config_ccw_32.o\
	src_rtl/v1/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v1/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v1/LWC_config_tb.o\
	src_tb/v1/LWC_TB
MODULES_V1_8BIT=\
	src_rtl/v1_8bit/LWC_config_8.o\
	src_rtl/v1_8bit/LWC_config_ascon.o\
	src_rtl/v1_8bit/LWC_config_ccw_8.o\
	src_rtl/v1_8bit/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v1_8bit/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v1_8bit/LWC_config_tb.o\
	src_tb/v1_8bit/LWC_TB
MODULES_V1_16BIT=\
	src_rtl/v1_16bit/LWC_config_16.o\
	src_rtl/v1_16bit/LWC_config_ascon.o\
	src_rtl/v1_16bit/LWC_config_ccw_16.o\
	src_rtl/v1_16bit/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v1_16bit/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v1_16bit/LWC_config_tb.o\
	src_tb/v1_16bit/LWC_TB
MODULES_V2=\
	src_rtl/v2/LWC_config_32.o\
	src_rtl/v2/LWC_config_ascon.o\
	src_rtl/v2/LWC_config_ccw_32.o\
	src_rtl/v2/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v2/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v2/LWC_config_tb.o\
	src_tb/v2/LWC_TB
MODULES_V3=\
	src_rtl/v3/LWC_config_32.o\
	src_rtl/v3/LWC_config_ascon.o\
	src_rtl/v3/LWC_config_ccw_32.o\
	src_rtl/v3/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v3/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v3/LWC_config_tb.o\
	src_tb/v3/LWC_TB
MODULES_V4=\
	src_rtl/v4/LWC_config_32.o\
	src_rtl/v4/LWC_config_ascon.o\
	src_rtl/v4/LWC_config_ccw_32.o\
	src_rtl/v4/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v4/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v4/LWC_config_tb.o\
	src_tb/v4/LWC_TB
MODULES_V5=\
	src_rtl/v5/LWC_config_32.o\
	src_rtl/v5/LWC_config_ascon.o\
	src_rtl/v5/LWC_config_ccw_32.o\
	src_rtl/v5/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v5/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v5/LWC_config_tb.o\
	src_tb/v5/LWC_TB
MODULES_V6=\
	src_rtl/v6/LWC_config_32.o\
	src_rtl/v6/LWC_config_ascon.o\
	src_rtl/v6/LWC_config_ccw_32.o\
	src_rtl/v6/design_pkg.o\
	src_rtl/LWC/NIST_LWAPI_pkg.o\
	src_rtl/LWC/FIFO.o\
	src_rtl/LWC/data_piso.o\
	src_rtl/LWC/data_sipo.o\
	src_rtl/LWC/key_piso.o\
	src_rtl/v6/CryptoCore.o\
	src_rtl/LWC/PostProcessor.o\
	src_rtl/LWC/PreProcessor.o\
	src_rtl/LWC/LWC.o\
	src_tb/v6/LWC_config_tb.o\
	src_tb/v6/LWC_TB

v1: $(MODULES_V1)
	$(info More v1 testbench output can be found in log.txt or failed_testvectors.txt)

v1_8bit: $(MODULES_V1_8BIT)
	$(info More v1_8bit testbench output can be found in log.txt or failed_testvectors.txt)

v1_16bit: $(MODULES_V1_16BIT)
	$(info More v1_16bit testbench output can be found in log.txt or failed_testvectors.txt)
	
v2: $(MODULES_V2)
	$(info More v2 testbench output can be found in log.txt or failed_testvectors.txt)
	
v3: $(MODULES_V3)
	$(info More v3 testbench output can be found in log.txt or failed_testvectors.txt)
	
v4: $(MODULES_V4)
	$(info More v4 testbench output can be found in log.txt or failed_testvectors.txt)
	
v5: $(MODULES_V5)
	$(info More v5 testbench output can be found in log.txt or failed_testvectors.txt)
	
v6: $(MODULES_V6)
	$(info More v6 testbench output can be found in log.txt or failed_testvectors.txt)

# Binary depends on the object file
%: %.o
	$(GHDL) -e $(GHDL_FLAGS) $(GHDL_OPT) $(GHDL_WARNS) $(GHDL_ELAB_OPTS) LWC_TB
	$(GHDL) -r $(GHDL_FLAGS) $(GHDL_OPT) $(GHDL_WARNS) $(GHDL_ELAB_OPTS) LWC_TB

# Object file depends on source
%.o: %.vhd
	$(GHDL) -a $(GHDL_FLAGS) $(GHDL_OPT) $(GHDL_WARNS) $(GHDL_ELAB_OPTS) $<

.PHONY: clean
clean:
	$(info Cleaning up...)
	rm -f *.o *_TB work*.cf e*.lst failed_testvectors.txt result.txt log.txt lwc_tb timing.txt timing.csv
