import type { ImageProps } from 'expo-image';

type ImageSourcePropType = ImageProps['source'];

/**
 * โมเดลข้อมูลฟีดชุมชน — อิง docs/data-schema.md (ตาราง posts/comments/likes/saves/follows)
 * ช่วง mock: ใช้ interface ชุดนี้เหมือนกัน วันที่ต่อ API จริงไม่ต้องแก้หน้าจอ
 */

export type FeedTab = 'all' | 'following' | 'saved';

export type PostType = 'normal' | 'lost_cat';

export interface FeedUser {
  id: string;
  handle: string;
  avatar: ImageSourcePropType;
  /** สีพื้นหลังวงกลมอวตารระหว่างรอรูปโหลด */
  avatarBg: string;
  /** มีสตอรี่ที่ยังไม่ได้ดู — วงแหวนสีฟ้า (ดูแล้วเป็นสีเทา) */
  hasUnseenStory: boolean;
}

export interface PostMedia {
  kind: 'image' | 'video';
  alt: string;
  source: ImageSourcePropType;
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
  /** บรรทัดเล็กใต้ชื่อบัญชี เช่น "ความรู้" หรือ "อารีย์ · ห่างจากคุณ 900 ม." */
  subtitle?: string;
  subtitleHasPin: boolean;
  caption: string;
  media: PostMedia[];
  likeCount: number;
  commentCount: number;
  shareCount: number;
  /** บัญชีที่แสดงในบรรทัด "X และคนอื่น ๆ ถูกใจ" พร้อมอวตารซ้อนกัน */
  likedBy: { handle: string; avatars: { source: ImageSourcePropType; bg: string }[] };
  previewComments: CommentPreview[];
  postedAgoText: string;
  announcementId?: string;
  isFollowingAuthor: boolean;
  isLiked: boolean;
  isSaved: boolean;
  isOwn: boolean;
}
