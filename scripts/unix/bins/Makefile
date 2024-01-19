TARS = $(wildcard *.tar.gz)

install:
	@for tar in $(TARS); do \
		echo "untar $$tar"; \
		tar -xzf $$tar; \
	done; \
	# detect if binary by using file
	@for file in $(wildcard *); do \
		if file $$file | grep -q "ELF"; then \
			echo "installing $$file"; \
			cp $$file /usr/local/bin/; \
		fi; \
	done;
	
  
