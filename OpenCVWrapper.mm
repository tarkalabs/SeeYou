//
//  OpenCVWrapper.m
//  SeeYou
//
//  Created by Vagmi Mudumbai on 02/11/16.
//  Copyright © 2016 Vagmi Mudumbai. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/features2d/features2d.hpp>
#import <opencv2/nonfree/nonfree.hpp>
#include "opencv2/calib3d/calib3d.hpp"
#include <opencv2/imgproc/imgproc_c.h>


@implementation OpenCVWrapper

+(NSString *) openCVVersionString {
  return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+(UIImage *) processImage:(UIImage *)source {
  cv::Mat sourceMat;
  sourceMat = [OpenCVWrapper cvMatFromUIImage:source];
  
  cv::Mat grayMat;
  
  cv::cvtColor(sourceMat, grayMat, CV_BGR2GRAY);
  
  int minHessian = 400;
  
  cv::SurfFeatureDetector detector(minHessian);
  
  std::vector<cv::KeyPoint> keypoints_object;
  
  detector.detect( grayMat, keypoints_object );
  static CvScalar red_color[] ={255,0,0};

  for(int i = 0; i < keypoints_object.size(); i++ )
  {
    
    cv::KeyPoint kp = keypoints_object[i];
    CvPoint center;
    int radius;
    center.x = cvRound(kp.pt.x);
    center.y = cvRound(kp.pt.y);
    radius = cvRound(kp.size*1.2/9.*2);
    
    cv::circle(sourceMat, center, radius, red_color[0]);
  }
  return [OpenCVWrapper UIImageFromCVMat:sourceMat];
}

+(UIImage *) matchImage:(UIImage *)source withScene:(UIImage *)scene {
  cv::Mat sourceMat;
  sourceMat = [OpenCVWrapper cvMatFromUIImage:source];
  
  cv::Mat sceneMat;
  sceneMat = [OpenCVWrapper cvMatFromUIImage:scene];
  
  cv::Mat graySourceMat;
  cv::cvtColor(sourceMat, graySourceMat, CV_BGR2GRAY);
  
  cv::Mat graySceneMat;
  cv::cvtColor(sceneMat, graySceneMat, CV_BGR2GRAY);
  
  int minHessian = 400;
  std::vector<cv::KeyPoint> keypoints_source, keypoints_scene;
  cv::SurfFeatureDetector detector(minHessian);
  
  detector.detect( graySourceMat, keypoints_source );
  detector.detect( graySceneMat, keypoints_scene );
  
  cv::SurfDescriptorExtractor extractor;
  
  cv::Mat descriptors_source, descriptors_scene;
  extractor.compute( graySourceMat, keypoints_source, descriptors_source );
  extractor.compute( graySceneMat, keypoints_scene, descriptors_scene );
  
  cv::FlannBasedMatcher matcher;
  std::vector< cv::DMatch > matches;
  matcher.match(descriptors_source, descriptors_scene, matches);
  
  double max_dist = 0; double min_dist = 10;
  
  //-- Quick calculation of max and min distances between keypoints
  for( int i = 0; i < descriptors_source.rows; i++ )
  { double dist = matches[i].distance;
    if( dist < min_dist ) min_dist = dist;
    if( dist > max_dist ) max_dist = dist;
  }
  
  std::vector< cv::DMatch > good_matches;
  
  for( int i = 0; i < descriptors_source.rows; i++ ) {
    if( matches[i].distance < 3*min_dist ) {
      good_matches.push_back( matches[i]);
    }
  }

  cv::Mat imgMatches;
  
  cv::drawMatches( graySourceMat, keypoints_source, graySceneMat, keypoints_scene,
              good_matches, imgMatches, cv::Scalar::all(-1), cv::Scalar::all(-1),
              std::vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
  
  //-- Localize the object
  std::vector<cv::Point2f> sourcePoints;
  std::vector<cv::Point2f> scenePoints;
  
  for( int i = 0; i < good_matches.size(); i++ )
  {
    //-- Get the keypoints from the good matches
    sourcePoints.push_back( keypoints_source[ good_matches[i].queryIdx ].pt );
    scenePoints.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
  }
  
  cv::Mat H = cv::findHomography(sourcePoints, scenePoints, CV_RANSAC);
  
  //-- Get the corners from the image_1 ( the object to be "detected" )
  std::vector<cv::Point2f> source_corners(4);
  source_corners[0] = cv::Point(0,0); source_corners[1] = cv::Point( sourceMat.cols, 0 );
  source_corners[2] = cv::Point( sourceMat.cols, sourceMat.rows ); source_corners[3] = cv::Point( 0, sourceMat.rows );
  
  std::vector<cv::Point2f> scene_corners(4);
  perspectiveTransform( source_corners, scene_corners, H);
  
  //-- Draw lines between the corners (the mapped object in the scene - image_2 )
  cv::Scalar green = cv::Scalar(0, 255, 0);
  cv::line( imgMatches, scene_corners[0] + cv::Point2f( sourceMat.cols, 0), scene_corners[1] + cv::Point2f( sourceMat.cols, 0), green, 4 );
  cv::line( imgMatches, scene_corners[1] + cv::Point2f( sourceMat.cols, 0), scene_corners[2] + cv::Point2f( sourceMat.cols, 0), green, 4 );
  cv::line( imgMatches, scene_corners[2] + cv::Point2f( sourceMat.cols, 0), scene_corners[3] + cv::Point2f( sourceMat.cols, 0), green, 4 );
  cv::line( imgMatches, scene_corners[3] + cv::Point2f( sourceMat.cols, 0), scene_corners[0] + cv::Point2f( sourceMat.cols, 0), green, 4 );

  
  return [OpenCVWrapper UIImageFromCVMat:imgMatches];
  
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  
  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
  
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                  cols,                       // Width of bitmap
                                                  rows,                       // Height of bitmap
                                                  8,                          // Bits per component
                                                  cvMat.step[0],              // Bytes per row
                                                  colorSpace,                 // Colorspace
                                                  kCGImageAlphaNoneSkipLast |
                                                  kCGBitmapByteOrderDefault); // Bitmap info flags
  
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  
  return cvMat;
}
+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
  
  if (cvMat.elemSize() == 1) {
    colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
    colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                      cvMat.rows,                                 //height
                                      8,                                          //bits per component
                                      8 * cvMat.elemSize(),                       //bits per pixel
                                      cvMat.step[0],                            //bytesPerRow
                                      colorSpace,                                 //colorspace
                                      kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                      provider,                                   //CGDataProviderRef
                                      NULL,                                       //decode
                                      false,                                      //should interpolate
                                      kCGRenderingIntentDefault                   //intent
                                      );
  
  
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  
  return finalImage;
}

@end
