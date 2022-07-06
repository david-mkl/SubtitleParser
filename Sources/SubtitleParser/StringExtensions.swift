//
//  File.swift
//  
//
//  Created by David Lawrence on 7/4/22.
//

import Foundation

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        if self.count < toLength {
          return String(repeatElement(character, count: toLength - self.count)) + self
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: self.count - toLength)
        return String(self[startIndex...])
      }
}
