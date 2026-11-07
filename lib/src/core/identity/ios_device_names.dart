/// Names people know for iOS device identifiers, for example
/// `iPhone19,2` → `iPhone 18 Pro`.
///
/// Sources: TheAppleWiki, adamawolf/Apple_mobile_device_types.txt and
/// Wikipedia "List of iPhone models" (checked Feb 2026); the 2026 models
/// (iPhone 17e, iPhone 18 Pro and Pro Max, iPad Air M4) from device_info_plus
/// 13.3.0, ios/device_info_plus/Sources/device_info_plus/DeviceIdentifiers.m.
/// Add new models here as Apple releases them.
const iosDeviceNames = <String, String>{
  // =====================================================================
  // iPhones
  // =====================================================================

  // iPhone 18 series (2026)
  'iPhone19,2': 'iPhone 18 Pro',
  'iPhone19,3': 'iPhone 18 Pro Max',
  'iPhone19,7': 'iPhone 18 Pro Max',

  // iPhone 17 series (2025)
  'iPhone18,1': 'iPhone 17 Pro',
  'iPhone18,2': 'iPhone 17 Pro Max',
  'iPhone18,3': 'iPhone 17',
  'iPhone18,4': 'iPhone Air',
  'iPhone18,5': 'iPhone 17e',

  // iPhone 16 series (2024)
  'iPhone17,1': 'iPhone 16 Pro',
  'iPhone17,2': 'iPhone 16 Pro Max',
  'iPhone17,3': 'iPhone 16',
  'iPhone17,4': 'iPhone 16 Plus',
  'iPhone17,5': 'iPhone 16e',

  // iPhone 15 series (2023)
  'iPhone15,4': 'iPhone 15',
  'iPhone15,5': 'iPhone 15 Plus',
  'iPhone16,1': 'iPhone 15 Pro',
  'iPhone16,2': 'iPhone 15 Pro Max',

  // iPhone 14 series (2022)
  'iPhone14,7': 'iPhone 14',
  'iPhone14,8': 'iPhone 14 Plus',
  'iPhone15,2': 'iPhone 14 Pro',
  'iPhone15,3': 'iPhone 14 Pro Max',

  // iPhone 13 series (2021)
  'iPhone14,4': 'iPhone 13 mini',
  'iPhone14,5': 'iPhone 13',
  'iPhone14,2': 'iPhone 13 Pro',
  'iPhone14,3': 'iPhone 13 Pro Max',

  // iPhone SE (3rd generation) (2022)
  'iPhone14,6': 'iPhone SE (3rd generation)',

  // iPhone 12 series (2020)
  'iPhone13,1': 'iPhone 12 mini',
  'iPhone13,2': 'iPhone 12',
  'iPhone13,3': 'iPhone 12 Pro',
  'iPhone13,4': 'iPhone 12 Pro Max',

  // iPhone SE (2nd generation) (2020)
  'iPhone12,8': 'iPhone SE (2nd generation)',

  // iPhone 11 series (2019)
  'iPhone12,1': 'iPhone 11',
  'iPhone12,3': 'iPhone 11 Pro',
  'iPhone12,5': 'iPhone 11 Pro Max',

  // iPhone XS/XS Max/XR (2018)
  'iPhone11,2': 'iPhone XS',
  'iPhone11,4': 'iPhone XS Max',
  'iPhone11,6': 'iPhone XS Max',
  'iPhone11,8': 'iPhone XR',

  // iPhone X (2017)
  'iPhone10,3': 'iPhone X',
  'iPhone10,6': 'iPhone X',

  // iPhone 8/8 Plus (2017)
  'iPhone10,1': 'iPhone 8',
  'iPhone10,2': 'iPhone 8 Plus',
  'iPhone10,4': 'iPhone 8',
  'iPhone10,5': 'iPhone 8 Plus',

  // iPhone 7/7 Plus (2016)
  'iPhone9,1': 'iPhone 7',
  'iPhone9,2': 'iPhone 7 Plus',
  'iPhone9,3': 'iPhone 7',
  'iPhone9,4': 'iPhone 7 Plus',

  // iPhone 6s/6s Plus (2015)
  'iPhone8,1': 'iPhone 6s',
  'iPhone8,2': 'iPhone 6s Plus',

  // iPhone SE (1st generation) (2016)
  'iPhone8,4': 'iPhone SE (1st generation)',

  // iPhone 6/6 Plus (2014)
  'iPhone7,1': 'iPhone 6 Plus',
  'iPhone7,2': 'iPhone 6',

  // iPhone 5s/5c (2013)
  'iPhone6,1': 'iPhone 5s',
  'iPhone6,2': 'iPhone 5s',
  'iPhone5,3': 'iPhone 5c',
  'iPhone5,4': 'iPhone 5c',

  // iPhone 5 (2012)
  'iPhone5,1': 'iPhone 5',
  'iPhone5,2': 'iPhone 5',

  // iPhone 4S (2011)
  'iPhone4,1': 'iPhone 4S',

  // iPhone 4 (2010)
  'iPhone3,1': 'iPhone 4',
  'iPhone3,2': 'iPhone 4',
  'iPhone3,3': 'iPhone 4',

  // iPhone 3GS (2009)
  'iPhone2,1': 'iPhone 3GS',

  // iPhone 3G (2008)
  'iPhone1,2': 'iPhone 3G',

  // iPhone (1st generation) (2007)
  'iPhone1,1': 'iPhone (1st generation)',

  // =====================================================================
  // iPad Pro models
  // =====================================================================

  // iPad Pro 11" & 13" (M5) (2025)
  'iPad17,1': 'iPad Pro 11" (M5)',
  'iPad17,2': 'iPad Pro 11" (M5)',
  'iPad17,3': 'iPad Pro 13" (M5)',
  'iPad17,4': 'iPad Pro 13" (M5)',

  // iPad Pro 11" & 13" (M4) (2024)
  'iPad16,3': 'iPad Pro 11" (M4)',
  'iPad16,4': 'iPad Pro 11" (M4)',
  'iPad16,5': 'iPad Pro 13" (M4)',
  'iPad16,6': 'iPad Pro 13" (M4)',

  // iPad Pro 11" (4th generation) & 12.9" (6th generation) — M2 (2022)
  'iPad14,3': 'iPad Pro 11" (4th generation)',
  'iPad14,4': 'iPad Pro 11" (4th generation)',
  'iPad14,5': 'iPad Pro 12.9" (6th generation)',
  'iPad14,6': 'iPad Pro 12.9" (6th generation)',

  // iPad Pro 11" (3rd generation) & 12.9" (5th generation) — M1 (2021)
  'iPad13,4': 'iPad Pro 11" (3rd generation)',
  'iPad13,5': 'iPad Pro 11" (3rd generation)',
  'iPad13,6': 'iPad Pro 11" (3rd generation)',
  'iPad13,7': 'iPad Pro 11" (3rd generation)',
  'iPad13,8': 'iPad Pro 12.9" (5th generation)',
  'iPad13,9': 'iPad Pro 12.9" (5th generation)',
  'iPad13,10': 'iPad Pro 12.9" (5th generation)',
  'iPad13,11': 'iPad Pro 12.9" (5th generation)',

  // iPad Pro 11" (2nd generation) & 12.9" (4th generation) (2020)
  'iPad8,9': 'iPad Pro 11" (2nd generation)',
  'iPad8,10': 'iPad Pro 11" (2nd generation)',
  'iPad8,11': 'iPad Pro 12.9" (4th generation)',
  'iPad8,12': 'iPad Pro 12.9" (4th generation)',

  // iPad Pro 11" (1st generation) & 12.9" (3rd generation) (2018)
  'iPad8,1': 'iPad Pro 11" (1st generation)',
  'iPad8,2': 'iPad Pro 11" (1st generation)',
  'iPad8,3': 'iPad Pro 11" (1st generation)',
  'iPad8,4': 'iPad Pro 11" (1st generation)',
  'iPad8,5': 'iPad Pro 12.9" (3rd generation)',
  'iPad8,6': 'iPad Pro 12.9" (3rd generation)',
  'iPad8,7': 'iPad Pro 12.9" (3rd generation)',
  'iPad8,8': 'iPad Pro 12.9" (3rd generation)',

  // iPad Pro 12.9" (2nd generation) & 10.5" (2017)
  'iPad7,1': 'iPad Pro 12.9" (2nd generation)',
  'iPad7,2': 'iPad Pro 12.9" (2nd generation)',
  'iPad7,3': 'iPad Pro 10.5"',
  'iPad7,4': 'iPad Pro 10.5"',

  // iPad Pro 9.7" (2016) & 12.9" (1st generation) (2015)
  'iPad6,3': 'iPad Pro 9.7"',
  'iPad6,4': 'iPad Pro 9.7"',
  'iPad6,7': 'iPad Pro 12.9" (1st generation)',
  'iPad6,8': 'iPad Pro 12.9" (1st generation)',

  // =====================================================================
  // iPad Air models
  // =====================================================================

  // iPad Air 11" & 13" (M4) (2026)
  'iPad16,8': 'iPad Air 11" (M4)',
  'iPad16,9': 'iPad Air 11" (M4)',
  'iPad16,10': 'iPad Air 13" (M4)',
  'iPad16,11': 'iPad Air 13" (M4)',

  // iPad Air 11" & 13" (M3) (2025)
  'iPad15,3': 'iPad Air 11" (M3)',
  'iPad15,4': 'iPad Air 11" (M3)',
  'iPad15,5': 'iPad Air 13" (M3)',
  'iPad15,6': 'iPad Air 13" (M3)',

  // iPad Air 11" & 13" (M2) (2024)
  'iPad14,8': 'iPad Air 11" (M2)',
  'iPad14,9': 'iPad Air 11" (M2)',
  'iPad14,10': 'iPad Air 13" (M2)',
  'iPad14,11': 'iPad Air 13" (M2)',

  // iPad Air (5th generation) — M1 (2022)
  'iPad13,16': 'iPad Air (5th generation)',
  'iPad13,17': 'iPad Air (5th generation)',

  // iPad Air (4th generation) (2020)
  'iPad13,1': 'iPad Air (4th generation)',
  'iPad13,2': 'iPad Air (4th generation)',

  // iPad Air (3rd generation) (2019)
  'iPad11,3': 'iPad Air (3rd generation)',
  'iPad11,4': 'iPad Air (3rd generation)',

  // iPad Air 2 (2014)
  'iPad5,3': 'iPad Air 2',
  'iPad5,4': 'iPad Air 2',

  // iPad Air (1st generation) (2013)
  'iPad4,1': 'iPad Air (1st generation)',
  'iPad4,2': 'iPad Air (1st generation)',
  'iPad4,3': 'iPad Air (1st generation)',

  // =====================================================================
  // iPad models
  // =====================================================================

  // iPad (A16) (2025)
  'iPad15,7': 'iPad (A16)',
  'iPad15,8': 'iPad (A16)',

  // iPad (10th generation) (2022)
  'iPad13,18': 'iPad (10th generation)',
  'iPad13,19': 'iPad (10th generation)',

  // iPad (9th generation) (2021)
  'iPad12,1': 'iPad (9th generation)',
  'iPad12,2': 'iPad (9th generation)',

  // iPad (8th generation) (2020)
  'iPad11,6': 'iPad (8th generation)',
  'iPad11,7': 'iPad (8th generation)',

  // iPad (7th generation) (2019)
  'iPad7,11': 'iPad (7th generation)',
  'iPad7,12': 'iPad (7th generation)',

  // iPad (6th generation) (2018)
  'iPad7,5': 'iPad (6th generation)',
  'iPad7,6': 'iPad (6th generation)',

  // iPad (5th generation) (2017)
  'iPad6,11': 'iPad (5th generation)',
  'iPad6,12': 'iPad (5th generation)',

  // iPad (4th generation) (2012)
  'iPad3,4': 'iPad (4th generation)',
  'iPad3,5': 'iPad (4th generation)',
  'iPad3,6': 'iPad (4th generation)',

  // iPad (3rd generation) (2012)
  'iPad3,1': 'iPad (3rd generation)',
  'iPad3,2': 'iPad (3rd generation)',
  'iPad3,3': 'iPad (3rd generation)',

  // iPad 2 (2011)
  'iPad2,1': 'iPad 2',
  'iPad2,2': 'iPad 2',
  'iPad2,3': 'iPad 2',
  'iPad2,4': 'iPad 2',

  // iPad (1st generation) (2010)
  'iPad1,1': 'iPad (1st generation)',

  // =====================================================================
  // iPad mini models
  // =====================================================================

  // iPad mini (A17 Pro) (2024)
  'iPad16,1': 'iPad mini (A17 Pro)',
  'iPad16,2': 'iPad mini (A17 Pro)',

  // iPad mini (6th generation) (2021)
  'iPad14,1': 'iPad mini (6th generation)',
  'iPad14,2': 'iPad mini (6th generation)',

  // iPad mini (5th generation) (2019)
  'iPad11,1': 'iPad mini (5th generation)',
  'iPad11,2': 'iPad mini (5th generation)',

  // iPad mini 4 (2015)
  'iPad5,1': 'iPad mini 4',
  'iPad5,2': 'iPad mini 4',

  // iPad mini 3 (2014)
  'iPad4,7': 'iPad mini 3',
  'iPad4,8': 'iPad mini 3',
  'iPad4,9': 'iPad mini 3',

  // iPad mini 2 (2013)
  'iPad4,4': 'iPad mini 2',
  'iPad4,5': 'iPad mini 2',
  'iPad4,6': 'iPad mini 2',

  // iPad mini (1st generation) (2012)
  'iPad2,5': 'iPad mini (1st generation)',
  'iPad2,6': 'iPad mini (1st generation)',
  'iPad2,7': 'iPad mini (1st generation)',

  // =====================================================================
  // iPod touch models
  // =====================================================================
  'iPod9,1': 'iPod touch (7th generation)',
  'iPod7,1': 'iPod touch (6th generation)',
  'iPod5,1': 'iPod touch (5th generation)',
  'iPod4,1': 'iPod touch (4th generation)',
  'iPod3,1': 'iPod touch (3rd generation)',
  'iPod2,1': 'iPod touch (2nd generation)',
  'iPod1,1': 'iPod touch (1st generation)',
};
