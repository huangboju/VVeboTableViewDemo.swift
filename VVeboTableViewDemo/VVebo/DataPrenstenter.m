//
//  DataPrenstenter.m
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/29.
//  Copyright © 2017年 Johnil. All rights reserved.
//

#import "DataPrenstenter.h"
#import "NSString+Additions.h"
#import "VVeboTableViewDemo-Swift.h"

#define SIZE_GAP_LEFT 15
#define SIZE_GAP_TOP 13
#define SIZE_AVATAR 40
#define SIZE_GAP_BIG 10
#define SIZE_GAP_IMG 5
#define SIZE_GAP_SMALL 5
#define SIZE_IMAGE 80
#define SIZE_FONT 17
#define SIZE_FONT_NAME (SIZE_FONT-3)
#define SIZE_FONT_SUBTITLE (SIZE_FONT-8)
#define FontWithSize(s) [UIFont fontWithName:@"HelveticaNeue-Light" size:s]
#define SIZE_FONT_CONTENT 17
#define SIZE_FONT_SUBCONTENT (SIZE_FONT_CONTENT-1)

@implementation DataPrenstenter

//读取信息
+ (void)loadData:(void (^)(NSMutableDictionary*))handle {
    NSArray *temp = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"plist"]];
    for (NSDictionary *dict in temp) {
        NSDictionary *user = dict[@"user"];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        data[@"avatarUrl"] = user[@"avatar_large"];
        data[@"name"] = user[@"screen_name"];
        NSString *from = [dict valueForKey:@"source"];
        if (from.length>6) {
            NSInteger start = [from indexOf:@"\">"]+2;
            NSInteger end = [from indexOf:@"</a>"];
            from = [from substringFromIndex:start toIndex:end];
        } else {
            from = @"未知";
        }
        data[@"time"] = @"2015-05-25";
        data[@"from"] = from;
        [self setCommentsFrom:dict toData:data];
        [self setRepostsFrom:dict toData:data];
        data[@"text"] = dict[@"text"];
        
        NSDictionary *retweet = [dict valueForKey:@"retweeted_status"];
        if (retweet) {
            NSMutableDictionary *subData = [NSMutableDictionary dictionary];
            NSDictionary *user = retweet[@"user"];
            subData[@"avatarUrl"] = user[@"avatar_large"];
            subData[@"name"] = user[@"screen_name"];
            subData[@"text"] = [NSString stringWithFormat:@"@%@: %@", subData[@"name"], retweet[@"text"]];
            [self setPicUrlsFrom:retweet toData:subData];
            
            {
                float width = [UIScreen screenWidth]-SIZE_GAP_LEFT*2;
                CGSize size = [subData[@"text"] sizeWithConstrainedToWidth:width fromFont:FontWithSize(SIZE_FONT_SUBCONTENT) lineSpace:5];
                NSInteger sizeHeight = (size.height+.5);
                subData[@"textRect"] = [NSValue valueWithCGRect:CGRectMake(SIZE_GAP_LEFT, SIZE_GAP_BIG, width, sizeHeight)];
                sizeHeight += SIZE_GAP_BIG;
                if (subData[@"pic_urls"] && [subData[@"pic_urls"] count]>0) {
                    sizeHeight += (SIZE_GAP_IMG+SIZE_IMAGE+SIZE_GAP_IMG);
                }
                sizeHeight += SIZE_GAP_BIG;
                subData[@"frame"] = [NSValue valueWithCGRect:CGRectMake(0, 0, [UIScreen screenWidth], sizeHeight)];
            }
            data[@"subData"] = subData;
        } else {
            [self setPicUrlsFrom:dict toData:data];
        }
        
        {
            float width = [UIScreen screenWidth]-SIZE_GAP_LEFT*2;
            CGSize size = [data[@"text"] sizeWithConstrainedToWidth:width fromFont:FontWithSize(SIZE_FONT_CONTENT) lineSpace:5];
            NSInteger sizeHeight = (size.height+.5);
            data[@"textRect"] = [NSValue valueWithCGRect:CGRectMake(SIZE_GAP_LEFT, SIZE_GAP_TOP+SIZE_AVATAR+SIZE_GAP_BIG, width, sizeHeight)];
            sizeHeight += SIZE_GAP_TOP+SIZE_AVATAR+SIZE_GAP_BIG;
            if (data[@"pic_urls"] && [data[@"pic_urls"] count]>0) {
                sizeHeight += (SIZE_GAP_IMG+SIZE_IMAGE+SIZE_GAP_IMG);
            }
            
            NSMutableDictionary *subData = [data valueForKey:@"subData"];
            if (subData) {
                sizeHeight += SIZE_GAP_BIG;
                CGRect frame = [subData[@"frame"] CGRectValue];
                CGRect textRect = [subData[@"textRect"] CGRectValue];
                frame.origin.y = sizeHeight;
                subData[@"frame"] = [NSValue valueWithCGRect:frame];
                textRect.origin.y = frame.origin.y+SIZE_GAP_BIG;
                subData[@"textRect"] = [NSValue valueWithCGRect:textRect];
                sizeHeight += frame.size.height;
                data[@"subData"] = subData;
            }
            
            sizeHeight += 30;
            data[@"frame"] = [NSValue valueWithCGRect:CGRectMake(0, 0, [UIScreen screenWidth], sizeHeight)];
        }

        handle(data);
    }
}

+ (void)setCommentsFrom:(NSDictionary *)dict toData:(NSMutableDictionary *)data{
    NSInteger comments = [dict[@"reposts_count"] integerValue];
    if (comments>=10000) {
        data[@"reposts"] = [NSString stringWithFormat:@"  %.1fw", comments/10000.0];
    } else {
        if (comments>0) {
            data[@"reposts"] = [NSString stringWithFormat:@"  %ld", (long)comments];
        } else {
            data[@"reposts"] = @"";
        }
    }
}

+ (void)setRepostsFrom:(NSDictionary *)dict toData:(NSMutableDictionary *)data{
    NSInteger comments = [dict[@"comments_count"] integerValue];
    if (comments>=10000) {
        data[@"comments"] = [NSString stringWithFormat:@"  %.1fw", comments/10000.0];
    } else {
        if (comments>0) {
            data[@"comments"] = [NSString stringWithFormat:@"  %ld", (long)comments];
        } else {
            data[@"comments"] = @"";
        }
    }
}

+ (void)setPicUrlsFrom:(NSDictionary *)dict toData:(NSMutableDictionary *)data{
    NSArray *pic_urls = [dict valueForKey:@"pic_urls"];
    NSString *url = [dict valueForKey:@"thumbnail_pic"];
    NSArray *pic_ids = [dict valueForKey:@"pic_ids"];
    if (pic_ids && pic_ids.count>1) {
        NSString *typeStr = @"jpg";
        if (pic_ids.count>0||url.length>0) {
            typeStr = [url substringFromIndex:url.length-3];
        }
        NSMutableArray *temp = [NSMutableArray array];
        for (NSString *pic_url in pic_ids) {
            [temp addObject:@{@"thumbnail_pic": [NSString stringWithFormat:@"http://ww2.sinaimg.cn/thumbnail/%@.%@", pic_url, typeStr]}];
        }
        data[@"pic_urls"] = temp;
    } else {
        data[@"pic_urls"] = pic_urls;
    }
}

@end
