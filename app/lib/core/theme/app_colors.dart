import 'package:flutter/material.dart';

/// สีประจำแบรนด์แมว.live — ดึงจากเว็บ prototype (www.แมว.live)
abstract final class AppColors {
  static const page = Color(0xFFFFFBF5);
  static const card = Colors.white;
  static const text = Color(0xFF4A3428);
  static const text2 = Color(0xFF5E4636);
  static const muted = Color(0xFF7A6255);
  static const ink = Color(0xFF5A4030);
  static const btn = Color(0xFFFFF1E6);
  static const btnFollowing = Colors.white;
  static const btnBorder = Color(0xFFF2CFB4);
  static const soft = Color(0xFFF6EFE6);
  static const line = Color(0xFFF0E6DA);
  static const line2 = Color(0xFFE6D9C8);
  static const tile = Color(0xFFDCEBFF);
  static const media = Color(0xFFF3EDE6);
  static const heart = Color(0xFFE2557A);
  static const unchecked = Color(0xFFD4C4B8);
  static const danger = Color(0xFFC0392B);
  static const navBackground = Color(0xF2FFFDF9);
  static const ringUnseenFrom = Color(0xFFB5C8EC);
  static const ringUnseenTo = Color(0xFF8FA6DA);

  // หน้าแรก — แบนเนอร์ต้อนรับและการ์ดทางลัด
  static const heroStart = Color(0xFFFFF6EA);
  static const heroEnd = Color(0xFFF6E6D6);
  static const heroHeart = Color(0xFFF07E73);
  static const quickFeedBg = Color(0xFFDDF2EE);
  static const quickFeedBorder = Color(0xFFA9DCD3);
  static const quickFeedInk = Color(0xFF0B5E58);
  static const quickFeedIcon = Color(0xFF5FB3A8);
  static const quickAiBg = Color(0xFFE9E6FB);
  static const quickAiBorder = Color(0xFFC9C2F3);
  static const quickAiInk = Color(0xFF403A9C);
  static const quickAiIcon = Color(0xFF8F88DE);
  static const quickHelpBg = Color(0xFFFDE6DF);
  static const quickHelpBorder = Color(0xFFF5BFAF);
  static const quickHelpInk = Color(0xFF963721);
  static const quickHelpIcon = Color(0xFFE58A72);

  // แมวและฉัน (/my-cat)
  static const statusSafe = Color(0xFF2FA36B);
  static const addCatDashedBorder = Color(0xFFD7A3B8);
  static const sheetBarrier = Color(0x594A3428);
  static const catRingStart = Color(0xFFF2CFB4);
  static const catRingMid = Color(0xFFF9C98F);
  static const catRingEnd = Color(0xFFFFF1E6);
  static const ownerRingStart = Color(0xFF7CCBBB);
  static const ownerRingMid = Color(0xFFA9DDD2);
  static const ownerRingEnd = Color(0xFFD5F0EB);

  // ดูแลวันนี้
  static const careProgressFill = Color(0xFF0F766E);
  static const careFoodBg = Color(0xFFFFF1E2);
  static const careFoodIcon = Color(0xFF9A4A0B);
  static const careFoodCheckBg = Color(0xFFFFE0BF);
  static const careFoodCheckBorder = Color(0xFFF5B97E);
  static const careFoodCheckInk = Color(0xFF8A4508);
  static const careWaterBg = Color(0xFFFFF6D6);
  static const careWaterIcon = Color(0xFF6E4B00);
  static const careWaterCheckBg = Color(0xFFFCD3E1);
  static const careWaterCheckBorder = Color(0xFFEE9BB8);
  static const careWaterCheckInk = Color(0xFF9C2452);
  static const careLitterBg = Color(0xFFF1EADF);
  static const careLitterIcon = Color(0xFF6B4F1D);
  static const careMedsBg = Color(0xFFEDE4FB);
  static const careMedsIcon = Color(0xFF5B2DB0);
  static const careWeightBg = Color(0xFFD5F0EB);
  static const careWeightIcon = Color(0xFF0F6A62);

  // สุขภาพ
  static const healthReminderBg = Color(0xFFFFF3C4);
  static const healthReminderBorder = Color(0xFFF1D98A);
  static const healthReminderClockInk = Color(0xFF8A5A00);
  static const healthReminderBtnInk = Color(0xFF5C3D00);
  static const healthDotVaccine = Color(0xFFE6C24F);
  static const healthDotAi = Color(0xFFB9A6F2);
  static const healthDotCheckup = Color(0xFF7CCBBB);

  // ตัวฉัน (Teal/Mint accent) & ตั้งค่า & แชร์
  static const ownerTeal = Color(0xFF0B5E58);
  static const ownerPillBg = Color(0xFFD5F0EB);
  static const ownerTealBorder = Color(0xFFD8E9E6);
  static const ownerTealRing = Color(0xFF7CCBBB);
  static const settingsIconBox = Color(0xFFF6ECE3);
  static const logoutBg = Color(0xFFFFF5F6);
  static const logoutBorder = Color(0xFFF7B9C0);
  static const logoutText = Color(0xFF8F1C13);
  static const brandLine = Color(0xFF06C755);
  static const brandFacebook = Color(0xFF1877F2);

  // ตามหาแมว (/my-cat/tracker)
  static const trackerMapFallback = Color(0xFFEDE7DF);
  static const trackerMapGrid = Color(0xFFE0D7CC);
  static const trackerMapRoad = Color(0xFFFDFBF7);
  static const trackerSafeTeal = Color(0xFF2F7F7A);
  static const trackerSafeTealLight = Color(0xFF5AAAA2);
  static const trackerSafeZoneFill = Color(0x1A2F7F7A);
  static const trackerOutZoneFill = Color(0x14E2557A);
  static const trackerHomePin = Color(0xFF3B82F6);
  static const trackerTimelineInactive = Color(0xFFCDBFB0);
  static const trackerLostIconOff = Color(0xFFD9772B);
  static const trackerLostBgOn = Color(0xFFFFF1F3);
  static const trackerLostBtnBorder = Color(0xFFE7B3AA);
  static const trackerLostBtnInk = Color(0xFFA3321F);
  static const trackerCollarTeal = Color(0xFF328F87);
  static const trackerCollarSand = Color(0xFFDFC8A3);

  // หน้าแอนิเมชันเปิดแอป (Splash / Intro)
  static const splashBgStart = Color(0xFFFFF6EC);
  static const splashBgMid = Color(0xFFFFF1E6);
  static const splashBgEnd = Color(0xFFFBE3D0);
  static const splashShadow = Color(0xFFE9CDB6);
  static const splashShirt = Color(0xFFF4A3B4);
  static const splashSkin = Color(0xFFF6D2B8);
  static const splashCatBody = Color(0xFFF2B56B);
  static const splashCatDark = Color(0xFFE7A25B);
  static const splashCatStripe = Color(0xFFE29A4E);
  static const splashHeartGold = Color(0xFFF6DC8E);
  static const splashHint = Color(0xFF9C8A79);

  // สมุดสุขภาพ (/my-cat/health)
  static const healthNormalStroke = Color(0xFF4DB8A4);
  static const healthNormalInk = Color(0xFF0B5E58);
  static const healthWatchBg = Color(0xFFFFF3CC);
  static const healthWatchStroke = Color(0xFFE6B83A);
  static const healthWatchInk = Color(0xFF7A5200);
  static const healthAbnormalBg = Color(0xFFFFE4E6);
  static const healthAbnormalStroke = Color(0xFFF43F5E);
  static const healthAbnormalInk = Color(0xFFE11D48);
  static const healthEmptyStroke = Color(0xFFC9BDB3);
  static const healthDeltaGainBg = Color(0xFFE6F4EA);
  static const healthDeltaGainInk = Color(0xFF0F766E);
  static const healthDeltaDropBg = Color(0xFFFFF1F2);
  static const healthDeltaDropInk = Color(0xFFE11D48);
  static const healthWeightAlertBg = Color(0xFFFEF9C3);
  static const healthWeightAlertBorder = Color(0xFFFDE047);
  static const healthWeightAlertInk = Color(0xFF854D0E);
  static const healthVaccineBlue = Color(0xFF3B82F6);
  static const healthVaccineBlueBg = Color(0xFFEFF6FF);
  static const healthIllnessOrange = Color(0xFFE07A5F);
  static const healthIllnessOrangeBg = Color(0xFFFFF1EC);
  static const healthMedPurple = Color(0xFF7C3AED);
  static const healthMedPurpleBg = Color(0xFFF3E8FF);
  static const healthDewormTeal = Color(0xFF0D9488);
  static const healthDocPdfBg = Color(0xFFFCE7F3);
  static const healthDocPdfInk = Color(0xFFBE185D);
  static const healthDocImgBg = Color(0xFFDBEAFE);
  static const healthDocImgInk = Color(0xFF1D4ED8);

  // ใกล้ฉัน (/nearby)
  static const nearbyUserDot = Color(0xFF4F86C6);
  static const nearbyOpenDot = Color(0xFF3BA55C);
  static const nearbyOpenText = Color(0xFF2E7D4F);
  static const nearbyEmergencySiren = Color(0xFFC2503B);
  static const nearbyEmergencyCall = Color(0xFFB33A26);
  static const nearbyStarFill = Color(0xFFFFD95A);
  static const nearbyStarStroke = Color(0xFFC99A1A);
  static const nearbyAreaSelectedBg = Color(0xFFE1F1EE);
  static const nearbyPinClinic = Color(0xFFF5BFAF);
  static const nearbyPinShop = Color(0xFFF3DC9A);
  static const nearbyPinGrooming = Color(0xFFCFC8F2);
  static const nearbyPinBoarding = Color(0xFFB9CBEE);
  static const nearbyPinCafe = Color(0xFFF2CDB0);
  static const nearbyPinLostCat = Color(0xFFF0AFA2);
  static const nearbyPinFoundCat = Color(0xFFA9DCD3);
  static const nearbyPinCommunityCat = Color(0xFFE8D3B5);
}
