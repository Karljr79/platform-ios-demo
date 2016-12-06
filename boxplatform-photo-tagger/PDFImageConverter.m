//
//  PDFImageConverter.m
//
//  Created by Sorin Nistor on 4/21/11.
//  Copyright 2011 iPDFdev.com. All rights reserved.
//  @see: http://ipdfdev.com/2011/04/22/convert-an-image-to-pdf-on-the-iphone-and-ipad/

#import "PDFImageConverter.h"


@implementation PDFImageConverter

+ (NSData *) convertImageToPDF: (UIImage *) image {
    return [PDFImageConverter convertImageToPDF: image withResolution: 96];
}

+ (NSData *) convertImageToPDF: (UIImage *) image withResolution: (double) resolution {
    return [PDFImageConverter convertImageToPDF: image withHorizontalResolution: resolution verticalResolution: resolution];
}

+ (NSData *) convertImageToPDF: (UIImage *) image withHorizontalResolution: (double) horzRes verticalResolution: (double) vertRes {
    if ((horzRes <= 0) || (vertRes <= 0)) {
        return nil;
    }
    
    double pageWidth = image.size.width * image.scale * 72 / horzRes;
    double pageHeight = image.size.height * image.scale * 72 / vertRes;
    
    NSMutableData *pdfFile = [[NSMutableData alloc] init];
    CGDataConsumerRef pdfConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfFile);
    // The page size matches the image, no white borders.
    CGRect mediaBox = CGRectMake(0, 0, pageWidth, pageHeight);
    CGContextRef pdfContext = CGPDFContextCreate(pdfConsumer, &mediaBox, NULL);
    
    CGContextBeginPage(pdfContext, &mediaBox);
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
            CGContextTranslateCTM(pdfContext, pageWidth, pageHeight);
            CGContextScaleCTM(pdfContext, -1, -1);
            break;
            
        case UIImageOrientationLeft:
            mediaBox.size.width = pageHeight;
            mediaBox.size.height = pageWidth;
            CGContextTranslateCTM(pdfContext, pageWidth, 0);
            CGContextRotateCTM(pdfContext, M_PI / 2);
            break;
            
        case UIImageOrientationRight:
            mediaBox.size.width = pageHeight;
            mediaBox.size.height = pageWidth;
            CGContextTranslateCTM(pdfContext, 0, pageHeight);
            CGContextRotateCTM(pdfContext, -M_PI / 2);
            break;
            
        case UIImageOrientationUp:
        default:
            break;
            
    }
    CGContextDrawImage(pdfContext, mediaBox, [image CGImage]);
    CGContextEndPage(pdfContext);
    CGContextRelease(pdfContext);
    CGDataConsumerRelease(pdfConsumer);
    
    return pdfFile;
}

+ (NSData *) convertImageToPDF: (UIImage *) image withResolution: (double) resolution maxBoundsRect: (CGRect) boundsRect pageSize: (CGSize) pageSize {
    if (resolution <= 0) {
        return nil;
    }
    
    double imageWidth  = image.size.width * image.scale * 72 / resolution;
    double imageHeight = image.size.height * image.scale * 72 / resolution;
    
    double sx = imageWidth / boundsRect.size.width;
    double sy = imageHeight / boundsRect.size.height;
    
    // At least one image edge is larger than maxBoundsRect
    if ((sx > 1) || (sy > 1)) {
        double maxScale = sx > sy ? sx : sy;
        imageWidth = imageWidth / maxScale;
        imageHeight = imageHeight / maxScale;
    }
    
    NSMutableData *pdfFile = [[NSMutableData alloc] init];
    CGDataConsumerRef pdfConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfFile);
    
    CGRect mediaBox = CGRectMake(0, 0, pageSize.width, pageSize.height);
    CGContextRef pdfContext = CGPDFContextCreate(pdfConsumer, &mediaBox, NULL);
    
    CGContextBeginPage(pdfContext, &mediaBox);
    
    // Put the image in the top left corner of the bounding rectangle
    CGRect imageBox = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextTranslateCTM(pdfContext, boundsRect.origin.x, boundsRect.origin.y + boundsRect.size.height - imageHeight);
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
            CGContextTranslateCTM(pdfContext, imageWidth, imageHeight);
            CGContextScaleCTM(pdfContext, -1, -1);
            break;
            
        case UIImageOrientationLeft:
            imageBox.size.width = imageHeight;
            imageBox.size.height = imageWidth;
            CGContextTranslateCTM(pdfContext, imageWidth, 0);
            CGContextRotateCTM(pdfContext, M_PI / 2);
            break;
            
        case UIImageOrientationRight:
            imageBox.size.width = imageHeight;
            imageBox.size.height = imageWidth;
            CGContextTranslateCTM(pdfContext, 0, imageHeight);
            CGContextRotateCTM(pdfContext, -M_PI / 2);
            break;
            
        case UIImageOrientationUp:
        default:
            break;
            
    }
    
    CGContextDrawImage(pdfContext, imageBox, [image CGImage]);
    CGContextEndPage(pdfContext);
    CGContextRelease(pdfContext);
    CGDataConsumerRelease(pdfConsumer);
    
    return pdfFile;
}

@end
