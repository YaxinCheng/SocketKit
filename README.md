# SocketKit
A wrapped Swift toolkit for socket connection

## Requirements:
- Xcode 8.0+
- iOS 10.0+
- Swift 3.0+

## Installation:
SocketKit can be installed through Cocoapods or manual import. 
### Cocoapods:
```bash
$ gem install cocoapods
```
After installation of cocoapods, create a file named `Podfile` at the root directory of the project:

For swift3:
```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'SocketKit'
end
```
Then, run the following command:
```bash
$ pod install
```
## User Manual:
Kit imports
``` swift
import SocketKit
```
### Socket.swift
The only class will be used in the kit. All the requests go from this kit.
#### Constructor
``` swift
public init(address: String, port: Int) throws { ... }
```
SocketError.connectionFailed may be thrown from the constructor when connection failed

#### Read from socket
``` swift
public func read(complete: @escaping (String?) -> Void) throws { ... }
```
This function accepts a call back closure, which will be called when value is read from socket server side<br>
The closure accepts an optional string, and may throw out a SocketError.notConnected if the socket lost connection

```swift
public func readData(complete: @escaping (Data?) -> Void) throws { ... }
```
This function returns the raw data from the socket through the callback closure. <br>
SocketError.notConnectedd may be thrown if connection is lost

#### Write to socket
``` swift
public func write(value: String) throws { ... }
```
This function accepts an UTF-8 string value, and encode the string to binary data, then write to the socket server. <br>
SocketError.notConnected may be thrown if the socket connection is lost<br>
SocketError.notWritable may be thrown if the socket is not allowed to write values<br>
SocketError.dataEncodingFailed may be thrown if the string value cannot be encoded<br>

```swift
public func write(data: Data) throws { ... }
```
This function accepts a data value and writes to the socket<br>
SocketError.notConnected may be thrown if the socket connection is lost<br>
SocketError.notWritable may be thrown if the socket is not allowed to write values<br>

#### Connection status
``` swift
public var isConnected: Bool
```
This attribute returns true if the socket is connected, otherwise false

## License

WeatherKit is released under the MIT license. See LICENSE for details.