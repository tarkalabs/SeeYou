//
//  OpenCVWrapper.h
//  SeeYou
//
//  Created by Vagmi Mudumbai on 02/11/16.
//  Copyright © 2016 Vagmi Mudumbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+(NSString *) openCVVersionString;
+(UIImage *) processImage:(UIImage *)source;
+(UIImage *) matchImage:(UIImage *)source withScene:(UIImage *)scene;

@end
