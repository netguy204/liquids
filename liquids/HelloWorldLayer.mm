//
//  HelloWorldLayer.mm
//  liquids
//
//  Created by Brian Taylor on 3/13/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "PhysicsSprite.h"

enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (CCGLProgram*)loadProgram:(NSString*)path {
    GLchar * fragSource = (GLchar*) [[NSString stringWithContentsOfFile:[CCFileUtils fullPathFromRelativePath:path] encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    NSLog(@"program: %s", fragSource);
    CCGLProgram *program = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureColor_vert fragmentShaderByteArray:fragSource];
    
    
    CHECK_GL_ERROR_DEBUG();
    
    [program addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [program addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
    [program addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
    
    CHECK_GL_ERROR_DEBUG();
    
    [program link];
    
    CHECK_GL_ERROR_DEBUG();
    
    [program updateUniforms];
    
    CHECK_GL_ERROR_DEBUG();
    return [program autorelease];
}

- (CCRenderTexture*)getHblurEffect:(CGSize)s {
    CCRenderTexture *hblur = [CCRenderTexture renderTextureWithWidth:s.width height:s.height];
    hblur.position = CGPointMake(s.width / 2, s.height / 2);
    
    // set up the render effect
    
    hblur.sprite.shaderProgram = [self loadProgram:@"horizontal_Blur.fsh"];
    return hblur;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
		leftoverTime = 0;
        
		// init physics
		[self initPhysics];
        
		// create reset button
		//[self createMenu];
		
		//Set up sprite
		
		// Use batch node. Faster
		parent = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
		spriteTexture_ = [parent texture];
        
        effectStack = [[NSMutableArray alloc] init];

        [effectStack addObject:[self getHblurEffect:s]];
        
        [self addChild:parent z:0];
		//[self addChild:renderTexture z:0];
		
		
		//[self addNewSpriteAtPosition:ccp(s.width/2, s.height/2)];
        
        // add a bunch of new sprites in a grid
        //int n_wide = s.width / 64;
        //int n_height = s.height / 64 / 2;
        for(int ii = 0; ii < 18; ii++) {
            for(int jj = 0; jj < 10; jj++) {
                CGFloat posX = 32 + ii * 40;
                CGFloat posY = 32 + jj * 40;
                [self addNewSpriteAtPosition:CGPointMake(posX, posY)];
            }
        }
		
        /*
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		[self addChild:label z:0];
		[label setColor:ccc3(0,0,255)];
		label.position = ccp( s.width/2, s.height-50);
		*/
        
        // register for accelerometer callbacks
        UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
        accelerometer.delegate = self;
        accelerometer.updateInterval = 0.25;
        
		[self scheduleUpdate];
	}
	return self;
}

-(void) visit {
    CCRenderTexture *lastTexture = nil;
    for(CCRenderTexture* texture in effectStack) {
        [texture beginWithClear:0.0f g:0.0f b:0.0f a:1.0f ];
        if(!lastTexture) {
            [parent visit];
        } else {
            [lastTexture visit];
        }
        [texture end];
        lastTexture = texture;
    }

    [lastTexture visit];
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	//delete m_debugDraw;
	//m_debugDraw = NULL;
    //glDeleteFramebuffers(1, &renderTarget);
    //glDeleteFramebuffers(1, &blurTarget);
    [UIAccelerometer sharedAccelerometer].delegate = nil;
    [effectStack release];
    
	[super dealloc];
}	

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}];
	
	// Achievement Menu Item using blocks
	CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
		
		
		GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
		achivementViewController.achievementDelegate = self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:achivementViewController animated:YES];
		
		[achivementViewController release];
	}];
	
	// Leaderboard Menu Item using blocks
	CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
		
		
		GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
		leaderboardViewController.leaderboardDelegate = self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:leaderboardViewController animated:YES];
		
		[leaderboardViewController release];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, reset, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2)];
	
	
	[self addChild: menu z:-1];	
}

-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	//m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	//world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	//m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

/*
-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
}
*/

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	PhysicsSprite *sprite = [PhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(32 * idx,32 * idy,32,32)];						
	[parent addChild:sprite];
	
	sprite.position = ccp( p.x, p.y);
	
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2CircleShape dynamicCircle;
    dynamicCircle.m_radius = 0.5;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicCircle;	
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.1f;
	body->CreateFixture(&fixtureDef);
	
	[sprite setPhysicsBody:body];
}

-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 3;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
    const CGFloat timePerStep = 0.02;
    dt += leftoverTime;
    while(dt > timePerStep) {
        world->Step(timePerStep, velocityIterations, positionIterations);
        dt -= timePerStep;
    }
    leftoverTime = dt;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		
		[self addNewSpriteAtPosition: location];
	}
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    CGFloat ddx = acceleration.x * 10;
    CGFloat ddy = -acceleration.y * 10;
    b2Vec2 gravity;
    gravity.Set(ddy, ddx);
    NSLog(@"Gravity is %f %f", ddx, ddy);
    world->SetGravity(gravity);
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

@end
