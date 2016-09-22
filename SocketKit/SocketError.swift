//
//  SocketError.swift
//  SocketKit
//
//  Created by Yaxin Cheng on 2016-09-21.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public enum SocketError: Error {
	case connectionFailed
	case dataEncodingFailed
	case notWritable
	case notConnected
}
