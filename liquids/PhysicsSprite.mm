/*
 *  Copyright 2015 Brian Taylor
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#import "PhysicsSprite.h"

// Needed PTM_RATIO
#import "HelloWorldLayer.h"

#pragma mark - PhysicsSprite
@implementation PhysicsSprite

-(void) setPhysicsBody:(b2Body *)body
{
        body_ = body;
}

// this method will only get called if the sprite is batched.
// return YES if the physics values (angles, position ) changed
// If you return NO, then nodeToParentTransform won't be called.
-(BOOL) dirty
{
        return YES;
}

// returns the transform matrix according the Chipmunk Body values
-(CGAffineTransform) nodeToParentTransform
{
        b2Vec2 pos  = body_->GetPosition();

        float x = pos.x * PTM_RATIO;
        float y = pos.y * PTM_RATIO;

        if ( !isRelativeAnchorPoint_ ) {
                x += anchorPointInPoints_.x;
                y += anchorPointInPoints_.y;
        }

        // Make matrix
        float radians = body_->GetAngle();
        float c = cosf(radians);
        float s = sinf(radians);

        if( ! CGPointEqualToPoint(anchorPointInPoints_, CGPointZero) ){
                x += c*-anchorPointInPoints_.x + -s*-anchorPointInPoints_.y;
                y += s*-anchorPointInPoints_.x + c*-anchorPointInPoints_.y;
        }

        // Rot, Translate Matrix
        transform_ = CGAffineTransformMake( c,  s,
                                                                           -s,	c,
                                                                           x,	y );

        return transform_;
}

-(void) dealloc
{
        //
        [super dealloc];
}

@end
