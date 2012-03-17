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
    hblur.sprite.shaderProgram = [self loadProgram:@"horizontal_Blur.fsh"];
    return hblur;
}

- (CCRenderTexture*)getVblurEffect:(CGSize)s {
    CCRenderTexture *hblur = [CCRenderTexture renderTextureWithWidth:s.width height:s.height];
    hblur.position = CGPointMake(s.width / 2, s.height / 2);
    hblur.sprite.shaderProgram = [self loadProgram:@"vertical_Blur.fsh"];
    return hblur;
}

- (CCRenderTexture*)getThreshholdEffect:(CGSize)s {
    CCRenderTexture *hblur = [CCRenderTexture renderTextureWithWidth:s.width height:s.height];
    hblur.position = CGPointMake(s.width / 2, s.height / 2);
    hblur.sprite.shaderProgram = [self loadProgram:@"threshhold.fsh"];
    return hblur;
}

- (CCTexture2D*)makeBallTexture {
    // Build a UIImage (because CGImages seem hard to come by)
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(ballSize, ballSize), NO, 0);

    CGContextRef cg = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    CGFloat center = ballSize / 2;
    CGFloat xy = center - ballSize / 4;
    CGFloat wh = ballSize / 2;
    CGContextFillEllipseInRect(cg, CGRectMake(xy, xy, wh, wh));
    UIImage *whiteCircle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
#if 1
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *workingImage = [CIImage imageWithCGImage:[whiteCircle CGImage]];
    
    // filter it
    CIFilter *filter = [CIFilter filterWithName:@"CIBoxBlur"];
    [filter setDefaults];
    [filter setValue:workingImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:12.0] forKey:@"inputRadius"];

    CIImage *blurredImage = [filter outputImage];
    
    NSArray * allFilterNames = [CIFilter filterNamesInCategories:nil];

    
    CGImageRef filteredImage = [context createCGImage:blurredImage fromRect:[blurredImage extent]];
    return [[[CCTexture2D alloc] initWithCGImage:filteredImage resolutionType:kCCResolutionUnknown] autorelease];
#else
    return [[CCTexture2D alloc] initWithCGImage:[whiteCircle CGImage] resolutionType:kCCResolutionUnknown];
#endif
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
        opQueue = [[NSOperationQueue alloc] init];
        opQueue.maxConcurrentOperationCount = 1;
        ballSize = 64;
		leftoverTime = 0;
        
		// init physics
		[self initPhysics];
        
		// create reset button
		//[self createMenu];
		
		//Set up sprite
		
		// Use batch node. Faster
		parent = [CCSpriteBatchNode batchNodeWithTexture:[self makeBallTexture] capacity:200];
		spriteTexture_ = [parent texture];
        
        effectStack = [[NSMutableArray alloc] init];
        /*
        [effectStack addObject:[self getHblurEffect:s]];
        [effectStack addObject:[self getVblurEffect:s]];
        */
        [effectStack addObject:[self getThreshholdEffect:s]];
        
        [self addChild:parent z:0];
        
        // add a bunch of new sprites in a grid
        int nBallsToFill = s.width * s.height / (16.0 * 16.0);
        int nBalls = nBallsToFill / 4; // 1/3rd full
        
        CGFloat lastY = 16.0;
        CGFloat initialX = 16.0;
        CGFloat lastX = initialX;
        
        for(int ii = 0; ii < nBalls; ++ii) {
            if(lastX > s.width - 16.0) {
                lastY += 16.0;
                lastX = initialX;
            } else {
                lastX += 16.0;
            }
            
            [self addNewSpriteAtPosition:CGPointMake(lastX, lastY)];
        }
        
		[self scheduleUpdate];
	}
	return self;
}

-(void) visit {
#if 0
    CCRenderTexture *lastTexture = nil;
    for(CCRenderTexture* texture in effectStack) {
        [texture beginWithClear:0.0f g:0.0f b:0.0f a:0.0f ];
        if(!lastTexture) {
            [parent visit];
        } else {
            [lastTexture visit];
        }
        [texture end];
        lastTexture = texture;
    }

    [lastTexture visit];
#else
    [parent visit];
#endif
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
    [effectStack release];
    [opQueue release];
    
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
	
	//world->SetContinuousPhysics(true);
	
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

	PhysicsSprite *sprite = [PhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,0,ballSize,ballSize)];
    sprite.scale = 0.5;
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
    dynamicCircle.m_radius = 0.05;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicCircle;	
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.0f;
    fixtureDef.restitution = 0.3f;
    
	body->CreateFixture(&fixtureDef);
	
	[sprite setPhysicsBody:body];
}

-(void) update: (ccTime) dt
{
	int32 velocityIterations = 1;
	int32 positionIterations = 1;
	
    const CGFloat timePerStep = 0.02;
    dt += leftoverTime;
    while(dt > timePerStep) {
        [opQueue addOperationWithBlock:^(void) {
            world->Step(timePerStep, velocityIterations, positionIterations);
        }];
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
		
		// FIXME [self addNewSpriteAtPosition: location];
	}
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    CGFloat ddx = acceleration.x * 10;
    CGFloat ddy = -acceleration.y * 10;
    b2Vec2 gravity;
    gravity.Set(ddy, ddx);
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
