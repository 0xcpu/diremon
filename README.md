[![Xcode - Build and Analyze](https://github.com/0xcpu/diremon/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/0xcpu/diremon/actions/workflows/objective-c-xcode.yml)

# Diremon

Diremon is a lightweight _macOS_ command-line tool that watches a directory via FSEvents and logs activity to _log sinks_.
It's intended to be used for monitoring of canary tokens, sensitive files, or directories that should not be modified on _macOS_ systems (especially where the EDR doesn't monitor file system operations).

## Log sinks

Currently, Diremon supports the following log sinks:
- `file`: Logs events to `/var/log/diremon/events.log` in JSON format.

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later

## Build

1. Clone the repository
2. Open `diremon.xcodeproj` in Xcode
3. Build and run the project

## Usage

To use Diremon, you need to specify the path to the directory you want to monitor. The command is as follows:
```
sudo diremon <path to monitor>
```

### Debugging

`Debug` and `Info` log level events are logged to the console. Use `com.cpu.diremon` as the subsystem to filter logs in Console.app.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request 