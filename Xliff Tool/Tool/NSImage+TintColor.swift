//
//  NSImage+TintColor.swift
//  Xliff Tool
//
//  Created by zhaoxin on 2022/12/9.
//  Copyright © 2022 zhaoxin. All rights reserved.
//

import Foundation
import AppKit

extension NSImage {
   func image(withTintColor tintColor: NSColor) -> NSImage {
       guard isTemplate else { return self }
       guard let copiedImage = self.copy() as? NSImage else { return self }
       copiedImage.lockFocus()
       tintColor.set()
       let imageBounds = NSMakeRect(0, 0, copiedImage.size.width, copiedImage.size.height)
       imageBounds.fill(using: .sourceAtop)
       copiedImage.unlockFocus()
       copiedImage.isTemplate = false
       return copiedImage
   }
}
