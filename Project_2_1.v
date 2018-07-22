module Project_2_1
	(
		CLOCK_50,						//	On Board 50 MHz
		
		// Your inputs and outputs here
      KEY,
      SW,
		  
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input	  CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = SW[4];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
	datapath d0(
	         .clk(CLOCK_50),
	         .direction(direction),
				.inmenu(SW[0]),
				.ingame(SW[1]),
		      .RGB(colour),
				.x_pointer(x),
				.y_pointer(y),
				
				//delete later
				.inital_head(SW[2])
	 );
	 
	 
	 //direction wire
	 wire [4:0] direction;
	 kbInput kbIn(CLOCK_50, KEY, SW, direction, reset);
	 
endmodule


module datapath(clk, direction, inmenu, ingame, RGB, x_pointer, y_pointer ,inital_head );
   input clk;
	
	output [7:0] x_pointer;
	output [6:0] y_pointer;
	input [4:0] direction;
	
	//delete later
	input inital_head;
	
	//status of game
   input inmenu;
	input ingame;
	
	
	wire R, G, B; // Will be used for concatenation for output "RGB".
	wire frame_update; // signal for frame update
	wire delayed_clk;
	
	output [2:0] RGB; // the colour used for output
	
	reg menu_text; // check if the pixel is the menu's text.
	
	
	
	//register for border
	reg border;
	
	//registers for snake
	reg [6:0] size;
	reg [7:0] snakeX[0:640];
	reg [6:0] snakeY[0:640];
	reg found;
	reg snakeHead;
	reg snakeBody;
	reg [1:0]currentDirect;
	integer bodycounter, bodycounter2, bodycounter3;
	reg up,down,left,right;
	
	//registers for apple
	reg apple;
	reg [7:0] appleX;
	reg [6:0] appleY;
	reg apple_inX, apple_inY;
	wire [7:0]rand_X;
	wire [6:0]rand_Y;
	
	//registers for game status
	reg lethal, nonLethal;
	reg bad_collision, good_collision, game_over;
	
	
	//down level modules
	refresher ref0(clk, x_pointer, y_pointer);
	frame_updater upd0(clk, 1'b1, frame_update);
	delay_counter dc0(clk, 1'b1, frame_update,delayed_clk);
	randomGrid rand1(clk, rand_X, rand_Y);
	
	always@(posedge clk)
	begin
		if (inmenu)begin
				
			
			 //initialize snake's position
			 for(bodycounter3 = 1; bodycounter3 < 641; bodycounter3 = bodycounter3+1)begin
					snakeX[bodycounter3] = 0;
					snakeY[bodycounter3] = 0;
			 end
				
			 //initialze snake's size
			 size = 1;	
			 
			 //start game
			 game_over=0;
		
			 //initialize apple's position
			 appleX = 15;
			 appleY = 15;
			
			 if (
			 // Letter "S"
				  (x_pointer >= 10 && x_pointer <= 36 && y_pointer >= 11  && y_pointer <= 16 )
				||(x_pointer >= 10 && x_pointer <= 15 && y_pointer >= 11  && y_pointer <= 33 )
				||(x_pointer >= 31 && x_pointer <= 36 && y_pointer >= 11  && y_pointer <= 20 )
				||(x_pointer >= 10 && x_pointer <= 36 && y_pointer >= 29  && y_pointer <= 33 )
				||(x_pointer >= 31 && x_pointer <= 36 && y_pointer >= 29  && y_pointer <= 54 )
				||(x_pointer >= 10 && x_pointer <= 36 && y_pointer >= 49  && y_pointer <= 54 )
				||(x_pointer >= 10 && x_pointer <= 15 && y_pointer >= 44  && y_pointer <= 54 )
				
			 // Letter "N"
				||(x_pointer >= 41 && x_pointer <= 46 && y_pointer >= 11  && y_pointer <= 54 )
				||(x_pointer >= 46 && x_pointer <= 50 && y_pointer >= 13  && y_pointer <= 20 )
				||(x_pointer >= 50 && x_pointer <= 54 && y_pointer >= 20  && y_pointer <= 29 )
				||(x_pointer >= 53 && x_pointer <= 57 && y_pointer >= 28  && y_pointer <= 38 )
				||(x_pointer >= 56 && x_pointer <= 60 && y_pointer >= 37  && y_pointer <= 45 )
				||(x_pointer >= 59 && x_pointer <= 62 && y_pointer >= 44  && y_pointer <= 51 )
				||(x_pointer >= 62 && x_pointer <= 67 && y_pointer >= 11  && y_pointer <= 54 )
			 // Letter "A"
			 // Letter "K"
			 // Letter "E"
				)
				 menu_text <= 1'b1;
			 else
				 menu_text <= 1'b0;
		end
		else if(ingame)begin
				
				//################################################################################################
				//Add border
				border <= (   ((x_pointer >= 2) && (x_pointer <= 4)&&(y_pointer >= 2) && (y_pointer <=112))
								||((x_pointer >= 156)&& (x_pointer <= 158)&&(y_pointer >= 2) && (y_pointer <=112))
								||((x_pointer >= 2) && (x_pointer <= 158)&&(y_pointer >= 2) && (y_pointer <= 4))
								||((x_pointer >= 2) && (x_pointer <= 158)&&(y_pointer >= 110) && (y_pointer <= 112)));
				
				
				//################################################################################################
				//SNAKE PART STARTS FROM HERE!
				//Add Snake body
				found = 0;
				for(bodycounter = 1; bodycounter <= size; bodycounter = bodycounter + 1)begin
					if(~found)begin				
						snakeBody = ( (x_pointer >= snakeX[bodycounter] && x_pointer <= snakeX[bodycounter]+2) 
								  && (y_pointer >= snakeY[bodycounter] && y_pointer <= snakeY[bodycounter]+2));
						found = snakeBody;
					end
				end
				
				//Add Snake head
				snakeHead = (x_pointer >= snakeX[0] && x_pointer <= (snakeX[0]+2))
								&& (y_pointer >= snakeY[0] && y_pointer <= (snakeY[0]+2));
				
				
				//Initial Snake's head
				if(!inital_head) begin
					snakeY[0] = 60;
					snakeX[0] = 80;
				end
				
				
				//update snake's position
				if(delayed_clk)begin
					for(bodycounter2 = 640; bodycounter2 > 0; bodycounter2 = bodycounter2 - 1)begin
							if(bodycounter2 <= size - 1)begin
								snakeX[bodycounter2] = snakeX[bodycounter2 - 1];
								snakeY[bodycounter2] = snakeY[bodycounter2 - 1];
							end	
					end	
						
					//update snake's direction
					case(direction)
						//UP
						5'b00010: if(!down)begin
											up = 1;
											down = 0;
											left = 0;
											right = 0;
									 end 
						//LEFT
						5'b00100:if(!right)begin
											up = 0;
											down = 0;
											left = 1;
											right = 0;
									 end 
						//DOWN
						5'b01000:if(!up)begin
											up = 0;
											down = 1;
											left = 0;
											right = 0;
									end 
						//RIGHT
						5'b10000: if(!left)begin
											up = 0;
											down = 0;
											left = 0;
											right = 1;
									end 
					endcase	
					if(up)
						 snakeY[0] <= (snakeY[0] - 2);
					else if(left)
						 snakeX[0] <= (snakeX[0] - 2);
					else if(down)
						 snakeY[0] <= (snakeY[0] + 2);
					else if(right)
						 snakeX[0] <= (snakeX[0] + 2);
				end	
				
				
				//################################################################################################
				//APPLE PART STARTS FROM HERE! 
				//Draw an apple
				apple_inX <= (x_pointer >= appleX && x_pointer <= (appleX + 2));
				apple_inY <= (y_pointer >=appleY && y_pointer <= (appleY + 2));
				apple = apple_inX && apple_inY;
				
				//Set apple's position
				if(good_collision)begin
						appleX <= rand_X;
						appleY <= rand_Y;
				end
				
				//###############################################################################################
				//CHECK COLLISION
				//if is in lethal position
				lethal = border || snakeBody;
	
				//if is in nonLethal position
				nonLethal = apple;
	
				//check good collision
				if(nonLethal && snakeHead) begin 
					good_collision<=1;
					size = size+1;
				end	
				else 
					good_collision<=0;
			
				//check bad collision
				if(lethal && snakeHead) begin
					bad_collision<=1;
				end
				else begin 
					bad_collision<=0;
				end
	
				//check game over
				if(bad_collision) begin
					game_over<=1;
				end	
				
				
		end
	end
	
	// Display white: menu_text
	// Display green: the snake's head and the snake's body
	// Display red: the apple, or game over
	// Display blue: the border
	
	assign R = apple;
	assign G = snakeHead||snakeBody;
	assign B = border&&~game_over;
   assign RGB = {R, G, B};
endmodule
	
	
module randomGrid(clk, rand_X, rand_Y);
	input clk;
	output reg [7:0] rand_X =6;
	output reg [6:0] rand_Y =6;
	
	// set the maximum height and width of the game interface.
	// x and y will scan over every pixel.
	integer max_height = 108;
	integer max_width = 154;
	
	always@(posedge clk)
	begin
		if(rand_X === max_width)
			rand_X <= 6;
		else
			rand_X <= rand_X + 1;
	end

	always@(posedge clk)
	begin
		if(rand_X === max_width)
		begin
			if(rand_Y === max_height)
				rand_Y <= 6;
			else
				rand_Y <= rand_Y + 1;
		end
	end
endmodule	

	
module kbInput(CLOCK_50, KEY, SW,direction, reset);
	input CLOCK_50;
	input [3:0]KEY;
	input [9:0]SW;
	output reg [4:0] direction;
	output reg reset = 0; 
	
	always@(*)
	begin
		if(~KEY[2])
			direction = 5'b00010;
		else if(~KEY[3])
			direction = 5'b00100;
		else if(~KEY[1])
			direction = 5'b01000;
		else if(~KEY[0])
			direction = 5'b10000;
//		else if(SW[0])
//			reset <= ~reset;
		else direction <= direction;
	end	
endmodule





module refresher(clk, x_counter, y_counter);
// refreshes the coordinate of x and y to the next check point.
	input clk;
	output reg [7:0] x_counter;
	output reg [6:0] y_counter;
	
	// set the maximum height and width of the game interface.
	// x and y will scan over every pixel.
	integer max_height = 120;
	integer max_width = 160;
	
	always@(posedge clk)
	begin
		if(x_counter === max_width)
			x_counter <= 0;
		else
			x_counter <= x_counter + 1;
	end

	always@(posedge clk)
	begin
		if(x_counter === max_width)
		begin
			if(y_counter === max_height)
				y_counter <= 0;
			else
			y_counter <= y_counter + 1;
		end
	end
endmodule

module frame_updater(clk, reset_n, frame_update);
	input clk;
	input reset_n;
	output frame_update;
	reg[19:0] delay;
	// Register for the delay counter
	
	always @(posedge clk)
	begin: delay_counter
//		if (!reset_n)
//			delay <= 20'd840000;
		if (delay == 0)
			delay <= 20'd840000;
	   else
		begin
			    delay <= delay - 1'b1;
		end
	end
	
	assign frame_update = (delay == 20'd0)? 1: 0;
endmodule



module delay_counter(clk, reset_n, en_delay,delayed_clk);
	input clk;
	input reset_n;
	input en_delay;
	output delayed_clk;
	
	reg[3:0] delay;
	
	// Register for the delay counter
	always @(posedge clk)begin
//		if (!reset_n)
//			delay <= 20'd840000;
		if(delay == 2)
				delay <= 0;
		else if (en_delay)begin
			   delay <= delay + 1'b1;
		end	
	end
	
	assign delayed_clk = (delay == 2)? 1: 0;
endmodule

	
module fsm(resetn, clk, go, inmenu, ingame, plot);
	input resetn;
	input clk;
	input go;
	output ingame;
	output inmenu;
	output plot;
	
	assign ingame = 0;
	assign plot = 1;
	assign inmenu = 1;
endmodule