//
//  PostgreSQLSSLRequest.swift
//  Async
//
//  Created by franz busch on 15.04.18.
//

import Foundation

/// SSL request returned by the server.
enum PostgreSQLSSLRequest: UInt8, Decodable {

    case S = 83
    case N = 78

}
