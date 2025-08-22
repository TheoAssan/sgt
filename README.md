# SmartGlow GT

A Flutter application for smart home automation with motion tracking capabilities.

## Features

- **Home Control**: Control smart lights with manual and automatic modes
- **Motion Tracking**: Real-time motion detection and logging from LD2410C radar sensor
- **Data Logging**: Comprehensive logging of all device events
- **Power Consumption**: Monitor energy usage statistics
- **Settings**: Configure device preferences and connections

## Motion Tracker

The Motion Tracker page provides real-time monitoring of target detection data from the LD2410C radar sensor. Features include:

- **Real-time Data**: Live target detection updates via MQTT
- **Target Types**: Distinguishes between stationary, moving targets, and no targets
- **Distance & Energy**: Shows distance and energy readings from the sensor
- **Connection Status**: Visual indicator of MQTT connection status

### Data Format

The motion tracker supports various data formats from the LD2410C sensor:

- **JSON Format**: Structured data with target type, distance, and energy
- **String Format**: Text-based target detection messages
- **Target Types**: Stationary Target, Moving Target, No Target

### MQTT Integration

The motion tracker connects to a feed on Adafruit IO to receive real-time motion data and fetch historical records.

## Setup

1. Configure your `.env` file with Adafruit IO credentials:
   ```
   AIO_USERNAME=your_username
   AIO_KEY=your_aio_key
   ```

2. Ensure your LD2410C sensor is publishing data to the `ld2410c-feeds.data-log` feed

3. Run the application:
   ```bash
   flutter run
   ```

## Navigation

Access the Motion Tracker from the sidebar menu with the motion detection icon. The page includes smooth slide animations consistent with the rest of the application.
