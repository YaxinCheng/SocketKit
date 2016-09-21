//
//  Socket.swift
//  SocketKit
//
//  Created by Yaxin Cheng on 2016-09-21.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public final class Socket: NSObject, StreamDelegate {
	public let address: String
	public let port: Int
	private var inStream: InputStream?
	private var outStream: OutputStream?
	private var buffer: [UInt8]
	public var isConnected: Bool
	private var isWritable: Bool
	private var readComplete: ((String?) -> Void)?
	
	public init(address: String, port: Int) throws {
		isConnected = false
		isWritable = false
		buffer = [UInt8](repeating: 0, count: 200)
		self.address = address
		self.port = port
		Stream.getStreamsToHost(withName: address, port: port, inputStream: &inStream, outputStream: &outStream)
		super.init()
		guard inStream != nil && outStream != nil else { throw SocketError.connectionFailed }
		inStream?.delegate = self
		outStream?.delegate = self
		inStream?.open()
		outStream?.open()
	}
	
	public func write(value: String) throws {
		guard isWritable else { throw SocketError.notWritable }
		guard let data = value.data(using: .utf8) else { throw SocketError.dataEncodingFailed }
		_ = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
	}
	
	public func read(complete: @escaping (String?) -> Void) {
		readComplete = complete
	}
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case Stream.Event.openCompleted:
			isConnected = true
		case Stream.Event.hasBytesAvailable:
			inStream?.read(&buffer, maxLength: buffer.count)
			let valueRead = String(bytes: buffer, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
			readComplete?(valueRead)
		case Stream.Event.hasSpaceAvailable:
			isWritable = true
		default:
			break
		}
	}
	
	deinit {
		inStream?.close()
		outStream?.close()
		inStream = nil
		outStream = nil
	}
}
