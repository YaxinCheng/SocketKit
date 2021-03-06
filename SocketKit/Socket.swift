//
//  Socket.swift
//  SocketKit
//
//  Created by Yaxin Cheng on 2016-09-21.
//  Copyright © 2016 Yaxin Cheng. All rights reserved.
//

import Foundation

public final class Socket: NSObject, StreamDelegate {
	/**
	Destination socket address
	*/
	public let address: String
	/**
	Destination socket port
	*/
	public let port: Int
	/**
	Input stream from the socket
	*/
	private var inStream: InputStream?
	/**
	Output stream from the socket
	*/
	private var outStream: OutputStream?
	/**
	Buffer from the socket
	*/
	private var buffer: [UInt8]
	/**
	The connection status of the socket
	*/
	public var isConnected: Bool
	/**
	The writability of the socket
	*/
	private var isWritable: Bool
	/**
	Callback closures when new value is read from the socket
	*/
	private var readComplete: ((String?) -> Void)?
	private var readDataComplete: ((Data?) -> Void)? = nil
	/**
	A separate queue for socket events
	*/
	private let queue: DispatchQueue
	/**
	Constructor of a socket connector.
	- Parameter address: A string value specify which socket address needs to be connected to
	- Parameter port: An int value about the port opens
	- throws: Failed connection to socket: SocketError.connectionFailed
	*/
	public init(address: String, port: Int) throws {
		queue = DispatchQueue(label: "socketQueue")
		isConnected = false
		isWritable = false
		buffer = [UInt8](repeating: 0, count: 200)
		self.address = address
		self.port = port
		Stream.getStreamsToHost(withName: address, port: port, inputStream: &inStream, outputStream: &outStream)
		super.init()
		guard inStream != nil && outStream != nil else { throw SocketError.connectionFailed }
		inStream?.schedule(in: .current, forMode: .defaultRunLoopMode)
		outStream?.schedule(in: .current, forMode: .defaultRunLoopMode)
		inStream?.delegate = self
		outStream?.delegate = self
		inStream?.open()
		outStream?.open()
	}
	
	/**
	Function accepts a string value and writes to the socket side
	- parameter value: A string value needs to be written
	- throws: Socket is not connected: Socket.notConnected
		Socket is not writable: SocketError.notWritable
		Failed to encode the string: SocketError.dataEncodingFailed
	*/
	public func write(value: String) throws {
		guard isConnected else { throw SocketError.notConnected }
		guard isWritable else { throw SocketError.notWritable }
		guard let data = value.data(using: .utf8) else { throw SocketError.dataEncodingFailed }
		try! write(data: data)
	}
	
	/**
	Function accepts a string value and writes to the socket side
	- parameter data: A binary data value needs to be written
	- throws: Socket is not connected: Socket.notConnected
		Socket is not writable: SocketError.notWritable
	*/
	public func write(data: Data) throws {
		guard isConnected else { throw SocketError.notConnected }
		guard isWritable else { throw SocketError.notWritable }
		queue.async {
				_ = data.withUnsafeBytes { [weak self] in
					self?.outStream?.write($0, maxLength: data.count)
			}
		}
	}
	
	/**
	Function accepts a call back closure and read value from socket side
	- parameter complete: A call back closure accepts a string value from server
	- throws: Socket is not connected: Socket.notConnected
	*/
	public func read(complete: @escaping (String?) -> Void) throws {
		guard isConnected else { throw SocketError.notConnected }
		readDataComplete = nil
		readComplete = complete
	}
	
	/**
	Function accepts a call back closure and read value from socket side
	- parameter complete: A call back closure accepts a binary data value from server
	- throws: Socket is not connected: Socket.notConnected
	*/
	public func readData(complete: @escaping (Data?) -> Void) throws {
		guard isConnected else { throw SocketError.notConnected }
		readComplete = nil
		readDataComplete = complete
	}
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
		case Stream.Event.openCompleted:// Successfully connected
			isConnected = true
		case Stream.Event.hasBytesAvailable:// Read in value from socket
			queue.async { [unowned self] in
				self.inStream?.read(&self.buffer, maxLength: self.buffer.count)
				if let complete = self.readDataComplete {
					let data = Data(bytes: self.buffer)
					DispatchQueue.main.async {
							complete(data)
					}
				} else {
					let valueRead = String(bytes: self.buffer, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
					DispatchQueue.main.async {
							self.readComplete?(valueRead)
					}
				}
			}
		case Stream.Event.hasSpaceAvailable:// Check socket writable
			isWritable = true
		case Stream.Event.endEncountered, Stream.Event.errorOccurred:// Connection closed by server or failed connection
			isConnected = false
			inStream?.close()
			inStream?.remove(from: .current, forMode: .defaultRunLoopMode)
			outStream?.close()
			outStream?.remove(from: .current, forMode: .defaultRunLoopMode)
			inStream = nil
			outStream = nil
			readComplete = nil
		default:
			break
		}
	}
}
