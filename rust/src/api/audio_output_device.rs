pub struct AudioOutputDeviceInfo {
    pub endpoint_id: String,
    pub name: String,
    pub is_default: bool,
}

#[cfg(all(not(frb_expand), target_os = "windows"))]
mod imp {
    use anyhow::Result;
    use windows::{
        core::BSTR,
        Win32::{
            Devices::FunctionDiscovery::PKEY_Device_FriendlyName,
            Media::Audio::{
                eConsole, eRender, IMMDevice, IMMDeviceEnumerator, MMDeviceEnumerator,
                DEVICE_STATE_ACTIVE,
            },
            System::Com::{
                CoCreateInstance, CoInitializeEx, CLSCTX_ALL, COINIT_MULTITHREADED, STGM_READ,
            },
        },
    };

    use super::AudioOutputDeviceInfo;

    pub(super) fn list_render_audio_devices() -> Result<Vec<AudioOutputDeviceInfo>> {
        unsafe {
            let _ = CoInitializeEx(None, COINIT_MULTITHREADED);

            let enumerator: IMMDeviceEnumerator =
                CoCreateInstance(&MMDeviceEnumerator, None, CLSCTX_ALL)?;

            let default_id = enumerator
                .GetDefaultAudioEndpoint(eRender, eConsole)
                .ok()
                .and_then(|device| device.GetId().ok())
                .and_then(|id| id.to_string().ok());

            let collection = enumerator.EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE)?;
            let count = collection.GetCount()?;

            let mut devices = Vec::with_capacity(count as usize);
            for i in 0..count {
                let device = collection.Item(i)?;
                let endpoint_id = device.GetId()?.to_string()?;
                let name = read_friendly_name(&device)
                    .unwrap_or_else(|| format!("音频设备 {}", i as usize + 1));
                let is_default = default_id.as_deref() == Some(endpoint_id.as_str());
                devices.push(AudioOutputDeviceInfo {
                    endpoint_id,
                    name,
                    is_default,
                });
            }
            Ok(devices)
        }
    }

    unsafe fn read_friendly_name(device: &IMMDevice) -> Option<String> {
        let store = device.OpenPropertyStore(STGM_READ).ok()?;
        let value = store.GetValue(&PKEY_Device_FriendlyName).ok()?;
        if value.is_empty() {
            return None;
        }
        BSTR::try_from(&value).ok().map(|name| name.to_string())
    }
}

#[cfg(any(frb_expand, not(target_os = "windows")))]
mod imp {
    use anyhow::Result;

    use super::AudioOutputDeviceInfo;

    pub(super) fn list_render_audio_devices() -> Result<Vec<AudioOutputDeviceInfo>> {
        Ok(Vec::new())
    }
}

use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn list_render_audio_devices() -> Option<Vec<AudioOutputDeviceInfo>> {
    imp::list_render_audio_devices().ok()
}
