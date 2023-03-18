#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// Initialize MMIO addresses
volatile int * const VG_ADDR = (int *)0x11100000;
volatile int * const VG_COLOR = (int *)0x11140000;
volatile int * const BUTTONS = (int *)0x11180000;

volatile int * const SSEG_ADDR1 = (int *) 0x110C0000;
volatile int * const SSEG_ADDR2 = (int *) 0x111C0000;

volatile int * const SWITCHES = (int *) 0x11000000;


// Initialize Color Constants
const int BG_COLOR = 0x00;  		// Black background
const int P_NORM_COLOR = 0b11111111; 	// White paddle when normal
const int BALL_COLOR = 0b00100101;	// Grey Ball
const int WHITE_COLOR = 0b11111111;

const int BALL_SPEED = 100000; 		// Delay between each ball draw 100000




// Create typedef structs
typedef struct ball_s {
	int x, y;	// Ball Position
	int dx, dy;	// Amount to move ball
} ball_t;

typedef struct paddle_s {
	int x ,y;	// Paddle Position where y is the top of the paddle
	int w;		// Paddle Height
	int dy;		// Amount to move Paddle
	int up_btn;	// Paddle Up Button
	int down_btn;	// Paddle Down Button
	int score;	// Score Tracker
	int id;		// Paddle ID

} paddle_t;

// Create Objects
volatile ball_t ball;
volatile paddle_t paddle1;
volatile paddle_t paddle2;

// Initialize Functions
static void draw_horizontal_line(int X, int Y, int toX, int color);
static void draw_vertical_line(int X, int Y, int toY, int color);
static void draw_background();
static void draw_dot(int X, int Y, int color);

// Create Letter Functions
static void drawP(int X, int Y, int color);
static void drawL(int X, int Y, int color);
static void drawA(int X, int Y, int color);
static void drawY(int X, int Y, int color);
static void drawE(int X, int Y, int color);
static void drawR(int X, int Y, int color);
static void drawW(int X, int Y, int color);
static void drawI(int X, int Y, int color);
static void drawN(int X, int Y, int color);
static void drawS(int X, int Y, int color);
static void draw1(int X, int Y, int color);
static void draw2(int X, int Y, int color);

// Initialize Logic Functions
static void update_paddle(volatile paddle_t *paddle);
static void init();
static void move_ball(volatile ball_t *b);
static int chk_collision(volatile ball_t *b, volatile paddle_t *p);





static void init() {
	draw_background();

	*SSEG_ADDR1 = paddle1.score;
	*SSEG_ADDR2 = paddle2.score; //---------------------------------------------------

	paddle1.x = 0;			// Left of the screen
	paddle1.y = 29;			// Middle of the screen
	paddle1.w = 4;
	paddle1.up_btn = 0b01000;	// Top Button
	paddle1.down_btn = 0b00001;	// Bottom Button
	paddle1.id = 1;

	

	paddle2.x = 79;			// Right of the screen
	paddle2.y = 29;			// Middle of the screen
	paddle2.w = 4;
	paddle2.up_btn = 0b00100; 	// Left Button
	paddle2.down_btn = 0b00010;	// Right Button
	paddle2.id = 2;

	
	ball.x = 39;
	ball.y = 29;
	ball.dy = -1;

}

void main() {

	// Initialize Game Board
	init();
	paddle1.score = 0;
	paddle2.score = 0;
	ball.dx = 1; 		//Start Going to the right

	int state = 0;


	while(1) {  	  
		if(state == 0) {
			
			update_paddle(&paddle1);
			update_paddle(&paddle2);		

			int i = 0;
			while (i<BALL_SPEED) {

				// Allows paddles to move during the wait
				update_paddle(&paddle1);
				update_paddle(&paddle2);

				i++;
			}

			move_ball(&ball);
			if(paddle1.score == 5 || paddle2.score == 5) state = 1;

		}
		else if(state == 1) {
			draw_background();
			state = 2;		
		}
		else if(state == 2) {
			drawP(27, 23, WHITE_COLOR);
			drawL(31, 23, WHITE_COLOR);
			drawA(35, 23, WHITE_COLOR);
			drawY(39, 23, WHITE_COLOR);
			drawE(43, 23, WHITE_COLOR);
			drawR(47, 23, WHITE_COLOR);

			drawW(30, 31, WHITE_COLOR);//3 after p
			drawI(36, 31, WHITE_COLOR);
			drawN(40, 31, WHITE_COLOR);
			drawS(45, 31, WHITE_COLOR);
			if(paddle1.score == 5) draw1(52, 23, WHITE_COLOR);
			else draw2(52, 23, WHITE_COLOR);
			
		}

	}
}


// Updates paddle position and draws to the screen
static void update_paddle(volatile paddle_t *paddle) {
	int btn_val = *BUTTONS;
	int swt_val = *SWITCHES; 
	int p_dy = 1;

	// Allows paddles to move faster if switch is on
	if((paddle->id == 1) && (swt_val >> 15 == 1)) {
		p_dy = 4;
	}
	else if((paddle->id == 2) && ((swt_val & 1) == 1)) {
		p_dy = 4;
	}
	

	// Move Down
	if(btn_val == paddle->down_btn) {

		draw_vertical_line(paddle->x, paddle->y, paddle->y + paddle->w, BG_COLOR); // Clear this paddle

		// Keep the paddle on the screen
		if(59 - (paddle->y + paddle->w + p_dy) >= 0) { 
			paddle->y = paddle->y + p_dy;
			
		}
		else {
			paddle->y = 55;
			
		}

		
	}	

	//Move Up
	else if(btn_val == paddle->up_btn) { 
		
		draw_vertical_line(paddle->x, paddle->y, paddle->y + paddle->w, BG_COLOR); // Clear this paddle
		
		// Keep the paddle on the screen
		if((paddle->y - p_dy) >= 0) {
			paddle->y = paddle->y - p_dy;	
		}
		else {
			paddle->y = 0;
		}

		
	} 
	draw_vertical_line(paddle->x, paddle->y, paddle->y + paddle->w, P_NORM_COLOR); 	// Draw new paddle 
	





}


//Move the ball Position
//Check Collision
//Draw Ball 

static void move_ball(volatile ball_t *b) {
	draw_dot(b->x, b->y, BG_COLOR);
	b->x += b->dx;
	b->y += b->dy;
	
	if(b->x < 0) {
		paddle2.score += 1;
		init();
		return;
		//Increment Right Paddle's Score
	}
	if((79 -b->x) < 0)  {
		paddle1.score += 1;
		init();
		return;
		//Increment Left Paddle's Score
	}

	if(b->y < 0 || b->y > 59) {
		b->dy = -(b->dy);
	}
	
	draw_dot(b->x, b->y, P_NORM_COLOR);
	
	int collision_p1 = chk_collision(&ball, &paddle1);
	int collision_p2 = chk_collision(&ball, &paddle2);

	if(collision_p1) {

		int hit_location = (paddle1.y+4) - ball.y;

		if(hit_location == 0) b->dy = 3;	// Hit the Very Top

		if(hit_location == 1) b->dy = 2;

		if(hit_location == 2) b->dy = -(b->dy);	// Hit the center

		if(hit_location == 3) b->dy = -2;

		if(hit_location == 4) b->dy = -3;	//Hit the Very Bottom


		b->dx = -(b->dx);
	}

	else if(collision_p2) {
		int hit_location = (paddle2.y+4) - ball.y;

		if(hit_location == 0) b->dy = 3;	// Hit the Very Top

		if(hit_location == 1) b->dy = 2;

		if(hit_location == 2) b->dy = -(b->dy);	// Hit the center

		if(hit_location == 3) b->dy = -2;

		if(hit_location == 4) b->dy = -3;	//Hit the Very Bottom


		b->dx = -(b->dx);

	}
}






//Returns 1 if collision, 0 otherwise
static int chk_collision(volatile ball_t *b, volatile paddle_t *p) {

	if(b->x > p->x+1) return 0;	// returns 0 if ball is to the right of the left paddle
	


	if(b->x < p->x-1) return 0;	// returns 0 if ball is to the left of the right paddle

	if(b->y > p->y +4) return 0;	// returns 0 if ball is below the paddle
	if(b->y < p->y-1) return 0;	// returns 0 if ball is above the paddle

	return 1;			// return 1 when the ball is not above or below the paddle and either:
					// Directly to the right of the left paddle OR
					// Directly to the left of the right paddle.
	
}





// X is the left-most pixel of the Letter
// Y is the top-most pixel of the Letter
static void drawP(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_vertical_line(X+2, Y, Y+2, color);
	draw_dot(X+1, Y, color);
	draw_dot(X+1, Y+2, color);
	
}

static void drawL(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_horizontal_line(X+1, Y+4, X+2, color);
}

static void drawA(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_vertical_line(X+2, Y, Y+4, color);
	draw_dot(X+1, Y, color);
	draw_dot(X+1, Y+2, color);
}

static void drawY(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+1, color);
	draw_vertical_line(X+2, Y, Y+1, color);
	draw_vertical_line(X+1, Y+2, Y+4, color);
}

static void drawE(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_horizontal_line(X+1, Y, X+2, color);
	draw_horizontal_line(X+1, Y+4, X+2, color);
	draw_dot(X+1, Y+2, color);
}

static void drawR(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_vertical_line(X+2, Y, Y+1, color);
	draw_vertical_line(X+2, Y+3, Y+4, color);
	draw_dot(X+1, Y, color);
	draw_dot(X+1, Y+2, color);
}

static void drawW(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+3, color);
	draw_vertical_line(X+4, Y, Y+3, color);
	draw_vertical_line(X+2, Y+2, Y+3, color);
	draw_dot(X+1, Y+4, color);
	draw_dot(X+3, Y+4, color);
}

static void drawI(int X, int Y, int color) {
	draw_horizontal_line(X, Y, X+2, color);
	draw_horizontal_line(X, Y+4, X+2, color);
	draw_vertical_line(X+1, Y+1, Y+3, color);
}

static void drawN(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
	draw_vertical_line(X+3, Y, Y+4, color);
	draw_dot(X+1, Y+2, color);
	draw_dot(X+2, Y+3, color);
}

static void drawS(int X, int Y, int color) {
	draw_horizontal_line(X, Y, X+2, color);
	draw_horizontal_line(X, Y+2, X+2, color);
	draw_horizontal_line(X, Y+4, X+2, color);
	draw_dot(X, Y+1, color);
	draw_dot(X+2, Y+3, color);
}

static void draw1(int X, int Y, int color) {
	draw_vertical_line(X, Y, Y+4, color);
}

static void draw2(int X, int Y, int color) {
	draw_horizontal_line(X, Y, X+2, color);
	draw_horizontal_line(X, Y+2, X+2, color);
	draw_horizontal_line(X, Y+4, X+2, color);
	draw_dot(X+2, Y+1, color);
	draw_dot(X, Y+3, color);
}

static void draw_horizontal_line(int X, int Y, int toX, int color) {
	toX++;
	for (; X != toX; X++) {
		draw_dot(X, Y, color);
	}
}


static void draw_vertical_line(int X, int Y, int toY, int color) {
	toY++;
	for (; Y != toY; Y++) {
		draw_dot(X, Y, color);
	}
}

// fills the screen with BG_COLOR
static void draw_background() {
	for (int Y = 0; Y != 60; Y++) {
		draw_horizontal_line(0, Y, 79, BG_COLOR);
	}
}

// draws a small square (a single memory cell)
static void draw_dot(int X, int Y, int color) {
	*VG_ADDR = (Y << 7) | X;  // store into the address IO register
	*VG_COLOR = color;  // store into the color IO register, which triggers
	                    // the actual write to the framebuffer at the address
	                    // previously stored in the address IO register
}
