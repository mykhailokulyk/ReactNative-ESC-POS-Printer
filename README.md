# EPSON ePOS SDK for React Native

_An unofficial React Native library for printing on an EPSON TM printer with the <strong>Epson ePOS SDK for iOS</strong> and <strong>Epson ePOS SDK for Android</strong>_


<p align="center">
  <img src="./assets/printer.png"
     alt="Printer"
/>
</p>

|  [![npm version](https://badge.fury.io/js/react-native-esc-pos-printer.svg)](https://badge.fury.io/js/react-native-esc-pos-printer)  |
|---|





1. [Installation](./docs/INSTALLATION.md)
2. [Quick Print Example](./docs/QUICK_START.md)
3. [API](./docs/API.md)
4. [SDK information (v2.27.0)](./docs/SDK.md)
5. [List of supported printers for Android](./docs/and2270.pdf)
5. [List of supported printers for iOS](./docs/and2270.pdf)
6. [Expo](./docs/EXPO.md)


## Troubleshooting

1. For now it's not possible to print and discover on Android simulator. But you can always use real device.

2. If you have an issue with using Flipper on iOS real device, please [try this](./docs/flipperWorkaround.md) workaround.

## Roadmap
- [ ] Add expo example
- [ ] Add print from react View example
- [x] Reimplement discovering to have implementation close to native SDK
- [ ] Reimplement printing to have implementation close to native SDK
- [ ] Add queue mechanism for quick print

## License

MIT
