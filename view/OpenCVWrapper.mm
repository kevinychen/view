//
//  OpenCVWrapper.mm
//  view
//
//  Created by Kevin Chen on 6/9/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import "OpenCVWrapper.h"

@implementation OpenCVWrapper

+ (NSString *) openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

@end
