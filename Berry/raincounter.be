import persist
import webserver
import string
import mqtt

var rain_per_tip = 0.2  # liters per tilt (0.3mm precipitation)
var needs_save = false

if !persist.has("total_rain")
    persist.total_rain = 0.0
end

if !persist.has("today_rain")
    persist.today_rain = 0.0
end

def handle_switch_state(value)
    if value == 0
        persist.total_rain += rain_per_tip
        persist.today_rain += rain_per_tip
        needs_save = true
        print(format("Rain-Counter erhöht: %.2f L", persist.total_rain))
    end
end

def periodic_save()
    if needs_save
        persist.save()
        needs_save = false
        print("Raindaten sicher im Flash gespeichert.")
    end
    tasmota.set_timer(300000, periodic_save)
end

# MQTT Home Assistant Discovery
def mqtt_discovery()
    if !mqtt.connected() return end
    
    var mac_raw = tasmota.wifi()['mac']
    var mac = string.replace(mac_raw, ":", "")
    var topic = tasmota.cmd("Status")["Status"]["Topic"]
    
    # Konfiguration für beide Sensoren
    # s[0]=ID, s[1]=Name, s[2]=JSON-Key, s[3]=StateClass
    var sensors = [
        ["total", "Rain Total", "Total", "total_increasing"],
        ["today", "Rain Today", "Today", "total_increasing"]
    ]

    for s : sensors
        var t_url = format("homeassistant/sensor/%s_rain_%s/config", mac, s[0])
        var payload = format(
            "{\"name\":\"%s\"," +
            "\"stat_t\":\"tele/%s/SENSOR\"," +
            "\"unit_of_meas\":\"mm\"," +
            "\"dev_cla\":\"precipitation\"," + 
            "\"stat_cla\":\"%s\"," +
            "\"val_tpl\":\"{{value_json.Rain_%s | default(0)}}\"," +
            "\"avty\":[{\"t\":\"tele/%s/LWT\",\"pl_avail\":\"Online\",\"pl_not_avail\":\"Offline\"}]," +
            "\"uniq_id\":\"%s_rain_%s\"," +
            "\"dev\":{\"ids\":[\"%s_rain\"],\"name\":\"RainSensor\",\"mf\":\"Tasmota\",\"mdl\":\"Rain Gauge\"}}",
            s[1], topic, s[3], s[2], topic, mac, s[0], mac
        )
        mqtt.publish(t_url, payload, true)
    end
    log("MQTT discovery (precipitation) published.")
end

class RainDisplay : Driver
  
  def web_sensor()
    var total = persist.has("total_rain") ? persist.total_rain : 0.0
    var today = persist.has("today_rain") ? persist.today_rain : 0.0

    var msg1 = format("{s}Total Rain{m}%.2f mm{e}", total)
    tasmota.web_send(msg1)

    var msg2 = format("{s}Today Rain{m}%.2f mm{e}", today)
    tasmota.web_send(msg2)
  end

  def json_append()
    var total = persist.has("total_rain") ? persist.total_rain : 0.0
    var today = persist.has("today_rain") ? persist.today_rain : 0.0

    var msg = string.format(
    ",\"Rain_Total\":%.2f,\"Rain_Today\":%.2f", 
    total, today)
    tasmota.response_append(msg)
  end

end

var display_driver = RainDisplay()

def rain_reset()
    persist.total_rain = 0.0
    persist.save()
    tasmota.resp_cmnd(format('{"RainAllReset":%2f}', persist.total_rain))
end

def rain_today_reset()
    persist.today_rain = 0.0
    persist.save()
    tasmota.resp_cmnd(format('{"RainTodayReset":%2f}', persist.today_rain))
end

tasmota.add_cmd('RainAllReset', rain_reset)
tasmota.add_cmd('RainTodayReset', rain_today_reset)

# Publish discovery when MQTT connects
mqtt_discovery()
tasmota.add_rule("Mqtt#Connected", mqtt_discovery)

# Add driver
tasmota.add_driver(display_driver)

tasmota.add_rule("Switch1#state", handle_switch_state)
periodic_save()
tasmota.add_cron("0 0 0 * * *", rain_today_reset, "rain_today_reset")
