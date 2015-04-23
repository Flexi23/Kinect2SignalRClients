int w, h;
float kinectScale;

var numThrowies=128;
Throwie[] Throwies = new Throwie[numThrowies];

float v = 1/30;
 
static final double GRAVITY = 128;
static final float BOUNCE_DAMPENING = 1/32;

private boolean grav = false;
	
void setup() {
	w = window.innerWidth;
	h = window.innerHeight;
 
	size(w, h);
	frameRate(60);
 
	stroke(color(0));
	fill(color(0));
	textFont(createFont("Lucida Console",15));

	if( w / h > 512 / 424)
	{
		kinectScale = h / 424;
	}
	else
	{
		kinectScale = w / 512;
	}
 
	initThrowies();
} 
 
private void initThrowies() {
	for (int i = 0; i < numThrowies ; i++) {
		float x = random(0, 512);
		float y = random(0, 424);
		Throwies[i] = new Throwie(x, y, 5);
	}
}

var grabFrame = false;

public void draw() {
	if(grabFrame = this.bodyFrame > oldBodyFrame)
	{
		oldBodyFrame = this.bodyFrame;
	}

	fill(0,0,0);
	rect(0,0,w,h);

	fill(256,256,256);
	stroke(256,256,256);
	text("fps: " + nf(frameRate, 2, 1), 10, 40);


	if(this.trackedBodyIds != null) {
		text("bodies: " + this.trackedBodyIds.length, 10, 20);
	} else {
		text("nothing tracked yet.", 10, 20);
	}	
	
	pushMatrix();
	scale(kinectScale);

	if(this.trackedBodyIds != null) {
		for(int i = 0; i < this.trackedBodyIds.length; i++) {
			var TrackingId = this.trackedBodyIds[i];
			drawBody(this.bodies[TrackingId]);
		}
	}
	grabables.forEach(function(t){
		drawPinControl(t.x, t.y, t.s);
	});

	drawThrowies();
 
	noFill();
	strokeWeight(1);
	stroke(color(255));
	rect(0, 0, 512 * kinectScale - 1, 424 * kinectScale - 1);

	popMatrix();
}

var joints = ["SpineBase", "SpineMid", "Neck", "Head", "ShoulderLeft",
 "ElbowLeft", "WristLeft", "HandLeft", "ShoulderRight", "ElbowRight",
  "WristRight", "HandRight", "HipLeft", "KneeLeft", "AnkleLeft", 
  "FootLeft", "HipRight", "KneeRight", "AnkleRight", "FootRight", 
  "SpineShoulder", "HandTipLeft", "ThumbLeft", "HandTipRight", "ThumbRight"];

var members = [
	["SpineBase", "SpineMid"],
	["SpineMid", "SpineShoulder"],
	["SpineShoulder", "Neck"],
	["Neck", "Head"],
	["SpineShoulder", "ShoulderLeft"],
	["ShoulderLeft","ElbowLeft"],
	["ElbowLeft","WristLeft"],
	["WristLeft","HandLeft"],
	["HandLeft","HandTipLeft"],
	["HandLeft","ThumbLeft"],
	["SpineBase","HipLeft"],
	["HipLeft","KneeLeft"],
	["KneeLeft","AnkleLeft"],
	["AnkleLeft","FootLeft"],
	["SpineShoulder", "ShoulderRight"],
	["ShoulderRight","ElbowRight"],
	["ElbowRight","WristRight"],
	["WristRight","HandRight"],
	["HandRight","HandTipRight"],
	["HandRight","ThumbRight"],
	["SpineBase","HipRight"],
	["HipRight","KneeRight"],
	["KneeRight","AnkleRight"],
	["AnkleRight","FootRight"]
];

var grabables = [];

for(i = 0; i < 42; i++)
{
	grabables.push(	{"x": Math.random()*512, "y": Math.random()*424, "s": 1, "r": 0, "grabbedBy" : null});
}


int oldBodyFrame = 1;

private void drawBody(body)
{
	if(body == null) {
		return;
	}

	// draw head

	var headX = body.points2D["Head"][0];
	var headY = body.points2D["Head"][1];
	var neckX = body.points2D["Neck"][0];
	var neckY = body.points2D["Neck"][1];

	var headSize = dist(headX, headY, neckX, neckY) * 2;
	var headColor = color(255,255,255,128);

	noStroke();
	fill(headColor);
	ellipse(headX, headY, headSize, headSize);


	// draw hand

	drawHand(body.handLeft);
	drawHand(body.handRight);

	if(grabFrame)
	{
		grabWith(body.handLeft);
		grabWith(body.handRight);
	}

	members.forEach(function(member) {
		var t1 = body.Joints[member[0]].TrackingState;
		var t2 = body.Joints[member[1]].TrackingState;
		if(t1 == 2 && t2 == 2)
		{
			var x1 = body.points2D[member[0]][0];
			var y1 = body.points2D[member[0]][1];
			var x2 = body.points2D[member[1]][0];
			var y2 = body.points2D[member[1]][1];

			stroke(color(96,96,96, 128));
			strokeWeight(3);
			line(x1,y1,x2,y2);
		}
	});

	joints.forEach(function(joint){
		var ts = body.Joints[joint].TrackingState;
		switch(ts)
		{
			case 0:
			case 1:
				fill(color(255,0,0));
				break;
			case 2:
				fill(color(0,255,0));
				break;
		}
		var x = body.points2D[joint][0];
		var y = body.points2D[joint][1];		
		noStroke();
		ellipse(x,y,3,3);
	});
}

var handNotTrackedColor = color(255,0,0,0);
var handLassoColor = color(0,0,255,128);
var handOpenColor = color(255,255,255,32);
var handClosedColor = color(0,255,0,96);
var handUnknownColor = color(256,128,0,128);

function drawHand(hand){
	switch(hand.state) {
		case 0:
			handColor = handNotTrackedColor;
			break;
		case 1:
			handColor = handLassoColor;
			break;
		case 2:
			handColor = handOpenColor;
			break;
		case 3:
			handColor = handClosedColor;
			break;
		case 4:
			handColor = handUnknownColor;
			break;
	}

	if(!hand.grab)
	{
		releaseObject(hand);
	}

	if(hand.point || hand.grab && !hand.object)
	{
		noStroke();
		fill(handColor);
		var handSize = 25;
		ellipse(hand.x, hand.y, handSize, handSize);
	}
}

function releaseObject(hand)
{
	if(hand.object)
	{
		hand.object.grabbedBy = null;
		hand.object = null;
		hand.grab = false;
	}
}

function grabWith(hand) {

	if(!hand.grab)
	{
		return;
	}

	if(hand.object)
	{
		/* that would be a real differential shift
		hand.object.x += hand.x - hand.prevX;
		hand.object.y += hand.y - hand.prevY;
		hand.prevX = hand.x;
		hand.prevY = hand.y;
		*/

		// rather snap it right in the hand
		hand.object.x = hand.x;
		hand.object.y = hand.y;

		hand.object.vX = (hand.x - hand.prevX) * 30;
		hand.object.vY = (hand.y - hand.prevY) * 30;
		return;
	}

	var minD = 1000;
	var nearestGrabable = null;
	
	Throwies.forEach(function(throwie){
		var d = dist(throwie.x, throwie.y, hand.x, hand.y);
		if(d <= minD && throwie.grabbedBy == null) //todo: consider object's radius
		{
			minD = d;
			nearestGrabable = throwie;
		}	
	});
	

	grabables.forEach(function(o){
		var d = dist(o.x, o.y, hand.x, hand.y);
		if(d <= minD && o.grabbedBy == null) //todo: consider object's radius
		{
			minD = d;
			nearestGrabable = o;
		}
	});

	var threshold = 12.5;
	if(minD <= threshold)
	{
		nearestGrabable.grabbedBy = hand.id;
		hand.object = nearestGrabable;
	}
}

function drawPinControl(x, y, s) {
	pushMatrix();
	translate(x, y);

	noFill();
	stroke(color(255));
	strokeWeight(0.9);

	ellipse(0,0,10,10);

	popMatrix();
}

function drawThrowable(int x, int y, float s, float rot) {
	pushMatrix();
	translate(x, y);
	scale(s);
	rotate(rot);
	 
	strokeWeight(3);
	noFill();
	arc(0,-40,85,120,-PI*1.25f, PI*0.25f);
 
	strokeWeight(2);
	ellipse(15,-55,18,18);
	ellipse(-15,-55,18,18);
 
	strokeWeight(2.5f);
	line(-35,25,-30,3);
	line(35,25,30,3);
	line(-30,3,30,3);
	rect(-35,25,70,45);
	line(-5,70,-10,87);
	line(5,70,10,87);
	line(-10,87,10,87);
	 
	line(-20,-93,20,-93);
	line(-35,-73,35,-73);
	 
	line(42,-50,50,-52);
	line(42,-47,50,-45);
	line(50,-52,50,-45);
	line(-42,-50,-50,-52);
	line(-42,-47,-50,-45);
	line(-50,-52,-50,-45);	 
	 
	arc(-80,95,40, 5, 0, PI);
	arc(0,95,40, 5, 0, PI);
	arc(80,95,40, 5, 0, PI);
	strokeWeight(4.5f);
	line(-80,95,-60,45);
	line(0,95,0,45);
	line(80,95,60,45);
	strokeWeight(2.5f);
	line(-60,45,-35,30);
	line(-60,45,-35,65);
	line(-75,85,-35,65);
	line(0,45,-15,30);
	line(0,45,15,30);
	line(0,45,15,65);
	line(0,45,-15,65);
	line(0,85,15,65);
	line(0,85,-15,65);
	line(60,45,35,30);
	line(60,45,35,65);
	line(75,85,35,65);

	popMatrix();
}

var bodies, trackedBodyIds;
var bodyFrame;

void onBodies( bodies,  trackedBodyIds, frame) {
	this.bodyFrame = frame;
	this.bodies = bodies;
	this.trackedBodyIds = trackedBodyIds;
}


class Throwie {

	float x;
	float y;

	float vX = 0;
	float vY = 0;

	float radius;

	public Throwie(float x, float y, float r) {
		this.x = x;
		this.y = y;
		radius = r;
	}

	public float getVelocity() {
		return sqrt(vX * vX + vY * vY);
	}

	public float getMotionDirection() {
		return atan2(vX, vY);
	}

	public void tick() {
		x += vX * v;
		y += vY * v;
	}
	 
	public void bounce(Throwie theOtherThrowie) {
		if (hit(theOtherThrowie)) {
			float commonTangentAngle = atan2(
					(float) (x - theOtherThrowie.x),
					(float) (y - theOtherThrowie.y))
					+ asin(1);

			float v1 = theOtherThrowie.getVelocity();
			float v2 = getVelocity();
			float w1 = theOtherThrowie.getMotionDirection();
			float w2 = getMotionDirection();

			theOtherThrowie.vX = sin(commonTangentAngle) * v1
					* cos(w1 - commonTangentAngle)
					+ cos(commonTangentAngle) * v2
					* sin(w2 - commonTangentAngle);
			theOtherThrowie.vY = cos(commonTangentAngle) * v1
					* cos(w1 - commonTangentAngle)
					- sin(commonTangentAngle) * v2
					* sin(w2 - commonTangentAngle);
			vX = sin(commonTangentAngle) * v2
					* cos(w2 - commonTangentAngle)
					+ cos(commonTangentAngle) * v1
					* sin(w1 - commonTangentAngle);
			vY = cos(commonTangentAngle) * v2
					* cos(w2 - commonTangentAngle)
					- sin(commonTangentAngle) * v1
					* sin(w1 - commonTangentAngle);

			theOtherThrowie.vX *= (1 - BOUNCE_DAMPENING);
			theOtherThrowie.vY *= (1 - BOUNCE_DAMPENING);
			vX *= (1 - BOUNCE_DAMPENING);
			vY *= (1 - BOUNCE_DAMPENING);

		}
	}

	private boolean hit(Throwie theOtherThrowie) {
		return (sqrt(pow((float) (theOtherThrowie.x - x), 2)
				+ pow((float) (theOtherThrowie.y - y), 2)) < (theOtherThrowie.radius + radius))
				&& (sqrt(pow((float) (theOtherThrowie.x - x), 2)
						+ pow((float) (theOtherThrowie.y - y), 2)) > sqrt(pow(
						(float) (theOtherThrowie.x
								+ theOtherThrowie.vX*v - x - vX*v), 2)
						+ pow((float) (theOtherThrowie.y
								+ theOtherThrowie.vY*v - y - vY*v), 2)));
	}
}

private void drawThrowies() {
	noStroke();
	updateThrowies();

	for (int i = 0; i < numThrowies; i++)
	{
		int d = parseInt(Throwies[i].radius * 2);
		noFill();
		strokeWeight(1.);
		stroke(color(255,128,0));
		ellipse((float) Throwies[i].x, (float) Throwies[i].y, d, d);
	}
}

private void updateThrowies()
{
	for (int i = 0; i < numThrowies; i++) {
		Throwie Throwie = Throwies[i];

		// bounce off bottom
		if (Throwie.y > 424 - Throwie.radius) {
			Throwie.vY = -abs(Throwie.vY) * (1 - BOUNCE_DAMPENING);
			Throwie.y = 424 - Throwie.radius;
		}

		// bounce off ceiling
		if (Throwie.y < Throwie.radius) {
			Throwie.vY = abs(Throwie.vY) * (1 - BOUNCE_DAMPENING);
			Throwie.y = Throwie.radius;
		}

		// bounce off left border
		if (Throwie.x < Throwie.radius) {
			Throwie.vX = abs(Throwie.vX) * (1 - BOUNCE_DAMPENING);
			Throwie.x = Throwie.radius;
		}

		// bounce off right border
		if (Throwie.x > 512 - Throwie.radius) {
			Throwie.vX = -abs(Throwie.vX) * (1 - BOUNCE_DAMPENING);
			Throwie.x = 512 - Throwie.radius;
		}

		// inter Throwie
		for (int j = i+1; j < numThrowies; j++) {
			// bounce
			Throwies[i].bounce(Throwies[j]);
		}

		// apply Gravity
		if (grav) {
			Throwie.vY += GRAVITY * 0.1 * v;
		}

		// move it
		Throwie.tick();
	}
 }
