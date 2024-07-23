//
//  XCropProportionEnum.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/7/16.
//

import Foundation
public enum XCropProportionEnum: CaseIterable  {
    case original, custom, wh1x1,wh3x4,wh4x3, wh9x16, wh16x9,wh2x3,wh3x2
    
    public static var allCases: [XCropProportionEnum] {
        return [
            .original,
            .custom,
            .wh1x1,
            .wh3x4,
            .wh4x3,
            .wh9x16,
            .wh16x9,
            .wh2x3,
            .wh3x2
        ]
    }
    
    func toName() -> String {
           switch self {
           case .original:
               return "原比例"
           case .custom:
               return "自定义"
           case .wh1x1:
               return "正方形"
           case .wh3x4:
               return "3:4"
           case .wh4x3:
               return "4:3"
           case .wh9x16:
               return "9:16"
           case .wh16x9:
               return "16:9"
           case .wh2x3:
               return "2:3"
           case .wh3x2:
               return "3:2"
           }
       }

       func toImageName() -> String {
           switch self {
           case .original:
               return "whOri"
           case .custom:
               return "whCustom"
           case .wh1x1:
               return "wh1x1"
           case .wh3x4:
               return "wh3x4"
           case .wh4x3:
               return "wh4x3"
           case .wh9x16:
               return "wh9x16"
           case .wh16x9:
               return "wh16x9"
           case .wh2x3:
               return "wh2x3"
           case .wh3x2:
               return "wh3x2"
           }
       }
    
    var whRatio: CGFloat {
           switch self {
           case .original:
               return 0 // 可以根据需求返回原始比例，也可以用其他表示方式
           case .custom:
               return 0 // 自定义比例，这里返回0，具体比例需要用户输入
           case .wh1x1:
               return 1.0 / 1.0
           case .wh3x4:
               return 3.0 / 4.0
           case .wh4x3:
               return 4.0 / 3.0
           case .wh9x16:
               return 9.0 / 16.0
           case .wh16x9:
               return 16.0 / 9.0
           case .wh2x3:
               return 2.0 / 3.0
           case .wh3x2:
               return 3.0 / 2.0
           }
       }
}

public enum XClipSegmentTap:Int,CaseIterable  {
        case clip,rotate
    func toName() -> String {
        switch self {
        case .clip:
            return "裁剪"
        case .rotate:
            return "旋转"
        }
    }
    
//    func tag() -> Int {
//        switch self {
//        case .clip:
//            return 1
//        case .rotate:
//            return 2
//        }
//    }
    
}


public enum XCropRotateEnum: CaseIterable  {
    case cropLeft, cropRight,cropHor,cropVer
    
    public static var allCases: [XCropRotateEnum] {
        return [
            .cropLeft,
            .cropRight,
            .cropHor,
            .cropVer,
        ]
    }
    
    func toName() -> String {
        switch self {
        case .cropLeft:
            return "向左90"
        case .cropRight:
            return "向右90"
        case .cropHor:
            return "水平翻转"
        case .cropVer:
            return "垂直翻转"
        }
    }
    // 方法：将 XCropRotateEnum 映射到 UIImage.Orientation
     public func toImageOrientation() -> UIImage.Orientation {
          switch self {
          case .cropLeft:
              return .left
          case .cropRight:
              return .right
          case .cropHor:
              return .upMirrored
          case .cropVer:
              return .downMirrored
          }
      }
    
        func toImageName() -> String {
            switch self {
            case .cropLeft:
                return "crop_left"
            case .cropRight:
                return "crop_right"
            case .cropHor:
                return "crop_hor"
            case .cropVer:
                return "crop_ver"
            }
        }
        
    
}
