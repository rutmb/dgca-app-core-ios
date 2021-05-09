/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-app-core-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//
//  ASN1.swift
//  DGCAVerifier
//
//  Created by Yannick Spreen on 5/7/21.
//
//  Based on ASN1Encoder.swift in ehn-digital-green-development/ValidationCore
//  by Christian Kollmann
//

import Foundation

public class ASN1 {

  public static func encode(_ data: Data, _ digestLengthInBytes: Int? = nil) -> Data {
    let digestLengthInBytes = digestLengthInBytes ?? 32 // for ES256
    let sigR = encodeInt(data.prefix(data.count - digestLengthInBytes))
    let sigS = encodeInt(data.suffix(digestLengthInBytes))
    let tagSequence: UInt8 = 0x30
    return Data([tagSequence, UInt8(sigR.count + sigS.count)] + sigR + sigS)
  }

  private static func encodeInt(_ data: Data) -> Data {
    let firstBitIsSet: UInt8 = 0b10000000 // would be decoded as a negative number
    let tagInteger: UInt8 = 0x02
    if (data[0] >= firstBitIsSet) {
      return Data([tagInteger, UInt8(data.count + 1)] + [0] + data)
    } else if (data.first! == 0x00) {
      return encodeInt(data.dropFirst())
    } else {
      return Data([tagInteger, UInt8(data.count)] + data)
    }
  }

  public static func decode(from data: Data) -> Data {
    var data = data.uint
    if data[0] == 0x30 {
      data = data.suffix(data.count - 2)
    }
    let c = Int(data[1])
    let r = decodeInt([UInt8](data.prefix(c + 2)))
    var s = decodeInt([UInt8](data.suffix(data.count - c - 2)))
    while s.count < 32 { // 32 for ES256
      s = [UInt8(0)] + s
    }
    return Data(r + s)
  }

  private static func decodeInt(_ data: [UInt8]) -> [UInt8] {
    var data = [UInt8](data.suffix(data.count - 2))
    while data[0] == 0 {
      data = [UInt8](data.suffix(data.count - 1))
    }
    return [UInt8](data)
  }

}
