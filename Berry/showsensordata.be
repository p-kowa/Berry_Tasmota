def showsensor()
  import json
  import string
  var sens = json.load(tasmota.read_sensors())
  
  # Find all SEN0600 sensors (now nested structure)
  var sensor_list = []
  for key: sens.keys()
    if string.find(key, 'SEN0600_') == 0
      var sensor_data = sens[key]
      # Check if this is a nested object with Humidity and Temperature
      if isinstance(sensor_data, map) && sensor_data.contains('Humidity') && sensor_data.contains('Temperature')
        sensor_list.push(key)
      end
    end
  end
  
  # If no sensors found, exit
  if size(sensor_list) == 0
    tasmota.log('No SEN0600 sensors found', 2)
    return
  end
  
  # Get minutes from millis() to rotate sensors (changes every minute)
  var ms = tasmota.millis()
  var current_minute = (ms / 60000) % size(sensor_list)
  
  # Read values for current sensor (from nested structure)
  var current_sensor_key = sensor_list[current_minute]
  var sensor_obj = sens[current_sensor_key]
  
  if sensor_obj.contains('Temperature') && sensor_obj.contains('Humidity')
    var temp = sensor_obj['Temperature']
    var hum = sensor_obj['Humidity']
    var sensor_name = current_sensor_key  # e.g., "SEN0600_1"
    tasmota.cmd(f"DisplayText [sf0s2l1c1]Temp:{temp}C [l2c1]Hum:{hum}% [l5s1c1]Sensor: {sensor_name}")
    #tasmota.log(f'Displaying {sensor_name}: Temp={temp}C Hum={hum}%', 3)
  else
    tasmota.log(f'Sensor {current_sensor_key} data not found', 2)
  end
end

tasmota.set_timer(5000, showsensor)
tasmota.add_rule("Time#Minute", showsensor)