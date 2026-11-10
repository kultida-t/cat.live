/**
 * โมเดลข้อมูลฟีดชุมชน — อิง docs/data-schema.md (ตาราง posts/comments/likes/saves/follows)
 * ช่วง mock: ใช้ interface ชุดนี้เหมือนกัน วันที่ต่อ API จริงไม่ต้องแก้หน้าจอ
 */

export type FeedTab = 'all' | 'following' | 'saved';

export type PostType = 'normal' | 'lost_cat';

export interface FeedUser {
  id: string;
  handle: string;
  displayName?: string;
  avatarEmoji: string;
}

export interface PostMedia {
  kind: 'image' | 'video';
  /** คำอธิบายรูป (mock ยังไม่มีไฟล์จริง — ของจริงจะเป็น url) */
  alt: string;
  /** สีพื้นจำลองรูป สำหรับช่วง mock */
  mockColor: string;
  durationSec?: number;
}

export interface CommentPreview {
  authorHandle: string;
  body: string;
}

export interface Post {
  id: string;
  type: PostType;
  author: FeedUser;
  /** ป้ายข้างชื่อบัญชี เช่น "คำถาม · สุขภาพ" */
  badgeLabel?: string;
  /** ย่าน/ระยะทางที่โชว์สาธารณะ (พิกัดจริงห้ามส่งออก — ตามกฎ privacy) */
  areaLabel?: string;
  distanceMeters?: number;
  category: string;
  caption: string;
  media: PostMedia[];
  likeCount: number;
  commentCount: number;
  likedByHandle?: string;
  previewComments: CommentPreview[];
  postedAgoText: string;
  announcementId?: string;
  isFollowingAuthor: boolean;
  isLiked: boolean;
  isSaved: boolean;
  isOwn: boolean;
}
