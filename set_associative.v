// set associative.

module project();
	//main memory
	reg [6:0] memory[0:10737418];
	// k is used to vary the number of words per line.
	genvar k;
	// stores no of miss and hits.
	real miss[0:14];
	real hit[0:14];
	// Function for calculating log2(k) as required.
	function [31:0] log2;
   		input [31:0] value;
  	 	integer r;
   		reg [31:0] u;
   		begin
			if(value==1 || value ==2 || value ==4 || value ==8)begin
				value=value+1;
			end
   	       		u = value - 1;
      			log2 = 0;
      			for (r = 0; r < 31; r = r + 1)
        			if (u[r]) log2 = r+1;
   			end
	endfunction

	// run for different size of the line
	for(k=1;k<16;k=k+1)
	begin
		//cache components
		reg valid[0:255][0:k];                 // 256 lines with k+1 columns.
		reg [7:0]   index[0:255] ;	       // 256 lines with 8 bit size.
		reg [23-log2(k):0]  tag[0:255][0:k]; // 256 lines with k+1 columns each of tag size.
		reg [6:0] data[0:255][0:k];	       // 256 lines with k+1 columns each size of size 7 bits.
	
		//inputs storing
		reg [31:0] address;
		reg[4:0] inst; 
		
		integer data_file,tmp,data1,i,j,p;
		// initializing valid,tag,data,miss,hit to zero.
		initial begin
		miss[k-1]=0;
		hit[k-1]=0;
	
		// initiallizing memory with some random data.
		for(p=0;p<10737418;p=p+1)begin
			memory[p]=$random%7;
		end
	
		for(i=0;i<256;i=i+1)begin
			for(j=0;j<k+1;j=j+1)begin
				valid[i][j]=0;
				tag[i][j]=0;
				data[i][j]=0;
			end
		end
		// opening files to with read instructions.
		data_file=$fopen("twolf.trace","r");
		while(!$feof(data_file)) begin    // runs untill ebd of the line.
			tmp=$fscanf(data_file,"%s%h%h\n",inst,address,data1);  // read the contents of the file and store in respective variables.
		// ----------------------------------  load instruction ----------------------------------------------------------			
			if(inst==5'h0c)
			begin
				if(valid[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]==0)
				begin
					valid[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=1;
					index[address[log2(k)+7:log2(k)]]=address[log2(k)+7:log2(k)];
					tag[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=address[31:log2(k)+8];
					data[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=memory[address];
					miss[k-1]=miss[k-1]+1;
				end
				else 
				begin
					if(tag[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]==address[31:log2(k)+8])
					begin	
							// loading from cache.
							hit[k-1]=hit[k-1]+1;
					end
					else
					begin
						index[address[log2(k)+7:log2(k)]]=address[log2(k)+7:log2(k)];
						tag[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=address[31:log2(k)+8];
						data[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=memory[address];
						miss[k-1]=miss[k-1]+1;
					end
				
				end
			end
		// ---------------------------------------------------------------------------------------------------------------
						// write through+write miss no allocate.
		// ----------------------------------  store instruction ---------------------------------------------------------
			if(inst == 5'h13)
			begin
				if(valid[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]==0)
				begin
					memory[address] = data1;
					miss[k-1]=miss[k-1]+1;
				end
				else
				begin
					index[address[log2(k)+7:log2(k)]]=address[log2(k)+7:log2(k)];
					if(tag[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]==address[31:log2(k)+8])
					begin	
						hit[k-1]=hit[k-1]+1;
						data[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=data1;
						memory[address] = data1;
					end
					else
					begin
						tag[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=address[31:log2(k)+8];
						data[address[log2(k)+7:log2(k)]][address[log2(k)-1:0]]=data1;
						memory[address] = data1;			
						miss[k-1]=miss[k-1]+1;
					end
				end
			end
		// -----------------------------------------------------------------------------------------------------------------
		end 
		$display("%f\t%f",hit[k-1]/(hit[k-1]+miss[k-1])*100,miss[k-1]/(hit[k-1]+miss[k-1])*100);   // printing hit ratio and miss ratio.
		$fclose(data_file);
		end
	end
endmodule
