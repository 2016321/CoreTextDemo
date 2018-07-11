//
//  CoreTextBaseView.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "CoreTextBaseView.h"
#import <CoreText/CoreText.h>

@implementation CoreTextBaseView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    //1.获取绘制的上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //2.初始化要绘制的区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path , NULL , self.bounds);
    
    //3.对坐标进行转换
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context , 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    //4.
    NSAttributedString *att = [self getAtt];
    
    //5.初始化绘制区域的工厂对象
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)att);
    
    //6.初始化绘制区域
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [att length]), path , NULL);
    
    //7.1直接绘制
//    CTFrameDraw(frame, context);
    //7.2 遍历所有的行进行绘制
//    CFArrayRef lines = CTFrameGetLines(frame);
//    CFIndex lineNumber =  CFArrayGetCount(lines);
//    CGPoint lineOrigins[lineNumber];
//    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
//    for (int i = 0 ; i < lineNumber; i++) {
//        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
//        CGContextSetTextPosition(context, lineOrigins[i].x, lineOrigins[i].y);
//        CTLineDraw(line , context);
//    }
    //7.3 遍历本行的CTRun进行绘制
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineNumber =  CFArrayGetCount(lines);
    CGPoint lineOrigins[lineNumber];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    for (int i = 0 ; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGContextSetTextPosition(context, lineOrigins[i].x, lineOrigins[i].y);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runNumber = CFArrayGetCount(runs);
        for (int j = 0; j < runNumber; j++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            CTRunDraw(run, context, CFRangeMake(0, 0));
        }
    }
    
    //8.释放之前申请的内存
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(frame);
}

- (NSMutableAttributedString *)getAtt{
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:@"Core Text, Core Text, Core Text, Core Text, Core Text, Core Text, "];
    CTFontRef font = CTFontCreateWithName(CFSTR("PingFang SC"), 40, NULL);
    [att addAttribute:(id)kCTFontAttributeName value:(__bridge id)font  range:NSMakeRange(0, att.length)];
    long number = 10;
    CFNumberRef num = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt8Type,&number);
    [att addAttribute:(id)kCTKernAttributeName value:(__bridge id)num range:NSMakeRange(10, 4)];
    return att;
}

@end
