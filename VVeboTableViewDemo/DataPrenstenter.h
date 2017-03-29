//
//  DataPrenstenter.h
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/29.
//  Copyright © 2017年 Johnil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataPrenstenter : NSObject
+ (void)loadData:(void (^)(NSMutableDictionary*))handle;
@end
